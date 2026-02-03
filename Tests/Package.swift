// swift-tools-version: 6.2
import PackageDescription

let package: Package = .init(
    name: "swift-wasm-test",
    products: [
        .executable( name: "HelloBarbie", targets: ["HelloBarbie"]),
    ],
    targets: [
        .executableTarget(name: "HelloBarbie"),
    ]
)
