import CryptoKit
import Foundation
import Security

// Adapted from unofficial-positivo-pcuirn; see Licenses/positivo-integration-MIT.txt.
enum MobileCrypto {
  static let clientID = "qk4c93xsttfjsm4ktr94"
  // Identifies the public mobile application; this is not a user's credential.
  static let appKey = "A_9v5dh8yngmhtxdjen7t7qqx5ggmdf5su_w7vm9gr7meys387fpj7y7yrvx8w554cd"
  static func hex(_ data: some Sequence<UInt8>) -> String {
    data.map { String(format: "%02x", $0) }.joined()
  }
  static func md5(_ text: String) -> String { hex(Insecure.MD5.hash(data: Data(text.utf8))) }
  static func mobileHash(_ text: String) -> String {
    let chars = Array(md5(text))
    return String(chars[8..<16] + chars[0..<8] + chars[24..<32] + chars[16..<24])
  }
  static func sign(_ params: [String: String], body: String?) -> String {
    let allowed: Set<String> = [
      "a", "v", "lat", "lon", "lang", "deviceId", "imei", "imsi", "appVersion", "ttid", "isH5",
      "h5Token", "os", "clientId", "postData", "time", "requestId", "n4h5", "sid", "sp", "et",
    ]
    var data = params
    if let body = body { data["postData"] = body }
    let canonical = data.keys.sorted().filter { allowed.contains($0) && !(data[$0] ?? "").isEmpty }
      .map { key in
        key + "=" + (key == "postData" ? mobileHash(data[key]!) : data[key]!)
      }.joined(separator: "||")
    return hex(
      HMAC<SHA256>.authenticationCode(
        for: Data(canonical.utf8), using: SymmetricKey(data: Data(appKey.utf8))))
  }
  static func numberBytes(_ string: String, trimHexPadding: Bool = true) throws -> [UInt8] {
    let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if value.lowercased().hasPrefix("0x") {
      var hex = String(value.dropFirst(2))
      if hex.count % 2 == 1 { hex = "0" + hex }
      guard !hex.isEmpty else { throw PositivoError.invalidKey }
      var result: [UInt8] = []
      var index = hex.startIndex
      while index < hex.endIndex {
        let next = hex.index(index, offsetBy: 2)
        guard let byte = UInt8(hex[index..<next], radix: 16) else { throw PositivoError.invalidKey }
        result.append(byte)
        index = next
      }
      if trimHexPadding { while result.count > 1 && result.first == 0 { result.removeFirst() } }
      return result
    }
    guard !value.isEmpty, value.allSatisfy({ $0.isASCII && $0.isNumber }) else {
      throw PositivoError.invalidKey
    }
    var bytes: [UInt8] = [0]
    for digit in value.utf8 {
      var carry = Int(digit - 48)
      for index in bytes.indices.reversed() {
        let sum = Int(bytes[index]) * 10 + carry
        bytes[index] = UInt8(sum & 255)
        carry = sum >> 8
      }
      while carry > 0 {
        bytes.insert(UInt8(carry & 255), at: 0)
        carry >>= 8
      }
    }
    return bytes
  }
  private static func der(_ tag: UInt8, _ bytes: [UInt8]) -> [UInt8] {
    var length = bytes.count
    if length < 128 { return [tag, UInt8(length)] + bytes }
    var encoded: [UInt8] = []
    while length > 0 {
      encoded.insert(UInt8(length & 255), at: 0)
      length >>= 8
    }
    return [tag, 0x80 | UInt8(encoded.count)] + encoded + bytes
  }
  static func encryptedPassword(modulus: String, exponent: String, password: String) throws
    -> String
  {
    let n = try numberBytes(modulus)
    let e = try numberBytes(exponent)
    guard n.count >= 128, n.count <= 1024, e.contains(where: { $0 != 0 }) else {
      throw PositivoError.invalidKey
    }
    func integer(_ bytes: [UInt8]) -> [UInt8] {
      der(0x02, (bytes[0] & 0x80 != 0 ? [0] : []) + bytes)
    }
    let keyData = Data(der(0x30, integer(n) + integer(e)))
    let attributes: [CFString: Any] = [
      kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPublic,
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error)
    else { throw PositivoError.invalidKey }
    let message = Array(md5(password).utf8)
    let blockSize = SecKeyGetBlockSize(key)
    guard blockSize >= message.count else { throw PositivoError.invalidKey }
    let padded = Data(repeating: 0, count: blockSize - message.count) + Data(message)
    // This raw RSA format is required by the existing OEM mobile protocol.
    guard
      let encrypted = SecKeyCreateEncryptedData(key, .rsaEncryptionRaw, padded as CFData, &error)
        as Data?
    else { throw PositivoError.invalidKey }
    var bytes = Array(encrypted)
    while bytes.count > 1 && bytes.first == 0 { bytes.removeFirst() }
    return String(repeating: "0", count: 64) + hex(bytes)
  }
}
