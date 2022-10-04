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
        let context = self.context
        context.perform {
            do {
                let request = NSFetchRequest<ManagedCache>(entityName: ManagedCache.entity().name!)
                request.returnsObjectsAsFaults = false

                if let cache = try context.fetch(request).first {
                    completion(.found(launches: cache.launches
                        .compactMap { ($0 as? ManagedLaunch)}
                        .map { LocalLaunchItem(id: Int($0.id), name: $0.name, date: $0.dateString)},
                                      timestamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    public func insert(_ launchItems: [LocalLaunchItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        let context = self.context
        context.perform {
            do {
                let managedCache = ManagedCache(context: context)
                managedCache.timestamp = timestamp
                managedCache.launches = NSOrderedSet(array: launchItems.map { localLaunch in
                    let managed = ManagedLaunch(context: context)
                    managed.id = Int64(localLaunch.id)
                    managed.name = localLaunch.name
                    managed.dateString = localLaunch.date
                    return managed
                })

                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func deleteCachedLaunches(completion: @escaping DeletionCompletion) {

    }
}

private extension NSPersistentContainer {
    enum LoadingError: Swift.Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }

    static func load(modelName name: String, url: URL, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, in: bundle) else {
            throw LoadingError.modelNotFound
        }

        let description = NSPersistentStoreDescription(url: url)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        container.persistentStoreDescriptions = [description]

        var loadError: Swift.Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw LoadingError.failedToLoadPersistentStores($0) }

        return container
    }
}

private extension NSManagedObjectModel {
    static func with(name: String, in bundle: Bundle) -> NSManagedObjectModel? {
        return bundle
            .url(forResource: name, withExtension: "momd")
            .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }
}

@objc(ManagedCache)
private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var launches: NSOrderedSet
}

@objc(ManagedLaunch)
private class ManagedLaunch: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var name: String
    @NSManaged var dateString: String
    @NSManaged var cache: ManagedCache
}
