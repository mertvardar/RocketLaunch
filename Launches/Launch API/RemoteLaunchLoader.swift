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
        case invalidData
    }

    public enum Result: Equatable {
        case success([LaunchItem])
        case failure(Error)
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    let result = try LaunchItemsMapper.map(data, response)
                    completion(.success(result))
                } catch {
                    completion(.failure(.invalidData))
                }

            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class LaunchItemsMapper {
    private struct Root: Decodable {
        let result: [Result]
    }

    private struct Result: Decodable {
        let id: Int
        let name: String
        let date_str: String

        var result: LaunchItem {
            return LaunchItem(id: id, name: name, date: date_str)
        }
    }

    static var OK_200: Int {
        return 200
    }

    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [LaunchItem] {
        guard response.statusCode == LaunchItemsMapper.OK_200 else {
            throw RemoteLaunchLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.result.map { $0.result }
    }
}
