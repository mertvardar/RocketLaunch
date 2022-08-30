//
//  LocalLaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 30.08.2022.
//

import Foundation

public final class LocalLaunchLoader {
    private let store: LaunchStore
    private let currentDate: () -> Date

    public typealias SaveResult = Error?

    public init(store: LaunchStore,
                currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func save(_ launchItems: [LaunchItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedLaunches { [weak self] error in
            guard let self = self else { return }

            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            } else {
                self.cache(launchItems, with: completion)
            }
        }
    }

    private func cache(_ items: [LaunchItem], with completion: @escaping (SaveResult) -> Void) {
        store.insert(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }

            completion(error)
        }
    }
}


private extension Array where Element == LaunchItem {
    func toLocal() -> [LocalLaunchItem] {
        return map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
    }
}
