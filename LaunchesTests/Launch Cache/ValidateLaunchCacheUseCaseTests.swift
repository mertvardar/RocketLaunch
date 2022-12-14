//
//  ValidateLaunchCacheUseCaseTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 5.09.2022.
//

import XCTest
import Launches

class ValidateLaunchCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheLaunch])
    }

    func test_validateCache_hasNoSideEffectsOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.validateCache()
        store.completeRetrievalWithEmptyCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_doesNotdeletesOnNonExpiredCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge().adding(seconds: 1)

        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: localLaunches, timestamp: nonExpiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_deletesOnCacheExpiration() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: localLaunches, timestamp: expirationTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheLaunch])
    }

    func test_validateCache_deletesOnExpiredCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusLaunchCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        sut.validateCache()
        store.completeRetrieval(with: localLaunches, timestamp: expiredTimestamp)

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheLaunch])
    }

    func test_validateCache_doesNotDeleteInvalidCacheAfterSUTInstanceHasBeenDeallocated() {
        let store = LaunchStoreSpy()
        var sut: LocalLaunchLoader? = LocalLaunchLoader(store: store, currentDate: Date.init)
        
        sut?.validateCache()

        sut = nil
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
}
