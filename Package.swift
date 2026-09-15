// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RunMusicCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RunMusicCore", targets: ["RunMusicCore"]),
        .library(name: "RunMusicApplePlatform", targets: ["RunMusicApplePlatform"]),
        .library(name: "RunMusicAppUI", targets: ["RunMusicAppUI"]),
        .executable(name: "RunMusicDemo", targets: ["RunMusicDemo"])
    ],
    targets: [
        .target(name: "RunMusicCore"),
        .target(name: "RunMusicApplePlatform", dependencies: ["RunMusicCore"]),
        .target(name: "RunMusicAppUI", dependencies: ["RunMusicCore", "RunMusicApplePlatform"]),
        .executableTarget(name: "RunMusicDemo", dependencies: ["RunMusicCore"]),
        .testTarget(name: "RunMusicCoreTests", dependencies: ["RunMusicCore"])
    ]
)
