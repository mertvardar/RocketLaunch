//
//  LaunchStore.swift
//  Launches
//
//  Created by Mert Vardar on 30.08.2022.
//

import Foundation

public protocol LaunchStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCachedLaunches(completion: @escaping DeletionCompletion)
    func insert(_ launchItems: [LocalLaunchItem], timestamp: Date, completion: @escaping InsertionCompletion)
}
