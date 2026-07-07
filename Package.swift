// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FeedCacheLab",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "FeedCacheLabCore", targets: ["FeedCacheLabCore"]),
        .library(name: "FeedCacheLabUI", targets: ["FeedCacheLabUI"]),
    ],
    targets: [
        .target(
            name: "FeedCacheLabCore"
        ),
        .target(
            name: "FeedCacheLabUI",
            dependencies: ["FeedCacheLabCore"]
        ),
        .testTarget(
            name: "FeedCacheLabCoreTests",
            dependencies: ["FeedCacheLabCore"]
        ),
    ]
)
