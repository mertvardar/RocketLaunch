//
//  ManagedLaunch.swift
//  Launches
//
//  Created by Mert Vardar on 5.10.2022.
//

import CoreData

@objc(ManagedLaunch)
internal class ManagedLaunch: NSManagedObject {
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
