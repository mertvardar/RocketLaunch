//
//  CoreDataLaunchStore.swift
//  Launches
//
//  Created by Mert Vardar on 4.10.2022.
//

import CoreData

public final class CoreDataLaunchStore: LaunchStore {

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "LaunchStore", url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        perform { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.found(launches: cache.localLaunches, timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func insert(_ launchItems: [LocalLaunchItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        perform { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.launches = ManagedLaunch.launches(from: launchItems, in: context)

                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func deleteCachedLaunches(completion: @escaping DeletionCompletion) {
        perform { context in
            do {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    private func perform(_ action: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.context
        context.perform { action(context) }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var launches: NSOrderedSet

    var localLaunches: [LocalLaunchItem] {
        return launches.compactMap { ($0 as? ManagedLaunch)?.local}
    }

    static func newUniqueInstance(in context: NSManagedObjectContext) throws -> ManagedCache {
        try find(in: context).map(context.delete)
        return ManagedCache(context: context)
    }

    static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
        request.returnsObjectsAsFaults = false

        return try context.fetch(request).first
    }
}

@objc(ManagedLaunch)
private class ManagedLaunch: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var name: String
    @NSManaged var dateString: String
    @NSManaged var cache: ManagedCache

    var local: LocalLaunchItem {
        return LocalLaunchItem(id: Int(id), name: name, date: dateString)
    }

    static func launches(from localLaunches: [LocalLaunchItem], in context: NSManagedObjectContext) -> NSOrderedSet {
        return NSOrderedSet(array: localLaunches.map { local in
            let managed = ManagedLaunch(context: context)
            managed.id = Int64(local.id)
            managed.name = local.name
            managed.dateString = local.date
            return managed
        })
    }
}
