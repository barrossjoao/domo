import SwiftUI

enum HouseTheme {
  static let background = Color(red: 0.025, green: 0.055, blue: 0.12)
  static let blue = Color(red: 0.25, green: 0.55, blue: 1)
  static let ice = Color(red: 0.58, green: 0.78, blue: 1)
  static let secondary = Color(red: 0.64, green: 0.72, blue: 0.84)
  static let surface = Color(red: 0.10, green: 0.16, blue: 0.26)
  static let border = Color.white.opacity(0.12)
  static let backdrop = LinearGradient(
    colors: [Color(red: 0.055, green: 0.15, blue: 0.29), background],
    startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct RemoteButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.isEnabled) private var isEnabled
  @State private var hovered = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label.opacity(configuration.isPressed ? 0.7 : 1)
      .brightness(hovered && isEnabled ? 0.07 : 0)
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .onHover { hovered = $0 }
      .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: hovered)
  }
}
