import XCTest

@testable import Domo

final class PositivoClientTests: XCTestCase {
  private func connect(_ client: PositivoClient) async throws -> [HouseRemote] {
    try await client.connect(
      email: "teste@example.com",
      password: MockPositivoProtocol.fixture["password"] as! String
    )
  }

  func testDiscoveryDoesNotSendCommands() async throws {
    let client = try MockPositivoProtocol.makeClient()
    let remotes = try await connect(client)
    XCTAssertEqual(remotes.count, 2)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
  }

  func testCommandEnumerationDoesNotSendCommands() async throws {
    let client = try MockPositivoProtocol.makeClient()
    let remotes = try await connect(client)
    let commands = try await client.commands(for: remotes[0])
    XCTAssertEqual(commands.count, 114)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
  }

  func testIRCommandUsesSelectedRemoteAndOriginalPayload() async throws {
    let client = try MockPositivoProtocol.makeClient()
    let remotes = try await connect(client)
    let commands = try await client.commands(for: remotes[0])
    let command = try XCTUnwrap(commands.first { $0.name == "M0_T23_S1" })
    try await client.send(command, to: remotes[0])
    let publication = try XCTUnwrap(MockPositivoProtocol.publications.last)
    XCTAssertEqual(publication["devId"] as? String, "ac")
    XCTAssertEqual(publication["gwId"] as? String, "gateway")
    let serialized = try XCTUnwrap(publication["dps"] as? String)
    let payload = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(serialized.utf8)) as? [String: Any])
    XCTAssertEqual(payload["4"] as? String, "pulse-M0_T23_S1")
    XCTAssertEqual(payload["3"] as? String, "encoded")
  }

  func testLearnedCommandPreservesCompressedPulse() async throws {
    let client = try MockPositivoProtocol.makeClient()
    let remotes = try await connect(client)
    MockPositivoProtocol.learned = true
    let commands = try await client.commands(for: remotes[0])
    XCTAssertEqual(commands[0].payload["7"] as? String, Data([0, 1, 255]).base64EncodedString())
  }

  func testDisconnectClearsSession() async throws {
    let client = try MockPositivoProtocol.makeClient()
    let remotes = try await connect(client)
    try client.disconnect()
    do {
      _ = try await client.commands(for: remotes[0])
      XCTFail("Disconnected clients must require a new session.")
    } catch PositivoError.noSession {
    }
  }

  func testCloudErrorIsPresentedWithoutSensitiveData() async throws {
    let client = try MockPositivoProtocol.makeClient()
    MockPositivoProtocol.reject = true
    do {
      _ = try await client.connect(email: "teste@example.com", password: "fake")
      XCTFail("Cloud rejection must propagate.")
    } catch {
      XCTAssertTrue(error.localizedDescription.contains("recusados"))
    }
  }
}
