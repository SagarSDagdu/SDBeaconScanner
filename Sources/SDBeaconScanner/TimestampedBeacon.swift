//
//  TimestampedBeacon.swift
//
//
//  Created by Sagar Dagdu on 18/08/24.
//

import CoreLocation

/// A struct representing a beacon that has been scanned, along with the timestamp when it was observed.
struct TimestampedBeacon {
    /// The beacon that was observed
    let beacon: CLBeacon

    /// The timestamp representing when the beacon was observed
    let timestamp: Int64

    init(beacon: CLBeacon,
         timestamp: Int64 = Date.currentMillis())
    {
        self.beacon = beacon
        self.timestamp = timestamp
    }
}

extension TimestampedBeacon {
    /// Convert the ``TimestampedBeacon`` to a ``Beacon``
    /// - Returns: A ``Beacon``
    func toBeacon() -> Beacon {
        let internalCLBeacon = beacon
        return Beacon(
            uuid: internalCLBeacon.uuid.uuidString,
            major: internalCLBeacon.major.intValue,
            minor: internalCLBeacon.minor.intValue,
            rssi: internalCLBeacon.rssi,
            proximity: internalCLBeacon.proximity,
            accuracy: internalCLBeacon.accuracy,
            timestamp: timestamp
        )
    }
}
