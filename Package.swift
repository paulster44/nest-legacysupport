// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LegacyNestControl",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "LegacyNestControl", targets: ["LegacyNestControl"])
    ],
    targets: [
        .target(
            name: "LegacyNestControl",
            path: "Sources/LegacyNestControl"
        ),
        .testTarget(
            name: "LegacyNestControlTests",
            dependencies: ["LegacyNestControl"],
            path: "Tests/LegacyNestControlTests"
        )
    ]
)
