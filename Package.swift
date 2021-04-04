// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IconBadger",
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
