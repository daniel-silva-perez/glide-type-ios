// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GlideTypeAI",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "GlideCore", targets: ["GlideCore"])
    ],
    targets: [
        .target(name: "GlideCore"),
        .testTarget(name: "GlideCoreTests", dependencies: ["GlideCore"])
    ]
)
