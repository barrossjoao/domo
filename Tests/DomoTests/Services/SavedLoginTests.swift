import XCTest

@testable import Domo

final class SavedLoginTests: XCTestCase {
  private func connect(_ client: PositivoClient) async throws -> [HouseRemote] {
    try await client.connect(
      email: "teste@example.com",
      password: MockPositivoProtocol.fixture["password"] as! String)
  }

  func testRestoresSessionAndDeviceIdentityWithoutLoginOrCommands() async throws {
    let storage = MemoryLoginStorage()
    let first = try MockPositivoProtocol.makeClient(storage: storage)
    _ = try await connect(first)
    let deviceID = try XCTUnwrap(storage.value?.deviceID)
    let reopened = try MockPositivoProtocol.makeClient(storage: storage)
    let remotes = try await reopened.restoreConnection()
    XCTAssertEqual(remotes?.count, 2)
    XCTAssertTrue(MockPositivoProtocol.deviceIDs.allSatisfy { $0 == deviceID })
    XCTAssertFalse(MockPositivoProtocol.actions.contains("tuya.m.user.email.password.login"))
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
  }

  func testExpiredSessionIsRenewedOnceWithoutPublishingIR() async throws {
    let storage = MemoryLoginStorage()
    _ = try await connect(MockPositivoProtocol.makeClient(storage: storage))
    let reopened = try MockPositivoProtocol.makeClient(storage: storage)
    MockPositivoProtocol.expireAction = "tuya.m.location.list"
    _ = try await reopened.restoreConnection()
    XCTAssertEqual(
      MockPositivoProtocol.actions.filter { $0 == "tuya.m.user.email.password.login" }.count, 1)
    XCTAssertEqual(MockPositivoProtocol.actions.filter { $0 == "tuya.m.location.list" }.count, 2)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
  }

  func testOfflineRestoreKeepsSavedAccessForRetry() async throws {
    let storage = MemoryLoginStorage()
    _ = try await connect(MockPositivoProtocol.makeClient(storage: storage))
    let reopened = try MockPositivoProtocol.makeClient(storage: storage)
    MockPositivoProtocol.offline = true
    do {
      _ = try await reopened.restoreConnection()
      XCTFail("Offline restoration must report the network error.")
    } catch is URLError {}
    XCTAssertNotNil(storage.value)
    XCTAssertTrue(reopened.hasSavedLogin)
    XCTAssertFalse(MockPositivoProtocol.actions.contains("tuya.m.user.email.password.login"))
    MockPositivoProtocol.offline = false
    let remotes = try await reopened.restoreConnection()
    XCTAssertEqual(remotes?.count, 2)
  }

  func testDisconnectRequiresManualLoginEvenWhenKeychainRemovalFails() async throws {
    let storage = MemoryLoginStorage()
    let client = try MockPositivoProtocol.makeClient(storage: storage)
    _ = try await connect(client)
    storage.clearError = URLError(.noPermissionsToReadFile)
    XCTAssertThrowsError(try client.disconnect())
    XCTAssertFalse(client.hasSavedLogin)
    let reopened = try MockPositivoProtocol.makeClient(storage: storage)
    let restored = try await reopened.restoreConnection()
    XCTAssertNil(restored)
    XCTAssertTrue(MockPositivoProtocol.actions.isEmpty)
  }

  func testSavingFailureDoesNotPreventCurrentConnection() async throws {
    let storage = MemoryLoginStorage()
    storage.saveError = URLError(.noPermissionsToReadFile)
    let client = try MockPositivoProtocol.makeClient(storage: storage)
    let remotes = try await connect(client)
    XCTAssertEqual(remotes.count, 2)
    XCTAssertFalse(client.hasSavedLogin)
    XCTAssertNotNil(client.persistenceWarning)
  }
}
