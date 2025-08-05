// swift-tools-version:5.11
import PackageDescription

let package = Package(
    name: "macos-snipper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "macos-snipper", targets: ["macos-snipper"])
    ],
    dependencies: [
        // no external dependencies
    ],
    targets: [
        .executableTarget(
            name: "macos-snipper",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("ScreenCaptureKit")
            ]
        ),
    ]
)
