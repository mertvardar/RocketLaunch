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
        let launches: [LocalLaunchItem]
        let timestamp: Date
    }

    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("launches.store")

    func retrieve(completion: @escaping LaunchStore.RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(launches: cache.launches, timestamp: cache.timestamp))
    }

    func insert(_ launchItems: [LocalLaunchItem],
                timestamp: Date,
                completion: @escaping LaunchStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(launches: launchItems, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }

}

class CodableLaunchStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("launches.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("launches.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableLaunchStore()

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
        let sut = CodableLaunchStore()
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
        let sut = CodableLaunchStore()
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
}
