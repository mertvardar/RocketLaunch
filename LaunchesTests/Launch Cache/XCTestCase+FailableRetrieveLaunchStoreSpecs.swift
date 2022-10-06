//
//  XCTestCase+FailableRetrieveLaunchStoreSpecs.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 7.09.2022.
//

import XCTest
import Launches

extension FailableRetrieveLaunchStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .failure(anyNSError()), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: LaunchStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .failure(anyNSError()), file: file, line: line)
    }
}
