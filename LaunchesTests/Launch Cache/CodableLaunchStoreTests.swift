//
//  CodableLaunchStoreTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 5.09.2022.
//

import XCTest
import Launches

class CodableLaunchStore {
    private struct Cache: Codable {
        let launches: [CodableLocalLaunchItem]
        let timestamp: Date

        var localLaunches: [LocalLaunchItem] {
            return launches.map { $0.local }
        }
    }

    private struct CodableLocalLaunchItem: Codable {
        private let id: Int
        private let name: String
        private let date: String

        init(_ launch: LocalLaunchItem) {
            id = launch.id
            name = launch.name
            date = launch.date
        }

        var local: LocalLaunchItem {
            LocalLaunchItem(id: id, name: name, date: date)
        }
    }

    private let storeURL: URL

    init(storeURL: URL) {
        self.storeURL = storeURL
    }

    func retrieve(completion: @escaping LaunchStore.RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(launches: cache.localLaunches, timestamp: cache.timestamp))
    }

    func insert(_ launchItems: [LocalLaunchItem],
                timestamp: Date,
                completion: @escaping LaunchStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(launches: launchItems.map(CodableLocalLaunchItem.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }

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

    // - MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableLaunchStore {
        let sut = CodableLaunchStore(storeURL: testSpecificStoreURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func insert(_ cache: (launches: [LocalLaunchItem], timestamp: Date), to sut: CodableLaunchStore) {
        let exp = expectation(description: "Wait for cache insertion")

        sut.insert(cache.launches, timestamp: cache.timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected launches to be inserted successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: CodableLaunchStore, toRetrieve expectedResult: RetrieveCachedLaunchResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty):
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

    private func expect(_ sut: CodableLaunchStore, toRetrieveTwice expectedResult: RetrieveCachedLaunchResult, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult)
        expect(sut, toRetrieve: expectedResult)
    }

    func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
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
