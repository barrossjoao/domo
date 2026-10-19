import Foundation

@testable import Domo

final class MemoryLoginStorage: LoginStorage {
  var value: SavedLogin?
  var enabled = true
  var saveError: Error?
  var clearError: Error?

  func load() throws -> SavedLogin? { enabled ? value : nil }
  func save(_ login: SavedLogin) throws {
    if let saveError {
      enabled = false
      throw saveError
    }
    value = login
    enabled = true
  }
  func clear() throws {
    enabled = false
    if let clearError { throw clearError }
    value = nil
  }
}
