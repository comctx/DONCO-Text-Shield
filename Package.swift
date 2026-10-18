// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DONCOTextShieldCore",
    products: [.library(name: "TextShieldCore", targets: ["TextShieldCore"])],
    targets: [
        .target(name: "TextShieldCore", path: "Shared"),
        .testTarget(name: "TextShieldCoreTests", dependencies: ["TextShieldCore"], path: "Tests")
    ]
)
