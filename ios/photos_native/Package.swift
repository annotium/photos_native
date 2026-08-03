// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "photos_native",
    platforms: [.iOS("13.0")],
    products: [
        .library(name: "photos-native", targets: ["photos_native"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "photos_native",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            cSettings: [
                .headerSearchPath("include/photos_native")
            ]
        )
    ]
)
