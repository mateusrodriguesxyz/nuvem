// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Nuvem",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "Nuvem",
            targets: ["Nuvem"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "602.0.0"),
    ],
    targets: [
        .macro(
            name: "NuvemMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "Nuvem",
            dependencies: ["NuvemMacros"]
        ),
        .testTarget(
            name: "NuvemTests",
            dependencies: ["Nuvem"]
        ),
    ],
    swiftLanguageModes: [.version("5")]
)
