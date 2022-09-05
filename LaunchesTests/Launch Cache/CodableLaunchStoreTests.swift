//
//  CodableLaunchStoreTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 5.09.2022.
//

import XCTest
import Launches

class CodableLaunchStore {
    func retrieve(completion: @escaping LaunchStore.RetrieveCompletion) {
        completion(.empty)
    }
}

class CodableLaunchStoreTests: XCTestCase {

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
}
