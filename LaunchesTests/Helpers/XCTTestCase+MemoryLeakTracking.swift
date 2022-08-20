//
//  XCTTestCase+MemoryLeakTracking.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 20.08.2022.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject,
                             file: StaticString = #file,
                             line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
