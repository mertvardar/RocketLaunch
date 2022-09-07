//
//  XCTestCase+LaunchStoreSpecs.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 6.09.2022.
//

import XCTest
import Launches

extension LaunchStoreSpecs where Self: XCTestCase {

    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty, file: file, line: line)
    }

    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        let launches = [LocalLaunchItem(id: 1, name: "1", date: "1")]
        let timestamp = Date()

        insert((launches, timestamp), to: sut)

        expect(sut, toRetrieve: .found(launches: launches, timestamp: timestamp), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        let launches = [LocalLaunchItem(id: 1, name: "1", date: "1")]
        let timestamp = Date()

        insert((launches, timestamp), to: sut)

        expect(sut, toRetrieveTwice: .found(launches: launches, timestamp: timestamp), file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        let insertionError = insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }

    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        let latestLaunches = [LocalLaunchItem(id: 1, name: "1", date: "1")]
        let latestTimestamp = Date()
        insert((latestLaunches, latestTimestamp), to: sut)

        expect(sut, toRetrieve: .found(launches: latestLaunches, timestamp: latestTimestamp), file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatSideEffectsRunSerially(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Operation 1")
        sut.insert([LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedLaunches { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert([LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order", file: file, line: line)
    }

}

extension LaunchStoreSpecs where Self: XCTestCase {
    @discardableResult
    func deleteCache(from sut: LaunchStore) -> Error? {
        let exp = expectation(description: "Wait for deletion")

        var deletionError: Error?
        sut.deleteCachedLaunches { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        return deletionError
    }

    @discardableResult
    func insert(_ cache: (launches: [LocalLaunchItem], timestamp: Date), to sut: LaunchStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.launches, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }

    func expect(_ sut: LaunchStore, toRetrieve expectedResult: RetrieveCachedLaunchResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure):
                break
            case let (.found(expected), .found(retrieved)):
                XCTAssertEqual(retrieved.launches, expected.launches, file: file, line: line)
                XCTAssertEqual(retrieved.timestamp, expected.timestamp, file: file, line: line)
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func expect(_ sut: LaunchStore, toRetrieveTwice expectedResult: RetrieveCachedLaunchResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }
}
