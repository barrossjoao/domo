import Foundation
import XCTest

@testable import Domo

final class MockPositivoProtocol: URLProtocol {
  static var fixture: [String: Any] = [:]
  static var actions: [String] = []
  static var publications: [[String: Any]] = []
  static var reject = false
  static var learned = false
  static var expireAction: String?
  static var offline = false
  static var deviceIDs: [String] = []
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func stopLoading() {}
  override func startLoading() {
    do {
      guard let url = request.url, url.scheme == "https", url.host == "a1.tuyaus.com" else {
        throw PositivoError.invalidResponse
      }
      let query = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems!
      let action = query.first { $0.name == "a" }!.value!
      Self.actions.append(action)
      Self.deviceIDs.append(query.first { $0.name == "deviceId" }?.value ?? "")
      if Self.offline { throw URLError(.notConnectedToInternet) }
      if action == Self.expireAction {
        Self.expireAction = nil
        try respond(["success": false, "errorCode": "USER_SESSION_INVALID"], url: url)
        return
      }
      var bytes = request.httpBody ?? Data()
      if bytes.isEmpty, let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
          let count = stream.read(&buffer, maxLength: buffer.count)
          if count <= 0 { break }
          bytes.append(buffer, count: count)
        }
      }
      let raw = String(data: bytes, encoding: .utf8) ?? ""
      let fields =
        URLComponents(
          string: "https://test.invalid/?" + raw.replacingOccurrences(of: "+", with: "%20"))?
        .queryItems ?? []
      let body = fields.first { $0.name == "postData" }?.value ?? "{}"
      let post = try JSONSerialization.jsonObject(with: Data(body.utf8)) as! [String: Any]
      let result: Any
      switch action {
      case "tuya.m.user.email.token.create":
        result = [
          "publicKey": Self.fixture["modulus"]!, "exponent": Self.fixture["exponent"]!,
          "token": "fake-token",
        ]
      case "tuya.m.user.email.password.login":
        XCTAssertEqual(post["passwd"] as? String, Self.fixture["encrypted"] as? String)
        result = ["sid": "fake-session"]
      case "tuya.m.location.list": result = [["groupId": "home"]]
      case "tuya.m.my.group.device.list":
        result = [
          ["devId": "gateway", "name": "Smart Controle Universal", "productId": "lwpag3bu0faaowlj"]
        ]
      case "tuya.m.device.sub.list":
        result = [["devId": "ac", "name": "Air Conditioning 2"], ["devId": "tv", "name": "TV"]]
      case "tuya.m.infrared.record.get":
        result = [
          "devId": "ac", "devTypeId": 5, "gwId": "gateway", "remoteId": 1,
          "exts": Self.learned ? "{\"study\":1}" : "{}",
        ]
      case "tuya.m.infrared.learn.get":
        result = [["keyName": "Teste aprendido", "compressPulse": "0001ff"]]
      case "tuya.m.infrared.keydata.get":
        var names = ["power off", "power on"]
        for mode in 0...1 {
          for temp in 18...30 { for fan in 0...3 { names.append("M\(mode)_T\(temp)_S\(fan)") } }
        }
        names += ["M2_S0", "M2_S1", "M2_S2", "M2_S3", "M3_S1", "M3_S2", "M3_S3", "M4_S0"]
        result = [
          "compressPulseList": names.map {
            ["keyName": $0, "exts": "{\"99999\":\"encoded\"}", "compressPulse": "pulse-" + $0]
          }
        ]
      case "tuya.m.device.dp.publish":
        Self.publications.append(post)
        result = true
      default: throw PositivoError.invalidResponse
      }
      let reply: [String: Any] =
        Self.reject
        ? ["success": false, "errorCode": "USER_PASSWD_WRONG"]
        : ["success": true, "result": result]
      try respond(reply, url: url)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }

  private func respond(_ reply: [String: Any], url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: reply)
    client?.urlProtocol(
      self,
      didReceive: HTTPURLResponse(
        url: url, statusCode: 200, httpVersion: nil,
        headerFields: nil)!, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: data)
    client?.urlProtocolDidFinishLoading(self)
  }

  static func makeClient(storage: LoginStorage = MemoryLoginStorage()) throws -> PositivoClient {
    fixture = try TestFixtures.object("protocol-vectors")
    actions = []
    publications = []
    reject = false
    learned = false
    expireAction = nil
    offline = false
    deviceIDs = []
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockPositivoProtocol.self]
    return PositivoClient(session: URLSession(configuration: config), loginStorage: storage)
  }
}
