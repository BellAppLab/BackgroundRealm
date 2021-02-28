// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "BackgroundRealm",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "BackgroundRealm",
            type: .static,
            targets: ["BackgroundRealm"]),
    ],
    dependencies: [
         .package(url: "https://github.com/realm/realm-cocoa.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "BackgroundRealm",
            dependencies: ["RealmSwift"]),
        .testTarget(
            name: "Tests",
            dependencies: ["BackgroundRealm"]),
    ],
    swiftLanguageVersions: [.v5]
)
