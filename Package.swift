// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWSimpleZipDirectoryReader",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WWSimpleZipDirectoryReader", targets: ["WWSimpleZipDirectoryReader"]),
    ],
    targets: [
        .target(name: "WWSimpleZipDirectoryReader", resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
