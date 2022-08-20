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

    internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [LaunchItem] {
        guard response.statusCode == LaunchItemsMapper.OK_200 else {
            throw RemoteLaunchLoader.Error.invalidData
        }
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.result.map { $0.result }
    }
}
