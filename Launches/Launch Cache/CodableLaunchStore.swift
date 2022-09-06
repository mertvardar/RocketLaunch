//
//  CodableLaunchStore.swift
//  Launches
//
//  Created by Mert Vardar on 6.09.2022.
//

import Foundation

public class CodableLaunchStore: LaunchStore {
    private struct Cache: Codable {
        let launches: [CodableLocalLaunchItem]
        let timestamp: Date

        var localLaunches: [LocalLaunchItem] {
            return launches.map { $0.local }
        }
    }

    private struct CodableLocalLaunchItem: Codable {
        private let id: Int
        private let name: String
        private let date: String

        init(_ launch: LocalLaunchItem) {
            id = launch.id
            name = launch.name
            date = launch.date
        }

        var local: LocalLaunchItem {
            LocalLaunchItem(id: id, name: name, date: date)
        }
    }

    private let storeURL: URL

    public init(storeURL: URL) {
        self.storeURL = storeURL
    }

    public func retrieve(completion: @escaping RetrieveCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        do {
            let decoder = JSONDecoder()
            let cache = try decoder.decode(Cache.self, from: data)
            completion(.found(launches: cache.localLaunches, timestamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }

    public func insert(_ launchItems: [LocalLaunchItem],
                timestamp: Date,
                completion: @escaping InsertionCompletion) {
        do {
            let encoder = JSONEncoder()
            let cache = Cache(launches: launchItems.map(CodableLocalLaunchItem.init), timestamp: timestamp)
            let encoded = try encoder.encode(cache)
            try encoded.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }

    public func deleteCachedLaunches(completion: @escaping DeletionCompletion) {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return completion(nil)
        }

        do {
            try FileManager.default.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
