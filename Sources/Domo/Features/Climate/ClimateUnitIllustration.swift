import SwiftUI

struct ClimateUnitIllustration: View {
  let temperature: Int?
  let fan: Int
  var height: CGFloat = 150
  @State private var isVisible = false
  @State private var phaseOrigin = Date()
  @State private var phaseOffset = 0.0
  @State private var speed = 0.3

  private func airflowSpeed(_ fan: Int) -> Double {
    switch fan {
    case 1: return 0.22
    case 2: return 0.34
    case 3: return 0.5
    default: return 0.3
    }
  }

  private func updateSpeed() {
    let now = Date()
    phaseOffset = (phaseOffset + now.timeIntervalSince(phaseOrigin) * speed)
      .truncatingRemainder(dividingBy: 1)
    phaseOrigin = now
    speed = airflowSpeed(fan)
  }
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      ZStack(alignment: .top) {
        Ellipse().fill(HouseTheme.blue.opacity(0.17))
          .frame(width: width * 0.7, height: 100).blur(radius: 26).offset(y: 16)
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: reduceMotion || !isVisible)) {
          timeline in
          Canvas { context, size in
            let phaseTime =
              reduceMotion ? 0 : phaseOffset + timeline.date.timeIntervalSince(phaseOrigin) * speed
            for index in 0..<11 {
              let fraction = CGFloat(index) / 10
              let start = CGPoint(x: size.width * (0.25 + fraction * 0.5), y: 46)
              let end = CGPoint(x: size.width * (0.025 + fraction * 0.95), y: size.height)
              var path = Path()
              path.move(to: start)
              path.addCurve(
                to: end,
                control1: CGPoint(x: start.x, y: size.height * 0.55),
                control2: CGPoint(x: start.x + (end.x - start.x) * 0.3, y: size.height * 0.79))
              context.stroke(
                path,
                with: .linearGradient(
                  Gradient(colors: [HouseTheme.ice.opacity(0.28), HouseTheme.blue.opacity(0.045)]),
                  startPoint: start, endPoint: end), lineWidth: 1)
              for segment in 0..<3 {
                let phase =
                  (phaseTime + Double(index) * 0.13 + Double(segment) / 3)
                  .truncatingRemainder(dividingBy: 1)
                context.stroke(
                  path.trimmedPath(from: phase, to: min(1, phase + 0.075)),
                  with: .color(
                    HouseTheme.ice.opacity(0.65 * min(1, phase / 0.1) * min(1, (1 - phase) / 0.18))),
                  style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
              }
            }
          }
        }
        ZStack(alignment: .bottom) {
          RoundedRectangle(cornerRadius: 19, style: .continuous)
            .fill(
              LinearGradient(
                colors: [
                  .white, Color(red: 0.87, green: 0.92, blue: 0.98),
                  Color(red: 0.69, green: 0.77, blue: 0.86),
                ],
                startPoint: .top, endPoint: .bottom)
            )
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.75)))
            .shadow(color: .black.opacity(0.3), radius: 16, y: 10)
          VStack(spacing: 11) {
            HStack {
              Text("DOMO").font(.system(size: 6, weight: .semibold, design: .rounded))
                .tracking(1.4).foregroundStyle(Color(red: 0.37, green: 0.46, blue: 0.57))
              Spacer()
              HStack(spacing: 0) {
                if let temperature {
                  ClimateTemperatureText(value: temperature)
                  Text("°")
                } else {
                  Text("—")
                }
              }.font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(HouseTheme.blue)
              Circle().fill(HouseTheme.blue).frame(width: 3, height: 3)
            }.padding(.horizontal, 18)
            Capsule()
              .fill(
                LinearGradient(
                  colors: [Color(white: 0.30), Color(white: 0.48)],
                  startPoint: .top, endPoint: .bottom)
              )
              .frame(height: 7)
              .overlay(alignment: .bottom) { Capsule().fill(.white.opacity(0.3)).frame(height: 1) }
              .padding(.horizontal, 15)
          }.padding(.bottom, 9)
        }.frame(width: width * 0.61, height: 60)
      }
    }.frame(height: height).accessibilityHidden(true).allowsHitTesting(false)
      .onAppear {
        phaseOrigin = Date()
        speed = airflowSpeed(fan)
        isVisible = true
      }
      .onChange(of: fan) { _ in updateSpeed() }
      .onDisappear {
        updateSpeed()
        isVisible = false
      }
  }
}
