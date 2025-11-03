// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Aivora",
    platforms: [
        .iOS(.v13), .macOS(.v12), .tvOS(.v13), .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Aivora",
            targets: ["Aivora"]
        ),
    ],
    targets: [
        .target(
            name: "Aivora",
            path: "Sources/Aivora"
        ),
        .testTarget(
            name: "AivoraTests",
            dependencies: ["Aivora"],
            path: "Tests/AivoraTests"
        ),
    ]
)
