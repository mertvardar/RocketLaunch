//
//  RemoteLaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public final class RemoteLaunchLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Error) -> Void) {
        client.get(from: url) { error in
            completion(.connectivity)
        }
    }
}
