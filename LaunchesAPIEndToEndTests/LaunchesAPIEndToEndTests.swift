//
//  LaunchesAPIEndToEndTests.swift
//  LaunchesAPIEndToEndTests
//
//  Created by Mert Vardar on 21.08.2022.
//

import XCTest
import Launches

class LaunchesAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETLaunchesResult_matchesFixedTestData() {
        let testServerURL = URL(string: "https://fdo.rocketlaunch.live/json/launches/next/5")!
        let client = URLSessionHTTPClient()
        let loader = RemoteLaunchLoader(url: testServerURL, client: client)

        let exp = expectation(description: "Wait for load completion")

        var receivedResult: LoadLaunchResult?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)

        switch receivedResult {
        case let .success(items)?:
            XCTAssertEqual(items.count, 5, "Expected 5 items in the test url, got \(items.count) instead.")
        case let .failure(error)?:
            XCTFail("Expected successful result, got \(error) instead.")
        default:
            XCTFail("Expected successful result, got no result instead.")
        }
    }
}
