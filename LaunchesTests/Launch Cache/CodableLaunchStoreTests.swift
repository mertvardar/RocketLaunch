//
//  CodableLaunchStoreTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 5.09.2022.
//

import XCTest
import Launches

protocol LaunchStoreSpecs {
    func test_retrieve_deliversEmptyOnEmptyCache()
    func test_retrieve_hasNoSideEffectsOnEmptyCache()
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache()

    func test_insert_deliversNoErrorOnEmptyCache()
    func test_insert_deliversNoErrorOnNonEmptyCache()
    func test_insert_overridesPreviouslyInsertedCacheValues()

    func test_delete_deliversNoErrorOnEmptyCache()
    func test_delete_hasNoSideEffectsOnEmptyCache()
    func test_delete_deliversNoErrorOnNonEmptyCache()
    func test_deletion_emptiesPreviouslyInsertedCache()

    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveLaunchSpecs {
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_deliversFailureTwiceOnRetrievalError()
}

protocol FailableInsertLaunchSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteLaunchSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_hasNoSideEffectsOnDeletionError()
}

class CodableLaunchStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()

        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()

        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieve: .empty)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        expect(sut, toRetrieveTwice: .empty)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let givenLaunches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let givenLocalLaunches = givenLaunches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let givenTimestamp = Date()

        insert((givenLocalLaunches, givenTimestamp), to: sut)
        expect(sut, toRetrieve: .found(launches: givenLocalLaunches, timestamp: givenTimestamp))
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let givenLaunches = [LaunchItem(id: 1, name: "1", date: "1"),
                             LaunchItem(id: 2, name: "2", date: "2")]
        let givenLocalLaunches = givenLaunches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let givenTimestamp = Date()

        insert((givenLocalLaunches, givenTimestamp), to: sut)
        expect(sut, toRetrieve: .found(launches: givenLocalLaunches, timestamp: givenTimestamp))
    }

    func test_retrieve_deliversFailureOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieve: .failure(anyNSError()))
    }

    func test_retrieve_deliversFailureTwiceOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL: storeURL)

        try! "invalid data".write(to: storeURL, atomically: false, encoding: .utf8)

        expect(sut, toRetrieveTwice: .failure(anyNSError()))
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        let firstInsertedCache = (launches: [LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date())
        let firstInsertionError = insert(firstInsertedCache, to: sut)
        XCTAssertNil(firstInsertionError, "Expected to insert cache successfully")

        let latestInsertedCache = (launches: [LocalLaunchItem(id: 2, name: "2", date: "2")], timestamp: Date())
        let latestInsertionError = insert(latestInsertedCache, to: sut)
        XCTAssertNil(latestInsertionError, "Expected to insert cache successfully")

        expect(sut, toRetrieve: .found(launches: latestInsertedCache.launches, timestamp: latestInsertedCache.timestamp))
    }

    func test_insert_deliversErrorOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid.url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let cache = (launches: [LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date())

        let insertionError = insert(cache, to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        let firstInsertedCache = (launches: [LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date())
        insert(firstInsertedCache, to: sut)

        let latestInsertedCache = (launches: [LocalLaunchItem(id: 2, name: "2", date: "2")], timestamp: Date())
        let latestInsertionError = insert(latestInsertedCache, to: sut)
        XCTAssertNil(latestInsertionError, "Expected to insert cache successfully")
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        let cache = (launches: [LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date())

        let insertionError = insert(cache, to: sut)

        XCTAssertNil(insertionError, "Expected cache insertion error to be nil")
    }

    func test_insert_hasNoSideEffectsOnInsertionError() {
        let invalidStoreURL = URL(string: "invalid.url")!
        let sut = makeSUT(storeURL: invalidStoreURL)
        let cache = (launches: [LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date())

        insert(cache, to: sut)

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        let cache = (launches: [LocalLaunchItem(id: 1, name: "1", date: "1")], timestamp: Date())

        insert(cache, to: sut)

        let deletionError = delete(from: sut)

        XCTAssertNil(deletionError, "Expected deletionError to be nil")
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected cache deletion not to fail")
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected cache deletion not to fail")

        expect(sut, toRetrieve: .empty)
    }

    func test_deletion_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT(storeURL: testSpecificStoreURL())

        let insertedCache = ([LocalLaunchItem(id: 1, name: "1", date: "1")], Date())
        let insertionError = insert(insertedCache, to: sut)
        XCTAssertNil(insertionError, "Expected no error on insertion")

        let deletionError = delete(from: sut)
        XCTAssertNil(deletionError, "Expected cache deletion not to fail")

        expect(sut, toRetrieve: .empty)
    }

    func test_delete_deliversErrorOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        let deletionError = delete(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail")
    }

    func test_delete_hasNoSideEffectsOnDeletionError() {
        let noDeletePermissionURL = cachesDirectory()
        let sut = makeSUT(storeURL: noDeletePermissionURL)

        delete(from: sut)
        expect(sut, toRetrieve: .empty)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
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

        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order")
    }

    // - MARK: Helpers

    private func makeSUT(storeURL: URL? = nil,
                         file: StaticString = #file, line: UInt = #line) -> LaunchStore {
        let sut = CodableLaunchStore(storeURL: storeURL ?? testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    @discardableResult
    private func delete(from sut: LaunchStore) -> Error? {
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
    private func insert(_ cache: (launches: [LocalLaunchItem], timestamp: Date), to sut: LaunchStore) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(cache.launches, timestamp: cache.timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }

    private func expect(_ sut: LaunchStore, toRetrieve expectedResult: RetrieveCachedLaunchResult, file: StaticString = #file, line: UInt = #line) {
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

    private func expect(_ sut: LaunchStore, toRetrieveTwice expectedResult: RetrieveCachedLaunchResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }

    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }

    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
