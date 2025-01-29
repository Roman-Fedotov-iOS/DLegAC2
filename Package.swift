// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DLegAC2",
    platforms: [
        .iOS(.v16),
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DLegAC2",
            targets: ["DLegAC2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apphud/ApphudSDK.git", exact: "3.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DLegAC2",
            dependencies: [
                "ApphudSDK"
            ]),
        .testTarget(
            name: "DLegAC2Tests",
            dependencies: ["DLegAC2"]
        ),
    ]
)
