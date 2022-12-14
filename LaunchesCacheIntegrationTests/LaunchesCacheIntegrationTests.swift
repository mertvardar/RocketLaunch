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

        expect(sut, toLoad: [])
    }

    func test_load_deliversItemsSavedOnASeparateInstance() {
        let sutToPerformSave = makeSUT()
        let sutToPerformLoad = makeSUT()
        let launches = [LaunchItem(id: 1, name: "Launch", date: "Today")]

        save(launches, with: sutToPerformSave)

        expect(sutToPerformLoad, toLoad: [LaunchItem(id: 1, name: "Launch", date: "Today")])
    }

    func test_load_overridesItemsSavedOnASeparateInstance() {
        let sutToPerformFirstSave = makeSUT()
        let sutToPerformSecondSave = makeSUT()
        let sutToPerformLoad = makeSUT()

        let firstLaunches = [LaunchItem(id: 1, name: "Launch1", date: "Today")]
        let secondLaunches = [LaunchItem(id: 2, name: "Launch2", date: "Tomorrow")]

        save(firstLaunches, with: sutToPerformFirstSave)
        save(secondLaunches, with: sutToPerformSecondSave)

        expect(sutToPerformLoad, toLoad: secondLaunches)
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

    private func save(_ launches: [LaunchItem], with sut: LocalLaunchLoader, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for save completion")
        sut.save(launches) { saveError in
            XCTAssertNil(saveError, "Expected to save launches successfully")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    private func expect(_ sut: LocalLaunchLoader, toLoad expectedLaunches: [LaunchItem], file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")
        sut.load { result in
            switch result {
            case let .success(loadedLaunches):
                XCTAssertEqual(loadedLaunches, expectedLaunches, file: file, line: line)

            case let .failure(error):
                XCTFail("Expected succesful launches result, got \(error) instead", file: file, line: line)
            }

            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
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
