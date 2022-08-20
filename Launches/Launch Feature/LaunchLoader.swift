//
//  LaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 19.08.2022.
//

import Foundation

public enum LoadLaunchResult<Error: Swift.Error> {
    case success([LaunchItem])
    case failure(Error)
}

extension LoadLaunchResult: Equatable where Error: Equatable {}

protocol LaunchLoader {
    associatedtype Error: Swift.Error

    func load(completion: @escaping (LoadLaunchResult<Error>) -> Void)
}
