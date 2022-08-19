//
//  RemoteLaunchLoaderTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 19.08.2022.
//

import XCTest

class RemoteLaunchLoader {
    let url: URL
    let client: HTTPClient

    init(url: URL,
         client: HTTPClient) {
        self.url = url
        self.client = client
    }

    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class RemoteLaunchLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURL, url)
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteLaunchLoader, client: HTTPCLientSpy) {
        let client = HTTPCLientSpy()
        let sut = RemoteLaunchLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPCLientSpy: HTTPClient {
        var requestedURL: URL?

        func get(from url: URL) {
            requestedURL = url
        }
    }
}
