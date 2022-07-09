// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Project",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(
            name: "Project",
            targets: ["Project"]),
        .library(
            name: "Node",
            targets: ["Node"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "0.9.0")),
        .package(name: "Common", path: "./Common")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Project",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .byNameItem(name: "Common", condition: nil),
                .target(name: "Node")
            ]),
        .target(
            name: "Node",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .byNameItem(name: "Common", condition: nil)
            ]),
        .testTarget(
            name: "ProjectTests",
            dependencies: ["Project"]),
    ]
)
