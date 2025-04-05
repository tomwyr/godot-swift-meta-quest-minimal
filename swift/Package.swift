// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "GodotSwiftXr",
  platforms: [.macOS("14")],
  products: [
    .library(name: "GodotSwiftXr", type: .dynamic, targets: ["GodotSwiftXr"])
  ],
  dependencies: [
    .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
  ],
  targets: [
    .target(
      name: "GodotSwiftXr",
      dependencies: ["SwiftGodot"],
      swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
    )
  ]
)
