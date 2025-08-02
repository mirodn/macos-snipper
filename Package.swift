// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macos-snipper",
    platforms: [
        .macOS(.v14) // macOS Sonoma and newer (works on Sequoia)
    ],
    targets: [
        .executableTarget(
            name: "macos-snipper",
            path: "Sources"
        )
    ]
)
