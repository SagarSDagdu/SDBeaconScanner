//
//  Beacon.swift
//
//
//  Created by Sagar Dagdu on 18/08/24.
//

import CoreLocation

/// A struct representing a beacon that has been scanned.
public struct Beacon {
    /// The UUID of the scanned beacon.
    let uuid: String

    /// The major of the scanned beacon.
    let major: Int

    /// The minor of the scanned beacon
    let minor: Int

    /// The RSSI of the scanned beacon
    let rssi: Int

    /// The proximity of the scanned beacon
    let proximity: CLProximity

    /// The accuracy of the proximity value, measured in meters from the beacon
    let accuracy: CLLocationAccuracy

    /// The most recent timestamp representing when the beacon was observed
    let timestamp: Int64
}

extension Beacon: Equatable {
    /// Check if two beacons are equal
    /// - Parameters:
    ///   - lhs: The left hand side beacon
    ///   - rhs: The right hand side beacon
    /// - Returns: A boolean indicating if the two beacons are
    public static func == (lhs: Beacon, rhs: Beacon) -> Bool {
        lhs.uuid == rhs.uuid &&
            lhs.major == rhs.major &&
            lhs.minor == rhs.minor
    }
}
