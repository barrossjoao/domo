import Foundation

enum PositivoError: LocalizedError {
  case invalidResponse, invalidKey, noSession
  case cloud(String)
  var isSessionExpired: Bool {
    if case .cloud(let code) = self { return code.uppercased().contains("SESSION") }
    return false
  }
  var requiresLogin: Bool {
    if case .noSession = self { return true }
    if case .cloud(let code) = self {
      let code = code.uppercased()
      return isSessionExpired || code.contains("PASSWD") || code.contains("PASSWORD")
        || code.contains("USER_NOT_EXIST")
    }
    return false
  }
  var errorDescription: String? {
    switch self {
    case .invalidResponse: return "A nuvem retornou um formato inesperado."
    case .invalidKey: return "Não foi possível preparar o login seguro."
    case .noSession: return "Conecte sua conta Positivo para continuar."
    case .cloud(let code):
      if code.contains("PASSWD") || code.contains("PASSWORD") || code.contains("USER_NOT_EXIST") {
        return "E-mail ou senha recusados. Confira a conta usada no aplicativo Positivo."
      }
      if isSessionExpired {
        return "Não foi possível renovar a sessão. Entre novamente na sua conta."
      }
      return "A nuvem recusou o pedido (\(code)). Tente novamente."
    }
  }
}
