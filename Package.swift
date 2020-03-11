// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "BackgroundRealm",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_11),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "BackgroundRealm",
            type: .static,
            targets: ["BackgroundRealm"]),
    ],
    dependencies: [
         .package(url: "https://github.com/realm/realm-cocoa", from: "4.0.0"),
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
