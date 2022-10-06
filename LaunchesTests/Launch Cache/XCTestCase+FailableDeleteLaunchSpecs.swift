//
//  XCTestCase+FailableDeleteLaunchStoreSpecs.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 7.09.2022.
//

import XCTest
import Launches

extension FailableDeleteLaunchStoreSpecs where Self: XCTestCase {
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
}
