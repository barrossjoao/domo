import XCTest

@testable import Domo

final class RemoteCatalogTests: XCTestCase {
  func testTVButtonsKeepOriginalCommandNames() throws {
    let names = try TestFixtures.tvCommands()
    let keys = RemoteCatalog.tvKeys(names)
    XCTAssertEqual(keys["power"], "On/Off")
    XCTAssertEqual(keys["up"], "Navigate Up")
    XCTAssertEqual(keys["digit0"], "Channel 0")
    XCTAssertTrue(keys.values.allSatisfy(names.contains))
  }

  func testClimateLabelsAreReadable() {
    XCTAssertEqual(RemoteCatalog.label("M0_T23_S1"), "Resfriar · 23 °C · Ventilação baixa")
    XCTAssertEqual(RemoteCatalog.label("M3_S2"), "Ventilar · Ventilação média")
  }

  func testClimateModesWithoutTemperature() {
    XCTAssertNil(ClimateChoice("M4_S0")?.temp)
    XCTAssertEqual(ClimateChoice("M4_S0")?.mode, 4)
    XCTAssertNil(ClimateChoice("M0_T23_S9"))
  }
}
