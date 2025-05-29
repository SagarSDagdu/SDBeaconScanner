//
//  SDBeaconScanner.swift
//
//
//  Created by Sagar Dagdu on 18/08/24.
//

import CoreLocation

/// Completion handler for the beacon scanning operation.
public typealias BeaconScanningCompletion = (Result<[Beacon], BeaconScannerError>) -> Void

/// Errors that can be reported by the beacon scanner
public enum BeaconScannerError: Error {
    /// The UUID provided is invalid
    case invalidUUID

    /// Ranging is unavailable on the device
    case rangingUnavailable

    /// A generic error with an associated `NSError` object. This error will be reported when the location manager notifies and error through the `didFailRangingFor` delegate method
    case rangingFailed(NSError)
}

/**
 A class that handles scanning for Bluetooth beacons using CoreLocation's beacon ranging API.

 The class allows you to start scanning for beacons based on their UUID, and optionally major and minor values. It utilizes CoreLocation's `CLLocationManager` for beacon scanning and provides a timeout mechanism to ensure that scanning doesn't run indefinitely.
 After a set time (default: 15 seconds) or once beacons are found, the scan automatically stops, and the results are reported to the caller via the provided completion handler.

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

    /// The location manager used for ranging beacons
    private let locationManager: CLLocationManager

    /// The shared singleton instance of the beacon scanner
    public static let shared = SDBeaconScanner()
    
    /// The timestamp (in milliseconds since epoch) when new beacons were last discovered during the current scan.
    /// This is used in conjunction with `noNewBeaconsTimeoutSeconds` to determine when to stop scanning
    /// if no new beacons have been found for the specified timeout duration.
    /// The value is initialized when a scan starts and updated whenever new beacons are discovered.
    private var lastNewBeaconFoundTimestampMillis: Int64 = 0

    /// The timeout duration (in seconds) for the scan when no new beacons are found. Default is 5 seconds.
    /// This timeout is used to stop the scan if no new beacons are found since the last ranging event.
    private var noNewBeaconsTimeoutSeconds: TimeInterval = 5.0

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
     - Parameter timeout: The timeout duration (in seconds) for the scan. If no beacons are found within this time, the scan will stop and an empty array will be returned through the completion handler. If you do not pass a value, the default timeout duration is 15 seconds.
     - Parameter noNewBeaconsTimeoutSeconds: The timeout duration (in seconds) to stop the scan if no new beacons are found since the last newly found beacon. Default is 5 seconds. If the set of beacons does not change within this time, the scan will stop and the results will be reported.
     - Parameter completion: A closure that gets called once the scan completes, either due to timeout or because beacons were found. The closure receives a `Result` which can be an array of ``Beacon`` objects in case beacons are found or the scan times out,  or a  ``BeaconScannerError`` if an error occurs

     ### Behavior
     - The scan will start for beacons matching the provided UUID.
     - The scan will automatically stop after `timeout` seconds if no beacons are found.
     - If any beacons are found before the timeout, the scan will stop and report the results after `noNewBeaconsTimeoutSeconds` seconds elapse without finding new beacons.
     - If a scan is already in progress, it will stop and a new one will begin.

     - Note: Ensure that location permissions are correctly configured for the app, including background location permission.
     */
    public func getNearbyBeacons(
        uuid: String,
        timeout: TimeInterval = 15.0,
        noNewBeaconsTimeoutSeconds: TimeInterval = 5.0,
        completion: @escaping BeaconScanningCompletion
    ) {
        
        // Call the private method with only UUID
        startBeaconScan(uuid: uuid,
                        major: nil,
                        minor: nil,
                        timeout: timeout,
                        noNewBeaconsTimeoutSeconds: noNewBeaconsTimeoutSeconds,
                        completion: completion)
    }

    /**
     Starts scanning for beacons with a specified UUID, major, and minor values.

     - Parameter uuid: The UUID string of the beacons to scan for.
     - Parameter major: The major value of the beacons to scan for.
     - Parameter minor: The minor value of the beacons to scan for.
     - Parameter timeout: The timeout duration (in seconds) for the scan. If no beacons are found within this time, the scan will stop and an empty array will be returned through the completion handler. If you do not pass a value, the default timeout duration is 15 seconds.
     - Parameter noNewBeaconsTimeoutSeconds: The timeout duration (in seconds) to stop the scan if no new beacons are found since the last newly found beacon. Default is 5 seconds. If the set of beacons does not change within this time, the scan will stop and the results will be reported.
     - Parameter completion: A closure that gets called once the scan completes, either due to timeout or because beacons were found. The closure receives a `Result` which can be an array of ``Beacon`` objects in case beacons are found or the scan times out,  or a  ``BeaconScannerError`` if an error occurs

     ### Behavior
     - The scan will start for beacons matching the provided UUID, major, and minor values.
     - The scan will automatically stop after `timeout` seconds if no beacons are found.
     - If any beacons are found before the timeout, the scan will stop and report the results after `noNewBeaconsTimeoutSeconds` seconds elapse without finding new beacons.
     - If a scan is already in progress, it will stop and a new one will begin.

     - Note: Ensure that location permissions are correctly configured for the app, including background location permission.
     */
    public func getNearbyBeacons(
        uuid: String,
        major: UInt16,
        minor: UInt16,
        timeout: TimeInterval = 15.0,
        noNewBeaconsTimeoutSeconds: TimeInterval = 5.0,
        completion: @escaping BeaconScanningCompletion
    ) {
        // Call the private method with UUID, major, and minor values
        startBeaconScan(uuid: uuid,
                        major: major,
                        minor: minor,
                        timeout: timeout,
                        noNewBeaconsTimeoutSeconds: noNewBeaconsTimeoutSeconds,
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

            let newBeaconFound = self.processRangedBeacons(rangedBeacons: beacons)
            
            // Only check noNewBeaconsTimeout if we have found beacons before
            if self.foundBeacons.count > 0 {
                let isNoNewBeaconsTimeUp = Date.isTimeAhead(
                    of: self.lastNewBeaconFoundTimestampMillis,
                    by: noNewBeaconsTimeoutSeconds
                )
                
                if isNoNewBeaconsTimeUp && !newBeaconFound {
                    consoleLog("Stopping beacon scan - no new beacons found for \(noNewBeaconsTimeoutSeconds) seconds")
                    self.stopScanningAndReportResults(error: nil)
                    return
                }
            }
            
            if newBeaconFound {
                consoleLog("New beacon found, continuing scan...")
            } else {
                consoleLog("Beacon scan still in progress...")
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
        timeout: TimeInterval,
        noNewBeaconsTimeoutSeconds: TimeInterval,
        completion: @escaping BeaconScanningCompletion
    ) {
        if scanStartTimestampMillis > 0 {
            consoleLog("Beacon scan already in progress, stopping it")
            stopScanningAndReportResults(error: nil)
        }

        guard let uuidToScan = UUID(uuidString: uuid) else {
            consoleLog("Invalid UUID \(uuid)")
            completion(.failure(.invalidUUID))
            return
        }

        guard CLLocationManager.isRangingAvailable() else {
            consoleLog("Ranging is unavailable")
            completion(.failure(.rangingUnavailable))
            return
        }

        // Assign the completion handler
        completionHandler = completion
        
        // Set the noNewBeaconsTimeoutSeconds
        self.noNewBeaconsTimeoutSeconds = noNewBeaconsTimeoutSeconds

        // Create a constraint based on the presence of major and minor values
        if let major = major, let minor = minor {
            beaconIdentityConstraint = CLBeaconIdentityConstraint(
                uuid: uuidToScan,
                major: major,
                minor: minor
            )
            consoleLog("Starting beacon scan for UUID: \(uuidToScan), Major: \(major), Minor: \(minor)")
        } else {
            beaconIdentityConstraint = CLBeaconIdentityConstraint(uuid: uuidToScan)
            consoleLog("Starting beacon scan for UUID: \(uuidToScan)")
        }

        // Save the start timestamp
        scanStartTimestampMillis = Date.currentMillis()

        // Start scanning for beacons
        locationManager.startRangingBeacons(satisfying: beaconIdentityConstraint!)

        // Set up the timeout timer to stop scanning after a timeout
        setupTimeoutTimer(timeout: timeout)
    }

    func setupTimeoutTimer(timeout: TimeInterval) {
        // Ensure previous timer is cancelled
        noBeaconsFoundTimeoutTimer?.cancel()

        // Create a new timer
        let timer = DispatchSource.makeTimerSource(queue: beaconScanningQueue)
        timer.schedule(deadline: .now() + timeout)
        timer.setEventHandler { [weak self] in
            consoleLog("Stopping beacon scan due to timeout \(Date.currentMillis())")
            self?.stopScanningAndReportResults(error: nil)
        }
        timer.resume()
        noBeaconsFoundTimeoutTimer = timer
    }

    func processRangedBeacons(rangedBeacons: [CLBeacon]) -> Bool {
        let currentTimestampMillis = Date.currentMillis()

        var newBeaconFound = false
        for beacon in rangedBeacons {
            if let index = foundBeacons.firstIndex(where: { $0.beacon.uuid == beacon.uuid && $0.beacon.major == beacon.major && $0.beacon.minor == beacon.minor }) {
                // Update existing beacon with new timestamp
                foundBeacons[index] = TimestampedBeacon(
                    beacon: beacon,
                    timestamp: currentTimestampMillis
                )

                consoleLog("Updated existing beacon with UUID: \(beacon.uuid.uuidString), Major: \(beacon.major.intValue), Minor: \(beacon.minor.intValue)")
            } else {
                // Add new beacon
                let newBeacon = TimestampedBeacon(beacon: beacon, timestamp: currentTimestampMillis)
                foundBeacons.append(newBeacon)
                newBeaconFound = true
                consoleLog("Found new beacon with UUID: \(beacon.uuid.uuidString), Major: \(beacon.major.intValue), Minor: \(beacon.minor.intValue)")
            }
        }
        
        // Update timestamp whenever ANY new beacon is found
        if newBeaconFound {
            lastNewBeaconFoundTimestampMillis = currentTimestampMillis
        }

        // Sort beacons by proximity for consistent ordering
        foundBeacons.sort {
            $0.beacon.proximity.rawValue < $1.beacon.proximity.rawValue
        }

        return newBeaconFound
    }

    func stopScanningAndReportResults(error: Error?) {
        if let error = error {
            consoleLog("Beacon scanning failed with error: \(error)")
            completionHandler?(.failure(.rangingFailed(error as NSError)))
            resetState()
        }

        guard let beaconIdentityConstraint = beaconIdentityConstraint else {
            consoleLog("Error: Beacon identity constraint is nil, cannot stop ranging beacons")
            resetState()
            return
        }

        locationManager.stopRangingBeacons(
            satisfying: beaconIdentityConstraint
        )

        let beaconsToReport = foundBeacons.map {
            $0.toBeacon()
        }

        consoleLog("Found \(beaconsToReport.count) beacons, notifying via completion handler")

        completionHandler?(.success(beaconsToReport))

        resetState()
    }

    func resetState() {
        consoleLog("Resetting state")

        beaconIdentityConstraint = nil
        noBeaconsFoundTimeoutTimer?.cancel()
        completionHandler = nil
        noBeaconsFoundTimeoutTimer = nil
        foundBeacons.removeAll()
        scanStartTimestampMillis = 0
        noNewBeaconsTimeoutSeconds = 5.0
        lastNewBeaconFoundTimestampMillis = 0
    }
}

func consoleLog(_ items: Any...) {
    #if DEBUG
        for item in items {
            Swift.print("\(item)")
        }
    #endif
}
