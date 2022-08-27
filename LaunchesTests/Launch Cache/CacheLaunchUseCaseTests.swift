//
//  CacheLaunchUseCaseTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 27.08.2022.
//

import XCTest

class LocalLaunchLoader {
    let store: LaunchStore

    init(store: LaunchStore) {
        self.store = store
    }
}

class LaunchStore {
    var deleteCachedLaunchCallCount = 0
}

class CacheLaunchUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = LaunchStore()
        _ = LocalLaunchLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedLaunchCallCount, 0)
    }
}
