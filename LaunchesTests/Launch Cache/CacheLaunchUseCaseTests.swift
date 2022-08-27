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
        store.deleteCachedLaunches { [unowned self] error in
            completion(error)
            if error == nil {
                self.store.insert(launchItems, timestamp: self.currentDate())
            }
        }
    }
}

class LaunchStore {
    typealias DeletionCompletion = (Error?) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCacheLaunch
        case insertCacheLaunch([LaunchItem], Date)
    }
    private(set) var receivedMessages = [ReceivedMessage]()

    private var deletionCompletions = [DeletionCompletion]()

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

    func insert(_ launchItems: [LaunchItem], timestamp: Date) {
        receivedMessages.append(.insertCacheLaunch(launchItems, timestamp))
    }
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
        let items = [LaunchItem(id: 0, name: "Launch 1", date: "01012022"),
                     LaunchItem(id: 1, name: "Launch 2", date: "02012022")]
        let deletionError = anyNSError()

        let exp = expectation(description: "Wait for completion")
        var receivedError: Error?
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        store.completeDeletion(with: deletionError)

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError as NSError?, deletionError)
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalLaunchLoader, store: LaunchStore) {
        let store = LaunchStore()
        let sut = LocalLaunchLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
