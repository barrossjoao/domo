import CryptoKit
import Foundation

final class PositivoClient {
  private let session: URLSession
  private var deviceID = String(
    MobileCrypto.hex(SHA256.hash(data: Data(UUID().uuidString.utf8))).prefix(40))
  private var sid: String?
  private let loginStorage: LoginStorage
  private var savedLogin: SavedLogin?
  private(set) var persistenceWarning: String?
  private(set) var hasSavedLogin = false

  init(session: URLSession? = nil, loginStorage: LoginStorage = KeychainLoginStorage()) {
    self.loginStorage = loginStorage
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 20
    config.timeoutIntervalForResource = 30
    self.session = session ?? URLSession(configuration: config)
  }
  static func form(_ fields: [String: String]) -> String {
    let allowed = CharacterSet(
      charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._*")
    func encode(_ value: String) -> String {
      value.addingPercentEncoding(withAllowedCharacters: allowed)!.replacingOccurrences(
        of: "%20", with: "+")
    }
    return fields.keys.sorted().map { encode($0) + "=" + encode(fields[$0]!) }.joined(
      separator: "&")
  }
  private func call(
    _ action: String, _ postData: [String: Any]? = nil, extra: [String: String] = [:],
    authenticated: Bool = true, canRefresh: Bool = true
  ) async throws -> Any {
    var body: String?
    if let postData = postData {
      body = String(
        data: try JSONSerialization.data(
          withJSONObject: postData, options: [.sortedKeys, .withoutEscapingSlashes]),
        encoding: .utf8)
    }
    var params: [String: String] = [
      "appVersion": "1.1.6", "appRnVersion": "5.14", "channel": "oem", "deviceId": String(deviceID),
      "platform": "Linux", "requestId": UUID().uuidString.lowercased(), "lang": "en", "a": action,
      "clientId": MobileCrypto.clientID, "osSystem": "9", "os": "Android",
      "timeZoneId": "America/Sao_Paulo",
      "ttid": "sdk_tuya@" + MobileCrypto.clientID, "et": "0.0.1",
      "v": action == "tuya.m.device.sub.list"
        ? "1.1" : action == "tuya.m.infrared.keydata.get" ? "2.0" : "1.0",
      "sdkVersion": "3.10.0", "time": String(Int(Date().timeIntervalSince1970)),
    ]
    if authenticated, let sid = sid { params["sid"] = sid }
    params.merge(extra) { _, new in new }
    params["sign"] = MobileCrypto.sign(params, body: body)
    var url = URLComponents(string: "https://a1.tuyaus.com/api.json")!
    url.percentEncodedQuery = Self.form(params)
    var request = URLRequest(url: url.url!)
    request.httpMethod = "POST"
    request.setValue("TY-UA=APP/Android/1.1.6/SDK/null", forHTTPHeaderField: "User-Agent")
    if let body = body {
      request.setValue(
        "application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
      request.httpBody = Data(Self.form(["postData": body]).utf8)
    }
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode),
      let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { throw PositivoError.invalidResponse }
    guard object["success"] as? Bool == true else {
      let error = PositivoError.cloud(object["errorCode"] as? String ?? "UNKNOWN")
      if authenticated, canRefresh, error.isSessionExpired, savedLogin != nil {
        try await renewSession()
        return try await call(
          action, postData, extra: extra, authenticated: true, canRefresh: false)
      }
      throw error
    }
    return object["result"] ?? NSNull()
  }
  static func string(_ value: Any?) -> String? {
    if let text = value as? String { return text }
    if let number = value as? NSNumber { return number.stringValue }
    return nil
  }
  private func dict(_ value: Any) throws -> [String: Any] {
    guard let result = value as? [String: Any] else { throw PositivoError.invalidResponse }
    return result
  }
  private func array(_ value: Any) throws -> [[String: Any]] {
    guard let result = value as? [[String: Any]] else { throw PositivoError.invalidResponse }
    return result
  }
  private func extras(_ value: Any?) throws -> [String: Any] {
    if value == nil { return [:] }
    if let dictionary = value as? [String: Any] { return dictionary }
    guard let text = value as? String, let data = text.data(using: .utf8),
      let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { throw PositivoError.invalidResponse }
    return object
  }
  func connect(email: String, password: String) async throws -> [HouseRemote] {
    let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let sessionID = try await authenticate(email: email, password: password)
    sid = sessionID
    savedLogin = SavedLogin(
      email: email, password: password, deviceID: deviceID, sessionID: sessionID)
    persistLogin()
    return try await discover()
  }

  func restoreConnection() async throws -> [HouseRemote]? {
    guard let login = try loginStorage.load() else {
      savedLogin = nil
      sid = nil
      hasSavedLogin = false
      return nil
    }
    hasSavedLogin = true
    savedLogin = login
    deviceID = login.deviceID
    sid = login.sessionID
    return try await discover()
  }

  private func authenticate(email: String, password: String) async throws -> String {
    guard !email.isEmpty, !password.isEmpty else { throw PositivoError.noSession }
    let token = try dict(
      await call(
        "tuya.m.user.email.token.create", ["countryCode": 55, "email": email], authenticated: false)
    )
    guard let modulus = Self.string(token["publicKey"]),
      let exponent = Self.string(token["exponent"]), let loginToken = token["token"]
    else { throw PositivoError.invalidResponse }
    let encrypted = try MobileCrypto.encryptedPassword(
      modulus: modulus, exponent: exponent, password: password)
    let result = try dict(
      await call(
        "tuya.m.user.email.password.login",
        [
          "countryCode": "55", "email": email, "ifencrypt": 1, "options": "{\"group\": 1}",
          "passwd": encrypted, "token": loginToken,
        ], authenticated: false))
    guard let sessionID = result["sid"] as? String, !sessionID.isEmpty else {
      throw PositivoError.invalidResponse
    }
    return sessionID
  }

  private func renewSession() async throws {
    guard var login = savedLogin else { throw PositivoError.noSession }
    let sessionID = try await authenticate(email: login.email, password: login.password)
    sid = sessionID
    login.sessionID = sessionID
    savedLogin = login
    persistLogin()
  }

  private func persistLogin() {
    guard let login = savedLogin else { return }
    do {
      try loginStorage.save(login)
      hasSavedLogin = true
      persistenceWarning = nil
    } catch {
      hasSavedLogin = false
      persistenceWarning =
        "Conectado, mas o macOS não permitiu salvar o acesso no Chaves. Na próxima abertura, tente conectar novamente."
    }
  }

  func disconnect() throws {
    defer {
      sid = nil
      savedLogin = nil
      hasSavedLogin = false
      persistenceWarning = nil
    }
    try loginStorage.clear()
  }
  private func discover() async throws -> [HouseRemote] {
    guard sid != nil else { throw PositivoError.noSession }
    let groups = try array(await call("tuya.m.location.list"))
    var remotes: [HouseRemote] = []
    for group in groups {
      guard let groupID = Self.string(group["groupId"] ?? group["gid"] ?? group["id"]) else {
        throw PositivoError.invalidResponse
      }
      let devices = try array(await call("tuya.m.my.group.device.list", extra: ["gid": groupID]))
      for device in devices {
        let name = device["name"] as? String ?? ""
        let match =
          name.range(
            of: "controle|universal|infra|\\bir\\b",
            options: [.regularExpression, .caseInsensitive]) != nil
        guard device["productId"] as? String == "lwpag3bu0faaowlj" || match else { continue }
        guard let gateway = device["devId"] as? String else { throw PositivoError.invalidResponse }
        let children = try array(await call("tuya.m.device.sub.list", ["meshId": gateway]))
        for child in children {
          guard let deviceID = child["devId"] as? String else {
            throw PositivoError.invalidResponse
          }
          let id = gateway + ":" + deviceID
          if !remotes.contains(where: { $0.id == id }) {
            remotes.append(
              HouseRemote(
                id: id, gateway: gateway, device: deviceID,
                name: child["name"] as? String ?? "Controle"))
          }
        }
      }
    }
    return remotes
  }
  func commands(for remote: HouseRemote) async throws -> [IRCommand] {
    guard sid != nil else { throw PositivoError.noSession }
    let record = try dict(
      await call(
        "tuya.m.infrared.record.get",
        ["devId": remote.device, "gwId": remote.device, "subDevId": remote.device, "vender": "3"]))
    let isLearned = Self.string(try extras(record["exts"])["study"]) == "1"
    if isLearned {
      let keys = try array(
        await call(
          "tuya.m.infrared.learn.get",
          [
            "devId": remote.gateway, "gwId": remote.gateway, "subDevId": remote.device,
            "vender": "3",
          ]))
      return try keys.map { key in
        guard let name = Self.string(key["keyName"] ?? key["name"]),
          let pulse = Self.string(key["compressPulse"])
        else { throw PositivoError.invalidResponse }
        let bytes = try MobileCrypto.numberBytes(
          pulse.lowercased().hasPrefix("0x") ? pulse : "0x" + pulse, trimHexPadding: false)
        return IRCommand(
          name: name, payload: ["1": "study_key", "3": "", "7": Data(bytes).base64EncodedString()])
      }
    }
    guard let device = record["devId"], let type = Self.string(record["devTypeId"]),
      let gateway = record["gwId"], let remoteID = Self.string(record["remoteId"])
    else { throw PositivoError.invalidResponse }
    let result = try dict(
      await call(
        "tuya.m.infrared.keydata.get",
        ["devId": device, "devTypeId": type, "gwId": gateway, "remoteId": remoteID, "vender": "3"]))
    let keys = try array(result["compressPulseList"] ?? [])
    return try keys.compactMap { key in
      guard let name = Self.string(key["keyName"] ?? key["key"]),
        let pulse = key["compressPulse"] as? String, !pulse.isEmpty,
        let extensionValue = try extras(key["exts"])["99999"]
      else { return nil }
      return IRCommand(
        name: name, payload: ["1": "send_ir", "3": extensionValue, "4": pulse, "10": 300, "13": 0])
    }
  }
  func send(_ command: IRCommand, to remote: HouseRemote) async throws {
    guard sid != nil else { throw PositivoError.noSession }
    let data = try JSONSerialization.data(
      withJSONObject: command.payload, options: [.sortedKeys, .withoutEscapingSlashes])
    guard let dps = String(data: data, encoding: .utf8) else { throw PositivoError.invalidResponse }
    _ = try await call(
      "tuya.m.device.dp.publish", ["devId": remote.device, "gwId": remote.gateway, "dps": dps])
  }
}
