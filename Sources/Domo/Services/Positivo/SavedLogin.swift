import Foundation

struct SavedLogin: Codable {
  let email: String
  let password: String
  let deviceID: String
  var sessionID: String
}

protocol LoginStorage {
  func load() throws -> SavedLogin?
  func save(_ login: SavedLogin) throws
  func clear() throws
}
