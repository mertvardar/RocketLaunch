//
//  RemoteLaunchLoaderTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 19.08.2022.
//

import XCTest

class RemoteLaunchLoader {
    func load() {
        HTTPClient.shared.get(from: URL(string: "https://a-url.com")!)
    }
}

class HTTPClient {
    static var shared: HTTPClient = HTTPClient()

    func get(from url: URL) {}
}

class HTTPCLientSpy: HTTPClient {
    var requestedURL: URL?

    override func get(from url: URL) {
        requestedURL = url
    }
}

class RemoteLaunchLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPCLientSpy()
        HTTPClient.shared = client
        _ = RemoteLaunchLoader()

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let client = HTTPCLientSpy()
        HTTPClient.shared = client
        let sut = RemoteLaunchLoader()

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }
}
