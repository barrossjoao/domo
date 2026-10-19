import SwiftUI

struct ClimateTemperatureText: View {
  let value: Int
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    Group {
      if #available(macOS 14, *), !reduceMotion {
        Text(String(value)).contentTransition(.numericText(value: Double(value)))
      } else {
        ZStack {
          Text(String(value)).id(value).transition(.opacity)
        }
      }
    }
    .monospacedDigit()
    .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.86), value: value)
  }
}
