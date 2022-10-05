//
//  LaunchesCacheIntegrationTests.swift
//  LaunchesCacheIntegrationTests
//
//  Created by Mert Vardar on 5.10.2022.
//

import XCTest
import Launches

class LaunchesCacheIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        setupEmptyStoreState()
    }

    override func tearDown() {
        super.tearDown()
        undoStoreSideEffects()
    }

    func test_load_deliversNoItemsOnEmptyCache() {
        let sut = makeSUT()

        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case let .success(launches):
                XCTAssertEqual(launches, [], "Expected empty launches")

            case let .failure(error):
                XCTFail("Expected succesful launches result, got \(error) instead")
            }

            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let launches = [LaunchItem(id: 1, name: "Launch", date: "Today")]

        let saveExp = expectation(description: "Wait for save completion")
        sutToPerformSave.save(launches) { saveError in
            XCTAssertNil(saveError, "Expected to save launches successfully")
            saveExp.fulfill()
        }
        wait(for: [saveExp], timeout: 1.0)

        let loadExp = expectation(description: "Wait for load completion")
        sutToPerformLoad.load { loadResult in
            switch loadResult {
            case let .success(launches):
                XCTAssertEqual(launches, launches)
            case let .failure(error):
                XCTFail("Expected successfull launches result, got \(error) instead")
            }
            loadExp.fulfill()
        }
        wait(for: [loadExp], timeout: 1.0)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> LocalLaunchLoader {
        let storeBundle = Bundle(for: CoreDataLaunchStore.self)
        let storeURL = testSpecificStoreURL()
        let store = try! CoreDataLaunchStore(storeURL: storeURL, bundle: storeBundle)
        let sut = LocalLaunchLoader(store: store, currentDate: Date.init)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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

    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }

    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
