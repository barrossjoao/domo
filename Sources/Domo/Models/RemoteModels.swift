import Foundation

struct HouseRemote: Identifiable, Hashable {
  let id: String
  let gateway: String
  let device: String
  let name: String
  var displayName: String {
    name.replacingOccurrences(
      of: "Air Conditioning", with: "Ar-condicionado", options: .caseInsensitive)
  }
}

struct IRCommand: Identifiable {
  let name: String
  let payload: [String: Any]
  var id: String { name }
}

struct ClimateChoice {
  let name: String
  let mode: Int
  let temp: Int?
  let fan: Int
  private static let pattern = try! NSRegularExpression(
    pattern: "^M([0-4])(?:_T([0-9]+))?_S([0-3])$", options: .caseInsensitive)
  init?(_ name: String) {
    guard
      let match = Self.pattern.firstMatch(in: name, range: NSRange(name.startIndex..., in: name))
    else { return nil }
    func part(_ number: Int) -> String? {
      Range(match.range(at: number), in: name).map { String(name[$0]) }
    }
    guard let mode = Int(part(1) ?? ""), let fan = Int(part(3) ?? "") else { return nil }
    self.name = name
    self.mode = mode
    self.fan = fan
    self.temp = part(2).flatMap(Int.init)
  }
}
