//
//  LaunchStoreSpy.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 1.09.2022.
//

import Foundation
import Launches

class LaunchStoreSpy: LaunchStore {
    enum ReceivedMessage: Equatable {
        case deleteCacheLaunch
        case insertCacheLaunch([LocalLaunchItem], Date)
        case retrieve
    }
    private(set) var receivedMessages = [ReceivedMessage]()

    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var receiveCompletions = [RetrieveCompletion]()

    func deleteCachedLaunches(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCacheLaunch)
    }

    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }

    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }

    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }

    func insert(_ launchItems: [LocalLaunchItem],
                timestamp: Date,
                completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insertCacheLaunch(launchItems, timestamp))
    }

    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }

    func completeRetrieval(with error: Error, at index: Int = 0) {
        receiveCompletions[index](.failure(error))
    }

    func retrieve(completion: @escaping RetrieveCompletion) {
        receiveCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }

    func completeRetrievalWithEmptyCache(at index: Int = 0) {
        receiveCompletions[index](.empty)
    }

    func completeRetrieval(with launches: [LocalLaunchItem], timestamp: Date, at index: Int = 0) {
        receiveCompletions[index](.found(launches: launches, timestamp: timestamp))
    }
}
