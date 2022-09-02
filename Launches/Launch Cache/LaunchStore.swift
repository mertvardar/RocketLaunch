//
//  LaunchStore.swift
//  Launches
//
//  Created by Mert Vardar on 30.08.2022.
//

import Foundation

public enum RetrieveCachedLaunchResult {
    case empty
    case found(launches: [LocalLaunchItem], timestamp: Date)
    case failure(Error)
}

public protocol LaunchStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrieveCompletion = (RetrieveCachedLaunchResult) -> Void

    func deleteCachedLaunches(completion: @escaping DeletionCompletion)
    func insert(_ launchItems: [LocalLaunchItem], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrieveCompletion)
}
