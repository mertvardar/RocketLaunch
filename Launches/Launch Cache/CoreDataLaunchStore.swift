//
//  CoreDataLaunchStore.swift
//  Launches
//
//  Created by Mert Vardar on 4.10.2022.
//

import Foundation

public final class CoreDataLaunchStore: LaunchStore {

    public init() {}

    public func retrieve(completion: @escaping RetrieveCompletion) {
        completion(.empty)
    }

    public func insert(_ launchItems: [LocalLaunchItem], timestamp: Date, completion: @escaping InsertionCompletion) {

    }

    public func deleteCachedLaunches(completion: @escaping DeletionCompletion) {

    }
}
