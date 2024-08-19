// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "SDBeaconScanner",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SDBeaconScanner",
            targets: ["SDBeaconScanner"]
        ),
    ],
    targets: [
        .target(
            name: "SDBeaconScanner"),
        .testTarget(
            name: "SDBeaconScannerTests",
            dependencies: ["SDBeaconScanner"]
        ),
    ]
)
