# 🛰️ SDBeaconScanner

SDBeaconScanner is a powerful Swift-based library for scanning Bluetooth beacons using CoreLocation’s beacon ranging API. It allows you to easily detect nearby beacons by providing their UUIDs, major, and minor values, and automatically manages scanning duration with a timeout mechanism.

## 🚀 Features

- Scan for beacons by UUID.
- Optionally scan with major and minor values.
- Automatically handles scanning timeout (default: 30 seconds).
- Singleton pattern ensures only one scan at a time.
- Easy-to-use public API.

## 📋 Requirements

- iOS 13.0+
- Swift 5.0+
- CoreLocation framework
- Bluetooth enabled on the device

## 🛠 Installation

### Swift Package Manager

Add the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/SagarSDagdu/SDBeaconScanner.git", from: "1.0.0")
