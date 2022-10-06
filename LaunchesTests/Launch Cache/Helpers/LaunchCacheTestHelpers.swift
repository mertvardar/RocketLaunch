//
//  LaunchCacheTestHelpers.swift
//  LaunchesTests
//
//  Created by Mert Vardar on 5.09.2022.
//

import Foundation

extension Date {
    func minusLaunchCacheMaxAge() -> Date {
        return adding(days: -launchCacheMaxAgeInDays)
    }

    private var launchCacheMaxAgeInDays: Int {
        return 7
    }

    private func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
}

extension Date {
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
