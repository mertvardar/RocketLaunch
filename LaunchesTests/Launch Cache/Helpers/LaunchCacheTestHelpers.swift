//
//  LaunchCacheTestHelpers.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 5.09.2022.
//

import Foundation

extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
