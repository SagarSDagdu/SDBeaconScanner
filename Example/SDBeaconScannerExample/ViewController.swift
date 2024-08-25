//
//  ViewController.swift
//  SDBeaconScannerExample
//
//  Created by Sagar Dagdu on 17/08/24.
//

import CoreLocation
import SDBeaconScanner
import UIKit

class ViewController: UIViewController {
    let permissionManager = PermissionManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        permissionManager.requestLocationPermissions()
    }

    @IBAction func scanBeaconsTapped(_: Any) {
        SDBeaconScanner.shared.getNearbyBeacons(uuid: "9B1A407A-57C4-4565-A6C8-7C9D4F2BC65A") { scanResult in
            switch scanResult {
            case let .success(beacons):
                print("Got \(beacons.count) beacons")
            case let .failure(scanError):
                print("Error: \(scanError)")
            }
        }
    }
}

class PermissionManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestLocationPermissions() {
        // Check the current authorization status
        let currentStatus = CLLocationManager.authorizationStatus()

        switch currentStatus {
        case .notDetermined:
            // Request "When In Use" location permissions first
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // If already authorized for "When In Use", ask for "Always" authorization
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            // Handle the case where the user has denied location services
            print("Location services were denied or restricted.")
        case .authorizedAlways:
            // Already authorized for "Always"
            print("Location services are already authorized for Always.")
        @unknown default:
            break
        }
    }

    // Delegate method to handle changes in authorization status
    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            // When "When In Use" is granted, now request "Always"
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Location services are authorized for Always.")
        case .denied, .restricted:
            print("Location services denied/restricted.")
        default:
            break
        }
    }
}
