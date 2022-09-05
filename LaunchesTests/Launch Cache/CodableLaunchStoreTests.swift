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

        try? FileManager.default.removeItem(at: storeURL())
    }

    override func tearDown() {
        super.tearDown()

        try? FileManager.default.removeItem(at: storeURL())
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for completion")
        sut.retrieve { result in
            switch result {
            case .empty:
                break

            default:
                XCTFail("Expected empty result, got \(result) instead")
            }

            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        let exp = expectation(description: "Wait for completion")

        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break

                default:
                    XCTFail("Expected both empty result, got \(firstResult) and \(secondResult) instead")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = makeSUT()
        let givenLaunches = [LaunchItem(id: 1, name: "1", date: "1"),
                        LaunchItem(id: 2, name: "2", date: "2")]
        let givenLocalLaunches = givenLaunches.map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
        let givenTimestamp = Date()
        let exp = expectation(description: "Wait for completion")

        sut.insert(givenLocalLaunches, timestamp: givenTimestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected launches to be inserted successfully")

            sut.retrieve { result in
                switch result {
                case let .found(launches, timestamp):
                    XCTAssertEqual(givenLocalLaunches, launches)
                    XCTAssertEqual(givenTimestamp, timestamp)
                default:
                    XCTFail("Expected (\(givenLaunches), \(givenTimestamp)) equal to \(result)")
                }

                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    // - MARK: Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableLaunchStore {
        let sut = CodableLaunchStore(storeURL: storeURL())
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    func storeURL() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("launches.store")
    }
}
