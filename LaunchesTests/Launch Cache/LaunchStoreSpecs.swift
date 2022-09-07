//
//  LaunchStoreSpecs.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 6.09.2022.
//

import Foundation

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
    func test_delete_emptiesPreviouslyInsertedCache()

    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveLaunchStoreSpecs: LaunchStoreSpecs {
    func test_retrieve_deliversFailureOnRetrievalError()
    func test_retrieve_hasNoSideEffectsOnFailure()
}

protocol FailableInsertLaunchStoreSpecs: LaunchStoreSpecs {
    func test_insert_deliversErrorOnInsertionError()
    func test_insert_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteLaunchStoreSpecs: LaunchStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_hasNoSideEffectsOnDeletionError()
}

typealias FailableLaunchStore = FailableRetrieveLaunchStoreSpecs & FailableInsertLaunchStoreSpecs & FailableDeleteLaunchStoreSpecs
