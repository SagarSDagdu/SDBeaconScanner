//
//  SDBeaconScanner.swift
//
//
//  Created by Sagar Dagdu on 18/08/24.
//

import CoreLocation

/// Completion handler for the beacon scanning operation.
public typealias BeaconScanningCompletion = ([Beacon], Error?) -> Void

/// Errors that can be reported by the beacon scanner
public enum BeaconScannerError: Error {
    /// The UUID provided is invalid
    case invalidUUID

    /// Ranging is unavailable on the device
    case rangingUnavailable
    
    /// A generic error with an associated ``NSError`` object. This error will be reported when the location manager notifies and error through the `didFailRangingFor` delegate method
    case rangingFailed(NSError)
}

/**
 A class that handles scanning for Bluetooth beacons using CoreLocation's beacon ranging API.

 The class allows you to start scanning for beacons based on their UUID, and optionally major and minor values. It utilizes CoreLocation's `CLLocationManager` for beacon scanning and provides a timeout mechanism to ensure that scanning doesn't run indefinitely.
 After a set time (default: 20 seconds) or once beacons are found, the scan automatically stops, and the results are reported to the caller via the provided completion handler.

 The class is designed as a singleton (``SDBeaconScanner/shared``) to ensure there is only one instance managing beacon scans at a time.
 */
public final class SDBeaconScanner: NSObject {
    private var beaconIdentityConstraint: CLBeaconIdentityConstraint?

    private var foundBeacons: [TimestampedBeacon] = []

    private let beaconScanningQueue = DispatchQueue(label: "com.sdbeaconscanner.beaconscanning")

    private var completionHandler: BeaconScanningCompletion?

    /// The timer that tracks the timeout for the beacon scan
    private var noBeaconsFoundTimeoutTimer: DispatchSourceTimer?

    private var scanStartTimestampMillis: Int64 = 0
    
    /// The timeout duration for the beacon scan. If no beacons are found within this time, the scan will stop and an empty array will be returned through the completion handler.
    private let scanTimeoutSeconds: TimeInterval = 15.0
    
    /// The location manager used for ranging beacons
    private let locationManager: CLLocationManager

    /// The shared singleton instance of the beacon scanner
    public static let shared = SDBeaconScanner()

    override private init() {
        locationManager = CLLocationManager()

        super.init()

        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
    }

    /**
     Starts scanning for beacons with a specified UUID.

     - Parameter uuid: The UUID string of the beacons to scan for.
     - Parameter completion: A closure that gets called once the scan completes, either due to timeout or because beacons were found. The closure receives an array of ``Beacon`` objects and an optional error.

     ### Behavior
     - The scan will start for beacons matching the provided UUID.
     - The scan will automatically stop after 30 seconds if no beacons are found.
     - If any beacons are found before the timeout, the scan will stop and report the results immediately.
     - If a scan is already in progress, it will stop and a new one will begin.

     - Note: Ensure that location permissions are correctly configured for the app, including background location permission.
     */
    public func getNearbyBeacons(
        uuid: String,
        completion: @escaping BeaconScanningCompletion
    ) {
        // Call the private method with only UUID
        startBeaconScan(uuid: uuid,
                        major: nil,
                        minor: nil,
                        completion: completion)
    }

    /**
     Starts scanning for beacons with a specified UUID, major, and minor values.

     - Parameter uuid: The UUID string of the beacons to scan for.
     - Parameter major: The major value of the beacons to scan for.
     - Parameter minor: The minor value of the beacons to scan for.
     - Parameter completion: A closure that gets called once the scan completes, either due to timeout or because beacons were found. The closure receives an array of ``Beacon`` objects and an optional error.

     ### Behavior
     - The scan will start for beacons matching the provided UUID, major, and minor values.
     - The scan will automatically stop after 30 seconds if no beacons are found.
     - If any beacons are found before the timeout, the scan will stop and report the results immediately.
     - If a scan is already in progress, it will stop and a new one will begin.

     - Note: Ensure that location permissions are correctly configured for the app, including background location permission.
     */
    public func getNearbyBeacons(
        uuid: String,
        major: UInt16,
        minor: UInt16,
        completion: @escaping BeaconScanningCompletion
    ) {
        // Call the private method with UUID, major, and minor values
        startBeaconScan(uuid: uuid,
                        major: major,
                        minor: minor,
                        completion: completion)
    }
}

extension SDBeaconScanner: CLLocationManagerDelegate {
    public func locationManager(
        _: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying _: CLBeaconIdentityConstraint
    ) {
        beaconScanningQueue.async { [weak self] in
            guard let self = self else { return }

            let isTimeUp = Date.isTimeAhead(
                of: self.scanStartTimestampMillis,
                by: 5.0
            )

            let hasFoundBeacons = !self.foundBeacons.isEmpty

            self.processRangedBeacons(rangedBeacons: beacons)

            if isTimeUp, hasFoundBeacons {
                // If beacons have been found and the time is up, stop scanning
                print("Stopping beacon scan due to found beacons \(Date.currentMillis())")
                self.stopScanningAndReportResults(error: nil)
            }
        }
    }

    public func locationManager(_: CLLocationManager,
                                didFailRangingFor _: CLBeaconIdentityConstraint,
                                error: any Error)
    {
        beaconScanningQueue.async {
            let rangingError = BeaconScannerError.rangingFailed(error as NSError)
            self.stopScanningAndReportResults(error: rangingError)
        }
    }
}

private extension SDBeaconScanner {
    func startBeaconScan(
        uuid: String,
        major: UInt16?,
        minor: UInt16?,
        completion: @escaping BeaconScanningCompletion
    ) {
        if scanStartTimestampMillis > 0 {
            print("Beacon scan already in progress, stopping it")
            stopScanningAndReportResults(error: nil)
        }

        guard let uuidToScan = UUID(uuidString: uuid) else {
            print("Invalid UUID \(uuid)")
            completion([], BeaconScannerError.invalidUUID)
            return
        }

        guard CLLocationManager.isRangingAvailable() else {
            print("Ranging is unavailable")
            completion([], BeaconScannerError.rangingUnavailable)
            return
        }

        // Assign the completion handler
        completionHandler = completion

        // Create a constraint based on the presence of major and minor values
        if let major = major, let minor = minor {
            beaconIdentityConstraint = CLBeaconIdentityConstraint(
                uuid: uuidToScan,
                major: major,
                minor: minor
            )
            print("Starting beacon scan for UUID: \(uuidToScan), Major: \(major), Minor: \(minor)")
        } else {
            beaconIdentityConstraint = CLBeaconIdentityConstraint(uuid: uuidToScan)
            print("Starting beacon scan for UUID: \(uuidToScan)")
        }

        // Save the start timestamp
        scanStartTimestampMillis = Date.currentMillis()

        // Start scanning for beacons
        locationManager.startRangingBeacons(satisfying: beaconIdentityConstraint!)

        // Set up the timeout timer to stop scanning after a timeout
        setupTimeoutTimer()
    }

    func setupTimeoutTimer() {
        // Ensure previous timer is cancelled
        noBeaconsFoundTimeoutTimer?.cancel()

        // Create a new timer
        let timer = DispatchSource.makeTimerSource(queue: beaconScanningQueue)
        timer.schedule(deadline: .now() + self.scanTimeoutSeconds)
        timer.setEventHandler { [weak self] in
            print("Stopping beacon scan due to timeout \(Date.currentMillis())")
            self?.stopScanningAndReportResults(error: nil)
        }
        timer.resume()
        noBeaconsFoundTimeoutTimer = timer
    }

    func processRangedBeacons(rangedBeacons: [CLBeacon]) {
        let currentTimestampMillis = Date.currentMillis()

        for beacon in rangedBeacons {
            if let index = foundBeacons.firstIndex(where: { $0.beacon.uuid == beacon.uuid && $0.beacon.major == beacon.major && $0.beacon.minor == beacon.minor }) {
                // Update existing beacon with new timestamp
                foundBeacons[index] = TimestampedBeacon(
                    beacon: beacon,
                    timestamp: currentTimestampMillis
                )
            } else {
                // Add new beacon
                let newBeacon = TimestampedBeacon(beacon: beacon, timestamp: currentTimestampMillis)
                foundBeacons.append(newBeacon)
            }
        }

        // Sort beacons by proximity for consistent ordering
        foundBeacons.sort {
            $0.beacon.proximity.rawValue < $1.beacon.proximity.rawValue
        }
    }

    func stopScanningAndReportResults(error: Error?) {
        if let error = error {
            print("Beacon scanning failed with error: \(error)")
            completionHandler?([], error)
            resetState()
        }

        guard let beaconIdentityConstraint = beaconIdentityConstraint else {
            print("Error: Beacon identity constraint is nil, cannot stop ranging beacons")
            resetState()
            return
        }

        locationManager.stopRangingBeacons(
            satisfying: beaconIdentityConstraint
        )

        let beaconsToReport = foundBeacons.map {
            $0.toBeacon()
        }

        print("Found \(beaconsToReport.count) beacons, notifying via completion handler")

        completionHandler?(beaconsToReport, error)

        resetState()
    }

    func resetState() {
        print("Resetting state")

        beaconIdentityConstraint = nil
        noBeaconsFoundTimeoutTimer?.cancel()
        completionHandler = nil
        noBeaconsFoundTimeoutTimer = nil
        foundBeacons.removeAll()
        scanStartTimestampMillis = 0
    }
}
