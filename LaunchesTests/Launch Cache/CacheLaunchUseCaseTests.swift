//
//  CacheLaunchUseCaseTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 27.08.2022.
//

import XCTest
import Launches

class LocalLaunchLoader {
    private let store: LaunchStore
    private let currentDate: () -> Date

    init(store: LaunchStore,
         currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    func save(_ launchItems: [LaunchItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedLaunches { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                completion(error)
            } else {
                self.store.insert(launchItems, timestamp: self.currentDate()) { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
            }
        }
    }
}

protocol LaunchStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCachedLaunches(completion: @escaping DeletionCompletion)
    func insert(_ launchItems: [LaunchItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

class CacheLaunchUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [LaunchItem(id: 0, name: "Launch 1", date: "01012022"),
                     LaunchItem(id: 1, name: "Launch 2", date: "02012022")]
        sut.save(items) { _ in }

        XCTAssertEqual(store.receivedMessages, [.deleteCacheLaunch])
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [LaunchItem(id: 0, name: "Launch 1", date: "01012022"),
                     LaunchItem(id: 1, name: "Launch 2", date: "02012022")]
        let deletionError = anyNSError()

        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.receivedMessages, [.deleteCacheLaunch])
    }

    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = [LaunchItem(id: 0, name: "Launch 1", date: "01012022"),
                     LaunchItem(id: 1, name: "Launch 2", date: "02012022")]

        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()

        XCTAssertEqual(store.receivedMessages, [.deleteCacheLaunch, .insertCacheLaunch(items, timestamp)])
    }

    func test_save_failsOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWithError: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }

    func test_save_failsOnInsertionError() {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()

        expect(sut, toCompleteWithError: insertionError) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }

    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWithError: nil) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }

    func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceDeallocated() {
        let store = LaunchStoreSpy()
        var sut: LocalLaunchLoader? = LocalLaunchLoader(store: store, currentDate: Date.init)

        var receivedResults = [Error?]()
        sut?.save([LaunchItem(id: 0, name: "Launch 0", date: "01012022")], completion: { receivedResults.append($0) })

        sut = nil
        store.completeDeletion(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty)
    }

    func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceDeallocated() {
        let store = LaunchStoreSpy()
        var sut: LocalLaunchLoader? = LocalLaunchLoader(store: store, currentDate: Date.init)

        var receivedResults = [Error?]()
        sut?.save([LaunchItem(id: 0, name: "Launch 0", date: "01012022")], completion: { receivedResults.append($0) })

        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: anyNSError())

        XCTAssertTrue(receivedResults.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalLaunchLoader, store: LaunchStoreSpy) {
        let store = LaunchStoreSpy()
        let sut = LocalLaunchLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    private func expect(_ sut: LocalLaunchLoader,
                        toCompleteWithError expectedError: NSError?,
                        when action: () -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) {
        let exp = expectation(description: "Wait for completion")
        var receivedError: Error?
        sut.save([LaunchItem(id: 0, name: "Launch 1", date: "01012022")]) { error in
            receivedError = error
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError as NSError?, expectedError, file: file, line: line)
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }

     private class LaunchStoreSpy: LaunchStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void

        enum ReceivedMessage: Equatable {
            case deleteCacheLaunch
            case insertCacheLaunch([LaunchItem], Date)
        }
        private(set) var receivedMessages = [ReceivedMessage]()

        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()

        func deleteCachedLaunches(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCacheLaunch)
        }

        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }

        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }

        func completeInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }

        func insert(_ launchItems: [LaunchItem],
                    timestamp: Date,
                    completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insertCacheLaunch(launchItems, timestamp))
        }

        func completeInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
