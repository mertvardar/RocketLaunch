//
//  CacheLaunchUseCaseTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 27.08.2022.
//

import XCTest
import Launches

class LocalLaunchLoader {
    let store: LaunchStore

    init(store: LaunchStore) {
        self.store = store
    }

    func save(_ launchItems: [LaunchItem]) {
        store.deleteCachedLaunhes()
    }
}

class LaunchStore {
    var deleteCachedLaunchCallCount = 0
    var insertCallCount = 0

    func deleteCachedLaunhes() {
        deleteCachedLaunchCallCount += 1
    }

    func completeDeletion(with error: Error, at index: Int = 0) {

    }
}

class CacheLaunchUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.deleteCachedLaunchCallCount, 0)
    }

    func test_save_requestCacheDeletion() {
        let (sut, store) = makeSUT()
        let items = [LaunchItem(id: 0, name: "Launch 1", date: "01012022"),
                     LaunchItem(id: 1, name: "Launch 2", date: "02012022")]
        sut.save(items)
        XCTAssertEqual(store.deleteCachedLaunchCallCount, 1)
    }

    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let items = [LaunchItem(id: 0, name: "Launch 1", date: "01012022"),
                     LaunchItem(id: 1, name: "Launch 2", date: "02012022")]
        let deletionError = anyNSError()

        sut.save(items)
        store.completeDeletion(with: deletionError)

        XCTAssertEqual(store.insertCallCount, 0)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file,
                         line: UInt = #line) -> (sut: LocalLaunchLoader, store: LaunchStore) {
        let store = LaunchStore()
        let sut = LocalLaunchLoader(store: store)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }

    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
