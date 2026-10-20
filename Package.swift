// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "DONCOTextShieldCore",
    products: [.library(name: "TextShieldCore", targets: ["TextShieldCore"])],
    targets: [
        .target(name: "TextShieldCore", path: "Shared", exclude: ["PrivacyInfo.xcprivacy"]),
        .testTarget(name: "TextShieldCoreTests", dependencies: ["TextShieldCore"], path: "Tests")
    ]
)
