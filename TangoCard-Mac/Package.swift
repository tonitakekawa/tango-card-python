// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TangoCard",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "TangoCard",
            path: "Sources/TangoCard"
        )
    ]
)
