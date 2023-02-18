// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BitcoinCore",
    platforms: [
        .iOS(.v13),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "BitcoinCore",
            targets: ["BitcoinCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Brightify/Cuckoo.git", .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Quick/Nimble.git", from: "10.0.0"),
        .package(url: "https://github.com/Quick/Quick.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.1")),

        .package(url: "https://github.com/BoRoZzz/Checkpoints.git", .branch("master")),
        .package(url: "https://github.com/BoRoZzz/HdWalletKit.git", .branch("main")),
        .package(url: "https://github.com/BoRoZzz/HsCryptoKit.git", .branch("main")),
        .package(url: "https://github.com/BoRoZzz/HsExtensions.git", .branch("main")),
        .package(url: "https://github.com/BoRoZzz/HsToolKit.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "BitcoinCore",
            dependencies: [
                "BigInt", "RxSwift",
                "Checkpoints",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "HdWalletKit", package: "HdWalletKit"),
                .product(name: "HsCryptoKit", package: "HsCryptoKit"),
                .product(name: "HsExtensions", package: "HsExtensions"),
                .product(name: "HsToolKit", package: "HsToolKit"),
            ]
        ),
        .testTarget(
            name: "BitcoinCoreTests",
            dependencies: [
                "BitcoinCore",
                "Cuckoo",
                "Nimble",
                "Quick",
                .product(name: "RxBlocking", package: "RxSwift"),
            ]
        )
    ]
)
