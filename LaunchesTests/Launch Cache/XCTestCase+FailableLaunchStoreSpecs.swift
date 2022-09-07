//
//  XCTestCase+FailableLaunchStoreSpecs.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 7.09.2022.
//

import XCTest
import Launches

extension FailableInsertLaunchStoreSpecs where Self: XCTestCase {
    func assertThatInsertDeliversErrorOnInsertionError(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }

    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        insert(([LocalLaunchItem(id: 1, name: "1", date: "1")], Date()), to: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
}
