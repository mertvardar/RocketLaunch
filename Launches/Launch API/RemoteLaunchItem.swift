//
//  RemoteLaunchItem.swift
//  Launches
//
//  Created by Mert Vardar on 30.08.2022.
//

import Foundation

internal struct RemoteLaunchItem: Decodable {
    internal let id: Int
    internal let name: String
    internal let date_str: String
}
