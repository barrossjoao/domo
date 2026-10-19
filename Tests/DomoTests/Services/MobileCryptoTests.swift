import XCTest

@testable import Domo

final class MobileCryptoTests: XCTestCase {
  func testMobileHashMatchesOriginalProtocol() throws {
    let fixture = try TestFixtures.object("protocol-vectors")
    XCTAssertEqual(MobileCrypto.mobileHash(fixture["body"] as! String), fixture["hash"] as? String)
  }

  func testSignatureMatchesOriginalProtocol() throws {
    let fixture = try TestFixtures.object("protocol-vectors")
    XCTAssertEqual(
      MobileCrypto.sign(fixture["params"] as! [String: String], body: fixture["body"] as? String),
      fixture["signature"] as? String
    )
  }

  func testPasswordEncryptionMatchesOriginalProtocol() throws {
    let fixture = try TestFixtures.object("protocol-vectors")
    let encrypted = try MobileCrypto.encryptedPassword(
      modulus: fixture["modulus"] as! String,
      exponent: fixture["exponent"] as! String,
      password: fixture["password"] as! String
    )
    XCTAssertEqual(encrypted, fixture["encrypted"] as? String)
  }

  func testDecimalAndHexadecimalKeyParsing() throws {
    XCTAssertEqual(try MobileCrypto.numberBytes("65537"), [1, 0, 1])
    XCTAssertEqual(try MobileCrypto.numberBytes("0x010001"), [1, 0, 1])
    XCTAssertEqual(
      try MobileCrypto.numberBytes("340282366920938463463374607431768211455"),
      Array(repeating: 255, count: 16)
    )
  }

  func testLearnedPulseKeepsLeadingZeros() throws {
    XCTAssertEqual(try MobileCrypto.numberBytes("0x0001ff", trimHexPadding: false), [0, 1, 255])
  }
}
