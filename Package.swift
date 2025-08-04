// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macos-snipper",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "macos-snipper",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AudioToolbox")
            ]
        )
    ]
)
