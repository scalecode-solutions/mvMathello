// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "mvMathello",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "mvMathelloKit", targets: ["mvMathelloKit"]),
        .library(name: "mvMathelloUI", targets: ["mvMathelloUI"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/scalecode-solutions/scalecode-metal-plugin.git",
            from: "1.0.1"
        ),
    ],
    targets: [
        .target(
            name: "mvMathelloKit",
            path: "Sources/mvMathelloKit"
        ),
        .target(
            name: "mvMathelloUI",
            dependencies: ["mvMathelloKit"],
            path: "Sources/mvMathelloUI",
            exclude: ["Shaders"],
            plugins: [
                .plugin(name: "MetalShadersPlugin", package: "scalecode-metal-plugin"),
            ]
        ),
        .testTarget(
            name: "mvMathelloKitTests",
            dependencies: ["mvMathelloKit"],
            path: "Tests/mvMathelloKitTests"
        ),
    ]
)
