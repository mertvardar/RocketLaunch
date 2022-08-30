//
//  LaunchItemsMapper.swift
//  Launches
//
//  Created by Mert Vardar on 20.08.2022.
//

import Foundation

internal struct RemoteLaunchItem: Decodable {
    internal let id: Int
    internal let name: String
    internal let date_str: String
}

internal final class LaunchItemsMapper {
    private struct Root: Decodable {
        let result: [RemoteLaunchItem]
    }

    private static var OK_200: Int {
        return 200
    }

    internal static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteLaunchItem] {
        guard response.statusCode == LaunchItemsMapper.OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteLaunchLoader.Error.invalidData
        }

        return root.result
    }
}
