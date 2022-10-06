//
//  RemoteLaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public final class RemoteLaunchLoader: LaunchLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadLaunchResult

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch result {
            case let .success(data, response):
                completion(RemoteLaunchLoader.map(data, from: response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }

    private static func map(_ data: Data, from response:  HTTPURLResponse) -> Result {
        do {
            let items = try LaunchItemsMapper.map(data, from: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension Array where Element == RemoteLaunchItem {
    func toModels() -> [LaunchItem] {
        return map { LaunchItem(id: $0.id, name: $0.name, date: $0.date_str) }
    }
}
