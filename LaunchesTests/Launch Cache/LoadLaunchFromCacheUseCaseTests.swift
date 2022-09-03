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

    func test_load_deliversCachedLaunchesOnLessThanSevenDaysOldCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWtih: .success(launches)) {
            store.completeRetrieval(with: localLaunches, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }

    func test_load_deliversNoLaunchesSevenDaysOldCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWtih: .success([])) {
            store.completeRetrieval(with: localLaunches, timestamp: sevenDaysOldTimestamp)
        }
    }

    func test_load_deliversNoLaunchesMoreThanSevenDaysOldCache() {
        let launches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let localLaunches = launches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWtih: .success([])) {
            store.completeRetrieval(with: localLaunches, timestamp: moreThanSevenDaysOldTimestamp)
        }
    }

    func test_load_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheLaunch])
    }

    func test_load_doesNotDeletesCacheOnEmptyCache() {
        let (sut, store) = makeSUT()

        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()

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

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
