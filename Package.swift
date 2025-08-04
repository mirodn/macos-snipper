// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MacosSnipper",               // ← Swift module name, CamelCase, no hyphens
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "macos-snipper",      // ← your final bundle name (can have hyphens)
            targets: ["MacosSnipper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacosSnipper",       // ← must match package.name
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AudioToolbox")
            ]
        ),
        .testTarget(
            name: "MacosSnipperTests",  // ← test target name
            dependencies: ["MacosSnipper"],
            path: "Tests/MacosSnipperTests"
        )
    ]
)
