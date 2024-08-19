# 🛰️ SDBeaconScanner


SDBeaconScanner is a Swift library for scanning Bluetooth beacons using CoreLocation's beacon ranging API. It simplifies scanning for beacons by providing an easy-to-use API with support for UUID, major, and minor identifiers. Additionally, the scanner allows you to specify a timeout for the scan and handles beacon detection results through completion handlers.

## Table of Contents

1. [Features](#features)
2. [Requirements](#requirements)
3. [Installation](#installation)
    - [Swift Package Manager](#swift-package-manager)
    - [Manually](#manually)
4. [Permissions](#permissions)
5. [Project Configuration](#project-configuration)
6. [Usage](#usage)
    - [Importing the Library](#1-importing-the-library)
    - [Initializing the Scanner](#2-initializing-the-scanner)
    - [Scanning for Beacons](#3-scanning-for-beacons)
    - [Customizing the Timeout](#4-customizing-the-timeout)
    - [Handling Results and Errors](#5-handling-results-and-errors)
7. [Example](#example)
8. [License](#license)

## Features

- **Beacon Scanning:** Scan for nearby Bluetooth beacons by UUID, with optional major and minor values.
- **Customizable Timeout:** Specify a custom timeout for the scan to avoid indefinite scanning.
- **Completion Handlers:** Results are returned via completion handlers, making it easy to integrate with your existing app logic.
- **Error Handling:** Provides detailed errors, including invalid UUID, unavailable ranging, and generic errors via NSError.

## Requirements

- iOS 13.0+
- Swift 5.0+
- CoreLocation framework

## Installation

### Swift Package Manager

Add SDBeaconScanner to your project using Swift Package Manager:

1. Open your Xcode project.
2. Select **File** > **Add Packages**.
3. Paste the repository URL in the search field: `https://github.com/SagarSDagdu/SDBeaconScanner.git`
4. Choose the package and add it to your project.

### Manually

You can manually copy the files under `Sources/SDBeaconScanner` to your project.

## Permissions
Ensure that your app includes the necessary permissions in `Info.plist` to use location services:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to scan for beacons.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to scan for beacons even when the app is in the background.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to scan for beacons.</string>
```

## Project Configuration

### Background Location Updates
To enable scanning for beacons while your app is in the background, ensure that your app has the correct background modes enabled in Info.plist:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>
```

## Usage

### 1. Importing the Library

```swift
import SDBeaconScanner
```

### 2. Initializing the Scanner

SDBeaconScanner is designed as a singleton, so you can directly access the shared instance:

```swift
let beaconScanner = SDBeaconScanner.shared
```

### 3. Scanning for Beacons

To start scanning for beacons, you can use either of the following methods depending on whether you want to scan by UUID only or include major and minor values.

#### Scan by UUID

```swift
beaconScanner.getNearbyBeacons(uuid: "your-uuid") { beacons, error in
    if let error = error {
        // Handle error
        print("Error scanning beacons: \(error)")
    } else {
        // Handle found beacons
        print("Found beacons: \(beacons)")
    }
}
```

#### Scan by UUID, Major, and Minor

```swift
beaconScanner.getNearbyBeacons(uuid: "your-uuid", major: 123, minor: 456) { beacons, error in
    if let error = error {
        // Handle error
        print("Error scanning beacons: \(error)")
    } else {
        // Handle found beacons
        print("Found beacons: \(beacons)")
    }
}
```

### 4. Customizing the Timeout

You can specify a custom timeout duration (in seconds) for the scan. The scan will automatically stop once the timeout is reached or once beacons are found.

```swift
beaconScanner.getNearbyBeacons(uuid: "your-uuid", timeout: 10.0) { beacons, error in
    if let error = error {
        print("Error scanning beacons: \(error)")
    } else {
        print("Found beacons: \(beacons)")
    }
}
```

### 5. Handling Results and Errors

The `BeaconScanningCompletion` typealias is used for handling the results of a scan. You can check for errors and handle the returned beacons in the completion handler.

### Error Handling

SDBeaconScanner provides detailed error handling through the `BeaconScannerError` enum. The following errors are reported:

- `invalidUUID`: Indicates that the provided UUID is not valid.
- `rangingUnavailable`: Indicates that the device does not support ranging.
- `rangingFailed(NSError)`: A generic error that reports an NSError object, typically triggered by internal location manager issues.

Example usage:

```swift
if let error = error as? BeaconScannerError {
    switch error {
    case .invalidUUID:
        print("The UUID provided is invalid.")
    case .rangingUnavailable:
        print("Ranging is unavailable on this device.")
    case .rangingFailed(let nsError):
        print("Ranging failed with error: \(nsError.localizedDescription)")
    }
}
```

## Example

You can find a simple example project in the [Example](/Example) directory. The example demonstrates how to scan for beacons using `SDBeaconScanner`.

## License

SDBeaconScanner is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
