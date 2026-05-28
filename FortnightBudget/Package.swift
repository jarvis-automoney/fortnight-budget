// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FortnightBudget",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FortnightBudget", targets: ["FortnightBudget"])
    ],
    targets: [
        .executableTarget(
            name: "FortnightBudget",
            path: "Sources"
        )
    ]
)
