// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Domo",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "Domo", targets: ["Domo"])],
  targets: [
    .executableTarget(name: "Domo"),
    .testTarget(
      name: "DomoTests",
      dependencies: ["Domo"],
      resources: [.copy("Fixtures")]
    ),
  ]
)
