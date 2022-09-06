//
//  XCTestCase+LaunchStoreSpecs.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 6.09.2022.
//

import XCTest
import Launches

extension LaunchStoreSpecs where Self: XCTestCase {
    @discardableResult
    func delete(from sut: LaunchStore) -> Error? {
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
