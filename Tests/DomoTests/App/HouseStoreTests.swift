import XCTest

@testable import Domo

final class HouseStoreTests: XCTestCase {
  @MainActor
  private func connectedStore() async throws -> HouseStore {
    let client = try MockPositivoProtocol.makeClient()
    let store = HouseStore(client: client)
    await store.connect(
      email: "teste@example.com", password: MockPositivoProtocol.fixture["password"] as! String)
    XCTAssertTrue(store.connected)
    return store
  }

  @MainActor
  private func finishSending(_ store: HouseStore) async throws {
    let deadline = Date().addingTimeInterval(3)
    while store.sending && Date() < deadline { try await Task.sleep(nanoseconds: 1_000_000) }
    XCTAssertFalse(store.sending, "The command queue did not finish.")
  }

  @MainActor
  func testLoadingControlsDoesNotSendCommands() async throws {
    let store = try await connectedStore()
    XCTAssertEqual(store.commands.count, 114)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
    await store.selectRemote(store.selectedID)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
  }

  @MainActor
  func testInputChangesApplyAutomatically() async throws {
    let store = try await connectedStore()
    store.changeFan(1)
    try await finishSending(store)
    store.stepTemperature(1)
    try await finishSending(store)
    XCTAssertEqual(MockPositivoProtocol.publications.count, 2)
  }

  @MainActor
  func testTemperatureBarOnlySendsAvailableChangedValues() async throws {
    let store = try await connectedStore()
    let initial = store.temperature
    store.setTemperature(initial)
    store.setTemperature(999)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
    store.setTemperature(28)
    try await finishSending(store)
    XCTAssertEqual(store.temperature, 28)
    XCTAssertEqual(MockPositivoProtocol.publications.count, 1)
    store.changeMode(3)
    try await finishSending(store)
    let count = MockPositivoProtocol.publications.count
    store.setTemperature(24)
    XCTAssertEqual(MockPositivoProtocol.publications.count, count)
  }

  @MainActor
  func testVentilationModeDoesNotExposeTemperature() async throws {
    let store = try await connectedStore()
    store.changeFan(1)
    try await finishSending(store)
    store.changeMode(3)
    try await finishSending(store)
    XCTAssertTrue(store.temperatures.isEmpty)
    XCTAssertEqual(store.fan, 1)
  }

  @MainActor
  func testRestoringLoginOnlyLoadsControls() async throws {
    let storage = MemoryLoginStorage()
    let client = try MockPositivoProtocol.makeClient(storage: storage)
    let store = HouseStore(client: client)
    await store.connect(
      email: "teste@example.com",
      password: MockPositivoProtocol.fixture["password"] as! String)
    let reopened = HouseStore(client: try MockPositivoProtocol.makeClient(storage: storage))
    await reopened.restoreLogin()
    XCTAssertTrue(reopened.connected)
    XCTAssertEqual(reopened.commands.count, 114)
    XCTAssertFalse(reopened.restoring)
    XCTAssertTrue(MockPositivoProtocol.publications.isEmpty)
    reopened.disconnect()
    await reopened.restoreLogin()
    XCTAssertFalse(reopened.connected)
  }

  @MainActor
  func testClimatePowerAlternatesAfterSuccessAndKeepsActionAfterFailure() async throws {
    let store = try await connectedStore()
    XCTAssertEqual(store.climatePowerCommand?.name, "power on")
    store.send(try XCTUnwrap(store.climatePowerCommand).name)
    try await finishSending(store)
    XCTAssertEqual(store.climatePowerCommand?.name, "power off")
    MockPositivoProtocol.offline = true
    store.send(try XCTUnwrap(store.climatePowerCommand).name)
    try await finishSending(store)
    XCTAssertEqual(store.climatePowerCommand?.name, "power off")
    MockPositivoProtocol.offline = false
    store.send(try XCTUnwrap(store.climatePowerCommand).name)
    try await finishSending(store)
    XCTAssertEqual(store.climatePowerCommand?.name, "power on")
    store.stepTemperature(1)
    try await finishSending(store)
    XCTAssertEqual(store.climatePowerCommand?.name, "power off")
    let ac = store.selectedID
    let other = try XCTUnwrap(store.remotes.first { $0.id != ac })
    await store.selectRemote(other.id)
    XCTAssertEqual(store.climatePowerCommand?.name, "power on")
    await store.selectRemote(ac)
    XCTAssertEqual(store.climatePowerCommand?.name, "power off")
    store.disconnect()
    XCTAssertNil(store.climatePowerCommand)
  }

  @MainActor
  func testDisconnectClearsVisibleControls() async throws {
    let store = try await connectedStore()
    store.disconnect()
    XCTAssertFalse(store.connected)
    XCTAssertTrue(store.commands.isEmpty)
  }
}
