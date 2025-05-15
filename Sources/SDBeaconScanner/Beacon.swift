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
    public let uuid: String

    /// The major of the scanned beacon.
    public let major: Int

    /// The minor of the scanned beacon
    public let minor: Int

    /// The RSSI of the scanned beacon
    public let rssi: Int

    /// The proximity of the scanned beacon
    public let proximity: CLProximity

    /// The accuracy of the proximity value, measured in meters from the beacon
    public let accuracy: CLLocationAccuracy

    /// The most recent timestamp representing when the beacon was observed
    public let timestamp: Int64
}
