import SwiftUI

struct TemperatureBar: View {
  @Binding var value: Int
  let values: [Int]
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @FocusState private var focused: Bool
  @State private var dragFraction: CGFloat?

  private var index: Int { values.firstIndex(of: value) ?? 0 }
  private var fraction: CGFloat { CGFloat(index) / CGFloat(max(1, values.count - 1)) }
  private var position: CGFloat { dragFraction ?? fraction }
  private var isDragging: Bool { dragFraction != nil }
  private var temperatureTint: Color {
    let progress = Double(position)
    let warmth = max(0, (progress - 0.4) / 0.6)
    return Color(
      red: 0.25 + 0.75 * progress, green: 0.55 - 0.12 * progress,
      blue: 1 - 0.64 * warmth)
  }
  private var settling: Animation? {
    reduceMotion ? nil : .interactiveSpring(response: 0.28, dampingFraction: 0.82)
  }

  @ViewBuilder var body: some View {
    if #available(macOS 14, *) {
      slider.focusEffectDisabled()
    } else {
      slider
    }
  }

  private var slider: some View {
    GeometryReader { geometry in
      let travel = max(1, geometry.size.width - 44)
      let fillWidth = 44 + travel * position
      ZStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 19).fill(.black.opacity(0.26))
        HStack(spacing: 0) {
          ForEach(0..<values.count, id: \.self) { _ in
            Spacer(minLength: 0)
            Capsule().fill(.white.opacity(0.2)).frame(width: 1, height: 8)
          }
          Spacer(minLength: 0)
        }.padding(.horizontal, 12)
        RoundedRectangle(cornerRadius: 19)
          .fill(
            LinearGradient(
              colors: [HouseTheme.blue, temperatureTint],
              startPoint: .leading, endPoint: .trailing)
          )
          .frame(width: fillWidth)
          .shadow(color: temperatureTint.opacity(isDragging ? 0.32 : 0.14), radius: 12)
        RoundedRectangle(cornerRadius: 11).fill(.white).frame(width: 30, height: 32)
          .overlay(
            RoundedRectangle(cornerRadius: 11).stroke(temperatureTint.opacity(0.42), lineWidth: 4)
          )
          .shadow(
            color: temperatureTint.opacity(isDragging ? 0.95 : 0.65), radius: isDragging ? 12 : 7
          )
          .scaleEffect(isDragging && !reduceMotion ? 1.08 : 1)
          .offset(x: 7 + travel * position)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { gesture in
            guard isEnabled, !values.isEmpty else { return }
            focused = true
            let progress = min(1, max(0, (gesture.location.x - 22) / travel))
            dragFraction = progress
            value = values[Int((progress * CGFloat(values.count - 1)).rounded())]
          }
          .onEnded { _ in
            withAnimation(settling) { dragFraction = nil }
          }
      )
      .animation(isDragging ? nil : settling, value: index)
    }
    .frame(height: 48).opacity(isEnabled ? 1 : 0.4)
    .focusable(isEnabled && !values.isEmpty).focused($focused)
    .onChange(of: values) { _ in dragFraction = nil }
    .onChange(of: isEnabled) { _ in dragFraction = nil }
    .onMoveCommand { direction in
      switch direction {
      case .left, .down: step(-1)
      case .right, .up: step(1)
      default: break
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Temperatura desejada")
    .accessibilityValue("\(value) graus Celsius")
    .accessibilityHint("Use as setas para ajustar. A alteração é enviada automaticamente.")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment: step(1)
      case .decrement: step(-1)
      @unknown default: break
      }
    }
  }

  private func step(_ direction: Int) {
    guard isEnabled, values.indices.contains(index + direction) else { return }
    value = values[index + direction]
  }
}
