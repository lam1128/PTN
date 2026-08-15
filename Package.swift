// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PTNHypercubeWidget",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PTNHypercubeWidget", targets: ["PTNHypercubeWidget"])
    ],
    targets: [
        .executableTarget(
            name: "PTNHypercubeWidget",
            path: "PTNHypercubeWidget"
        )
    ]
)
