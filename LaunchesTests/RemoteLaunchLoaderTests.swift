//
//  RemoteLaunchLoaderTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 19.08.2022.
//

import XCTest

class RemoteLaunchLoader {
    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func load() {
        client.get(from: URL(string: "https://a-url.com")!)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPCLientSpy: HTTPClient {
    var requestedURL: URL?

    func get(from url: URL) {
        requestedURL = url
    }
}

class RemoteLaunchLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPCLientSpy()
        _ = RemoteLaunchLoader(client: client)

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let client = HTTPCLientSpy()
        let sut = RemoteLaunchLoader(client: client)

        sut.load()

        XCTAssertNotNil(client.requestedURL)
    }
}
