//
//  Date+Extensions.swift
//
//
//  Created by Sagar Dagdu on 18/08/24.
//

import Foundation

extension Date {
    /// Current time in milliseconds
    /// - Returns: The current time in milliseconds
    static func currentMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    /// Check if the current time is ahead of the given timestamp by a certain number of seconds
    /// - Parameters:
    ///   - timestamp: The timestamp to compare against
    ///   - seconds: The number of seconds to compare
    /// - Returns: A boolean indicating if the current time is ahead of the given timestamp
    static func isTimeAhead(of timestamp: Int64, by seconds: Double) -> Bool {
        let currentTime = currentMillis()
        let differenceInMillis = currentTime - timestamp
        let thresholdInMillis = Int64(seconds * 1000)

        return differenceInMillis >= thresholdInMillis
    }
}
