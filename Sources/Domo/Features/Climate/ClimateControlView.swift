import SwiftUI

struct ClimateControlView: View {
  @ObservedObject var store: HouseStore
  var compact = false
  var showIllustration = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var presentedMenu: ControlMenu?

  private enum ControlMenu { case mode, fan }

  private func isPresented(_ menu: ControlMenu) -> Binding<Bool> {
    Binding(get: { presentedMenu == menu }, set: { presentedMenu = $0 ? menu : nil })
  }

  private var modeIcon: String {
    switch store.mode {
    case 1: return "sun.max"
    case 2: return "sparkles"
    case 3: return "wind"
    case 4: return "drop"
    default: return "snowflake"
    }
  }

  var body: some View {
    VStack(spacing: compact ? 12 : 16) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Label("CLIMA", systemImage: "thermometer.medium")
            .font(.system(size: 10, weight: .semibold)).tracking(2)
            .foregroundStyle(HouseTheme.ice)
          Text(store.remote?.displayName ?? "Ar-condicionado")
            .font(.system(size: 20, weight: .semibold))
        }
        Spacer()
        if let command = store.climatePowerCommand {
          Button {
            store.send(command.name)
          } label: {
            VStack(spacing: 5) {
              Image(systemName: "power")
                .font(.system(size: 23, weight: .medium)).foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                  LinearGradient(
                    colors: [HouseTheme.ice, HouseTheme.blue],
                    startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.25)))
                .shadow(color: HouseTheme.blue.opacity(0.3), radius: 12)
              Text(RemoteCatalog.label(command.name))
                .font(.system(size: 10, weight: .medium)).foregroundStyle(HouseTheme.ice)
            }.frame(minWidth: 60)
          }
          .buttonStyle(RemoteButtonStyle())
          .accessibilityLabel(RemoteCatalog.label(command.name) + " o ar-condicionado")
          .help(
            "Um clique envia " + RemoteCatalog.label(command.name).lowercased()
              + ". A ação se baseia nos comandos enviados pelo app; o infravermelho não confirma o estado físico."
          )
          .disabled(store.busy || store.sending)
        }
      }

      if showIllustration {
        ClimateUnitIllustration(
          temperature: store.temperatures.isEmpty ? nil : store.temperature,
          fan: store.fan, height: compact ? 80 : 132
        )
        .frame(maxWidth: 400).frame(maxWidth: .infinity)
        .padding(.top, compact ? 0 : 4)
      }

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 2) {
          if !store.temperatures.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
              ClimateTemperatureText(value: store.temperature)
                .font(.system(size: compact ? 60 : 68, weight: .ultraLight)).monospacedDigit()
              Text("°C").font(.system(size: 25, weight: .medium)).foregroundStyle(HouseTheme.ice)
            }.accessibilityElement(children: .ignore)
              .accessibilityLabel("Temperatura desejada, \(store.temperature) graus Celsius")
          } else {
            Text(RemoteCatalog.modes[store.mode] ?? "Automático")
              .font(.system(size: 32, weight: .light)).frame(
                height: compact ? 64 : 74, alignment: .bottom)
          }
          Text(
            store.temperatures.isEmpty
              ? "Temperatura não ajustável neste modo" : "Temperatura desejada"
          )
          .font(.caption).foregroundStyle(HouseTheme.secondary)
        }
        Spacer()
        Label(
          store.sending ? "Enviando" : "Controle IR",
          systemImage: store.sending ? "arrow.up" : "dot.radiowaves.left.and.right"
        )
        .font(.system(size: 11, weight: .medium)).foregroundStyle(HouseTheme.ice)
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(HouseTheme.blue.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(HouseTheme.blue.opacity(0.2)))
        .padding(.bottom, 3)
        .help(
          "Infravermelho: o estado físico do aparelho não é confirmado. Os ajustes são enviados automaticamente."
        )
      }

      if let minimum = store.temperatures.first, let maximum = store.temperatures.last {
        VStack(spacing: 8) {
          HStack(spacing: 14) {
            temperatureButton("minus", step: -1, disabled: store.temperature == minimum)
            TemperatureBar(
              value: Binding(get: { store.temperature }, set: store.setTemperature),
              values: store.temperatures
            ).disabled(store.busy || minimum == maximum)
            temperatureButton("plus", step: 1, disabled: store.temperature == maximum)
          }
          HStack {
            Text("\(minimum)°")
            Spacer()
            Text("\(maximum)°")
          }.font(.system(size: 11, weight: .medium)).foregroundStyle(HouseTheme.secondary)
            .padding(.horizontal, 58)
        }
      }

      HStack(spacing: 12) {
        selectionCard(
          menu: .mode, title: "Modo", icon: modeIcon,
          value: RemoteCatalog.modes[store.mode] ?? "Automático"
        ) {
          ForEach(store.modes, id: \.self) { mode in
            optionButton(RemoteCatalog.modes[mode] ?? "Automático", selected: mode == store.mode) {
              store.changeMode(mode)
            }
          }
        }
        selectionCard(
          menu: .fan, title: "Ventilação", icon: "fanblades",
          value: RemoteCatalog.fans[store.fan] ?? "Automática"
        ) {
          ForEach(store.fans, id: \.self) { fan in
            optionButton(RemoteCatalog.fans[fan] ?? "Automática", selected: fan == store.fan) {
              store.changeFan(fan)
            }
          }
        }
      }.disabled(store.busy)

    }
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.temperatures.isEmpty)
  }

  private func temperatureButton(_ icon: String, step: Int, disabled: Bool) -> some View {
    Button {
      store.stepTemperature(step)
    } label: {
      Image(systemName: icon).font(.system(size: 19, weight: .medium))
        .frame(width: 42, height: 44)
        .background(.white.opacity(0.065), in: Circle())
        .overlay(Circle().stroke(.white.opacity(0.06)))
    }.buttonStyle(RemoteButtonStyle())
      .accessibilityLabel(step < 0 ? "Diminuir temperatura" : "Aumentar temperatura")
      .disabled(store.busy || disabled).opacity(disabled ? 0.4 : 1)
  }

  private func selectionCard<Content: View>(
    menu: ControlMenu, title: String, icon: String, value: String,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    Button {
      presentedMenu = menu
    } label: {
      VStack(alignment: .leading, spacing: compact ? 10 : 12) {
        HStack {
          Image(systemName: icon).font(.system(size: compact ? 22 : 25, weight: .light))
            .foregroundStyle(
              HouseTheme.ice)
          Spacer()
          Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
            .foregroundStyle(HouseTheme.secondary)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(title).font(.system(size: 12)).foregroundStyle(HouseTheme.secondary)
          Text(value).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
        }
      }.padding(compact ? 12 : 14).frame(maxWidth: .infinity, alignment: .leading)
        .background(
          LinearGradient(
            colors: [HouseTheme.surface, HouseTheme.surface.opacity(0.55)],
            startPoint: .topLeading, endPoint: .bottomTrailing),
          in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(HouseTheme.border))
    }.buttonStyle(RemoteButtonStyle())
      .popover(isPresented: isPresented(menu), arrowEdge: .bottom) {
        VStack(spacing: 4, content: content).padding(8).preferredColorScheme(.dark)
      }
      .accessibilityLabel("\(title): \(value)")
  }
  private func optionButton(
    _ title: String, selected: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      action()
      presentedMenu = nil
    } label: {
      HStack(spacing: 16) {
        Text(title)
        Spacer()
        Image(systemName: "checkmark").opacity(selected ? 1 : 0)
      }.padding(10).frame(minWidth: 170)
    }.buttonStyle(.borderless).tint(HouseTheme.ice)
  }

}
