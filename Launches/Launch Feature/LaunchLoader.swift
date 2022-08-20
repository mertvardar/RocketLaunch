//
//  LaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public enum LoadLaunchResult {
    case success([LaunchItem])
    case failure(Error)
}

public protocol LaunchLoader {
    func load(completion: @escaping (LoadLaunchResult) -> Void)
}
