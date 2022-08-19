//
//  RemoteLaunchLoaderTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 19.08.2022.
//

import XCTest

class RemoteLaunchLoader {
    func load() {
        HTTPClient.shared.requestedURL = URL(string: "https://a-url.com")
    }
}

class HTTPClient {
    static let shared: HTTPClient = HTTPClient()

    private init() {}

    var requestedURL: URL?
}

class RemoteLaunchLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient.shared
        _ = RemoteLaunchLoader()

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let client = HTTPClient.shared
        let sut = RemoteLaunchLoader()

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }
}
