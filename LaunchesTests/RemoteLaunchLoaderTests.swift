//
//  RemoteLaunchLoaderTests.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 19.08.2022.
//

import XCTest
import Launches

class RemoteLaunchLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()

        XCTAssertEqual(client.requestedURLs, [])
    }

    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()

        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        sut.load()
        sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteLaunchLoader, client: HTTPCLientSpy) {
        let client = HTTPCLientSpy()
        let sut = RemoteLaunchLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPCLientSpy: HTTPClient {
        var requestedURLs = [URL]()

        func get(from url: URL) {
            requestedURLs.append(url)
        }
    }
}
