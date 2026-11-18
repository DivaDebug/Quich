// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Quich",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Quich",
            path: "Sources/Quich"
        )
    ]
)
