//
//  CoreDataLaunchStore.swift
//  Launches
//
//  Created by Mert Vardar on 4.10.2022.
//

import CoreData

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

private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var launches: NSOrderedSet
}

private class ManagedLaunch: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var name: String
    @NSManaged var dateString: String
    @NSManaged var cache: ManagedCache
}
