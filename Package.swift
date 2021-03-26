// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IconBadger",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "iconBadger", targets: ["IconBadger"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "IconBadger",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .testTarget(
            name: "IconBadgerTests",
            dependencies: ["IconBadger"]),
    ]
)
