// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Domo",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "Domo", targets: ["Domo"])],
  dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
  ],
  targets: [
    .executableTarget(
      name: "Domo",
      dependencies: [.product(name: "Sparkle", package: "Sparkle")],
      linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
    ),
    .testTarget(
      name: "DomoTests",
      dependencies: ["Domo"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
