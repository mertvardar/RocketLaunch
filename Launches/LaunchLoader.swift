//
//  LaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

enum LoadLaunchResult {
    case success([LaunchItem])
    case error(Error)
}

protocol LaunchLoader {
    func load(completion: @escaping (LoadLaunchResult) -> Void)
}
