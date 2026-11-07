// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ForknoteKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "ForknoteCore", targets: ["ForknoteCore"]),
        .library(name: "ForknoteStore", targets: ["ForknoteStore"]),
        .library(name: "ForknoteIntents", targets: ["ForknoteIntents"]),
    ],
    targets: [
        .target(name: "ForknoteCore"),
        .target(name: "ForknoteStore", dependencies: ["ForknoteCore"]),
        .target(name: "ForknoteIntents", dependencies: ["ForknoteCore"]),
        .testTarget(name: "ForknoteCoreTests", dependencies: ["ForknoteCore"]),
    ]
)
