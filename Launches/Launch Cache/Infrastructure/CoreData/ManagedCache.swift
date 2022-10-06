//
//  ManagedCache.swift
//  Launches
//
//  Created by Mert Vardar on 5.10.2022.
//

import CoreData

@objc(ManagedCache)
internal class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var launches: NSOrderedSet
}

extension ManagedCache {
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
