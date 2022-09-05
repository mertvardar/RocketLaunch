//
//  LocalLaunchLoader.swift
//  Launches
//
//  Created by Mert Vardar on 30.08.2022.
//

import Foundation

public final class LocalLaunchLoader: LaunchLoader {
    private let store: LaunchStore
    private let currentDate: () -> Date

    public init(store: LaunchStore,
                currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalLaunchLoader {
    public typealias SaveResult = Error?

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

extension LocalLaunchLoader {
    public typealias LoadResult = LoadLaunchResult

    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .found(launches, timestamp) where LaunchCachePolicy.validate(timestamp, against: self.currentDate()):
                completion(.success(launches.toModels()))
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension LocalLaunchLoader {
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.store.deleteCachedLaunches { _ in }
            case let .found(_, timestamp) where !LaunchCachePolicy.validate(timestamp, against: self.currentDate()):
                self.store.deleteCachedLaunches { _ in }
            case .empty, .found: break
            }
        }
    }
}

private extension Array where Element == LaunchItem {
    func toLocal() -> [LocalLaunchItem] {
        return map { LocalLaunchItem(id: $0.id, name: $0.name, date: $0.date) }
    }
}

private extension Array where Element == LocalLaunchItem {
    func toModels() -> [LaunchItem] {
        return map { LaunchItem(id: $0.id, name: $0.name, date: $0.date) }
    }
}
