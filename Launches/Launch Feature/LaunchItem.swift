//
//  LaunchItem.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public struct LaunchItem: Equatable {
    public let id: Int
    public let name: String
    public let date: String

    public init(id: Int, name: String, date: String) {
        self.id = id
        self.name = name
        self.date = date
    }
}
