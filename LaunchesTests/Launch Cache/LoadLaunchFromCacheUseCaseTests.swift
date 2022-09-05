//
//  LoadLaunchFromCacheUseCaseTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 1.09.2022.
//

import XCTest
import Launches

class LoadLaunchFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_load_requestCacheRetrevial() {
        let (sut, store) = makeSUT()

        sut.load(completion: { _ in })

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()

        expect(sut, toCompleteWtih: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }

    func test_load_deliversNoLaunchesOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWtih: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }

    func test_load_deliversCachedLaunchesOnNonExpiredCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWtih: .success(launches)) {
            store.completeRetrieval(with: localLaunches, timestamp: nonExpiredTimestamp)
        }
    }

    func test_load_deliversNoLaunchesOnCacheExpiration() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWtih: .success([])) {
            store.completeRetrieval(with: localLaunches, timestamp: expirationTimestamp)
        }
    }

    func test_load_deliversNoLaunchesOnExpiredCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge().adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWtih: .success([])) {
            store.completeRetrieval(with: localLaunches, timestamp: expiredTimestamp)
        }
    }

    func test_load_hasNoSideEffectsOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsLessThanSevenDaysOldCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: localLaunches, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnSevenDaysOldCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: localLaunches, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_hasNoSideEffectsOnMoreThanSevenDaysOldCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge().adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.load { _ in }
        store.completeRetrieval(with: localLaunches, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
        let store = LaunchStoreSpy()
        var sut: LocalLaunchLoader? = LocalLaunchLoader(store: store, currentDate: Date.init)

        var receivedResults = [LocalLaunchLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }

        sut = nil
        store.completeRetrievalWithEmptyCache()

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
                        toCompleteWtih expectedResult: LocalLaunchLoader.LoadResult,
                        file: StaticString = #file,
                        line: UInt = #line,
                        when action: () -> Void) {
        let exp = expectation(description: "Wait for load completion")

        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedLaunches), .success(expectedLaunches)):
                XCTAssertEqual(receivedLaunches, expectedLaunches, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult), got \(String(describing: receivedResult)) failure instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }
}
