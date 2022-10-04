//
//  CoreDataLaunchStoreTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 4.10.2022.
//

import XCTest
import Launches

class CoreDataLaunchStoreTests: XCTestCase, LaunchStoreSpecs {

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {

    }

    func test_insert_deliversNoErrorOnEmptyCache() {

    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {

    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {

    }

    func test_delete_deliversNoErrorOnEmptyCache() {

    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {

    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {

    }

    func test_delete_emptiesPreviouslyInsertedCache() {

    }

    func test_storeSideEffects_runSerially() {

    }

    // MARK: - Helpers
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LaunchStore {
        let storeBundle = Bundle(for: CoreDataLaunchStoreTests.self)
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataLaunchStore(storeURL: storeURL, bundle: storeBundle)

        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
