// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LivingUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "LivingUI", targets: ["LivingUI"]),
    ],
    targets: [
        .target(
            name: "LivingUI",
            path: "Sources/LivingUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "LivingUITests",
            dependencies: ["LivingUI"],
            path: "Tests/LivingUITests"
        ),
    ]
)
