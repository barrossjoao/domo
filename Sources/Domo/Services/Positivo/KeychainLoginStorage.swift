import Foundation
import Security

struct KeychainLoginStorage: LoginStorage {
  private let service: String
  private var enabledKey: String { service + ".rememberLogin" }

  // Keep this storage identifier stable to reuse existing logins and preferences.
  init(service: String = "br.automatizehouse.mac.positivo.login") {
    self.service = service
  }
  private var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: "saved-login",
    ]
  }

  func load() throws -> SavedLogin? {
    guard UserDefaults.standard.object(forKey: enabledKey) as? Bool != false else { return nil }
    var request = query
    request[kSecReturnData as String] = true
    request[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    let status = SecItemCopyMatching(request as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw KeychainError(status: status) }
    guard let data = result as? Data,
      let login = try? JSONDecoder().decode(SavedLogin.self, from: data),
      !login.email.isEmpty, !login.password.isEmpty,
      !login.deviceID.isEmpty, !login.sessionID.isEmpty
    else { throw KeychainError(status: errSecDecode) }
    return login
  }

  func save(_ login: SavedLogin) throws {
    let attributes: [String: Any] = [
      kSecValueData as String: try JSONEncoder().encode(login),
      kSecAttrLabel as String: "Domo — Positivo Casa Inteligente",
    ]
    var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      let item = query.merging(attributes) { _, new in new }
      status = SecItemAdd(item as CFDictionary, nil)
    }
    guard status == errSecSuccess else {
      UserDefaults.standard.set(false, forKey: enabledKey)
      throw KeychainError(status: status)
    }
    UserDefaults.standard.set(true, forKey: enabledKey)
  }

  func clear() throws {
    // A denied deletion must never restore the account after an explicit logout.
    UserDefaults.standard.set(false, forKey: enabledKey)
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError(status: status)
    }
  }

  private struct KeychainError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? {
      "Não foi possível acessar o login salvo no Chaves do macOS (\(status))."
    }
  }
}
