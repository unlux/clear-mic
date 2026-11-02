// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ClearMic",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "ClearMic", targets: ["ClearMic"]),
        .executable(name: "ClearMicBench", targets: ["ClearMicBench"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Desert-Ant-Labs/desert-ant-core.git", exact: "4.1.0"),
    ],
    targets: [
        .target(name: "CAudioFIFO", publicHeadersPath: "include"),
        .target(name: "ClearMicCore", dependencies: ["CAudioFIFO"]),
        .target(name: "ClearMicModel", dependencies: ["ClearMicCore", .product(name: "Clear", package: "desert-ant-core"), .product(name: "DesertAnt", package: "desert-ant-core")]),
        .executableTarget(name: "ClearMic", dependencies: ["ClearMicCore", "ClearMicModel"]),
        .executableTarget(name: "ClearMicBench", dependencies: ["ClearMicCore", "ClearMicModel", .product(name: "Clear", package: "desert-ant-core")]),
        .testTarget(name: "ClearMicCoreTests", dependencies: ["ClearMicCore"]),
        .testTarget(name: "ClearMicAudioTests", dependencies: ["ClearMic"]),
    ],
    swiftLanguageModes: [.v5]
)
