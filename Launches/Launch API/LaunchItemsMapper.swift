//
//  LaunchItemsMapper.swift
//  Launches
//
//  Created by Mert Vardar on 20.08.2022.
//

import Foundation

internal final class LaunchItemsMapper {
    private struct Root: Decodable {
        let result: [Result]

        var launches: [LaunchItem] {
            result.map { $0.result }
        }
    }

    private struct Result: Decodable {
        let id: Int
        let name: String
        let date_str: String

        var result: LaunchItem {
            return LaunchItem(id: id, name: name, date: date_str)
        }
    }

    private static var OK_200: Int {
        return 200
    }

    internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteLaunchLoader.Result {
        guard response.statusCode == LaunchItemsMapper.OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(.invalidData)
        }

        return .success(root.launches)
    }
}
