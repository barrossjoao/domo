import Foundation
import XCTest

enum TestFixtures {
  static func data(_ name: String) throws -> Data {
    let url = try XCTUnwrap(
      Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
  }

  static func object(_ name: String) throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: data(name)) as? [String: Any])
  }

  static func tvCommands() throws -> [String] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: data("tv-commands")) as? [String])
  }
}
