import SwiftUI

struct TVRemoteView: View {
  @ObservedObject var store: HouseStore
  var compact = false
  var showIllustration = true
  @State private var panel: Panel?
  private enum Panel: String, Identifiable {
    case numbers, media, power
    var id: String { rawValue }
  }
  private var keys: [String: String] { store.tvKeys }
  private var tight: Bool { !showIllustration }
  private var diameter: CGFloat { tight ? 132 : compact ? 176 : 208 }
  private let mediaKeys = ["rewind", "play", "fastforward", "record", "pause", "stop"]
  private let colorKeys = ["red", "green", "yellow", "blue"]

  var body: some View {
    VStack(spacing: tight ? 8 : compact ? 14 : 20) {
      HStack(spacing: 16) {
        if showIllustration {
          television.frame(width: compact ? 86 : 106, height: compact ? 60 : 74)
        }
        VStack(alignment: .leading, spacing: 5) {
          Text("Televisão").font(.system(size: compact ? 22 : 26, weight: .semibold))
          if !tight {
            Text("Seu controle, por perto").font(.system(size: 12)).foregroundStyle(
              HouseTheme.secondary)
          }
        }
        Spacer(minLength: 0)
        if let power = keys["power"] {
          Button {
            store.send(power)
          } label: {
            powerIcon
          }
          .accessibilityLabel(RemoteCatalog.label(power)).help(RemoteCatalog.label(power))
        } else if !store.powerCommands.isEmpty {
          Button {
            panel = .power
          } label: {
            powerIcon
          }.accessibilityLabel("Opções de energia")
        }
      }
      HStack(spacing: 12) {
        shortcut("back", "Voltar", "arrow.uturn.backward")
        shortcut("home", "Início", "house")
        shortcut("menu", "Menu", "line.3.horizontal")
        shortcut("mute", "Silenciar", "speaker.slash")
      }
      HStack(spacing: 12) {
        rocker("Volume", up: "volumeup", down: "volumedown", icon: "speaker.wave.2")
        Spacer(minLength: 0)
        directionPad
        Spacer(minLength: 0)
        rocker("Canal", up: "channelup", down: "channeldown", icon: "number")
      }.padding(.vertical, tight ? 0 : compact ? 2 : 8)
      HStack(spacing: 10) {
        if (0...9).contains(where: { keys["digit\($0)"] != nil }) || keys["guide"] != nil
          || keys["last"] != nil
        {
          panelButton("Números", icon: "circle.grid.3x3", panel: .numbers)
        }
        if (mediaKeys + colorKeys + ["netflix"]).contains(where: { keys[$0] != nil }) {
          panelButton("Mídia", icon: "play.rectangle", panel: .media)
        }
        shortcut("input", "Fonte", "rectangle.on.rectangle", card: true)
        shortcut("settings", "Ajustes", "slider.horizontal.3", card: true)
      }
    }.buttonStyle(RemoteButtonStyle()).foregroundStyle(.white)
      .disabled(store.busy || store.sending)
      .popover(item: $panel, arrowEdge: .bottom) { selection in
        VStack(spacing: 16) {
          HStack {
            Text(
              selection == .numbers
                ? "Números e canais" : selection == .media ? "Mídia e atalhos" : "Energia"
            )
            .font(.headline)
            Spacer()
            Button {
              panel = nil
            } label: {
              Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain).foregroundStyle(HouseTheme.secondary).accessibilityLabel(
              "Fechar painel")
          }
          switch selection {
          case .numbers: numberPad
          case .media: mediaPad
          case .power:
            ForEach(store.powerCommands) { command in
              Button(RemoteCatalog.label(command.name)) { store.send(command.name) }
                .buttonStyle(.bordered).disabled(store.busy || store.sending)
            }
          }
        }.padding(20).frame(width: 280).background(HouseTheme.backdrop).foregroundStyle(.white)
          .buttonStyle(RemoteButtonStyle()).preferredColorScheme(.dark)
      }
  }

  private var television: some View {
    VStack(spacing: 0) {
      ZStack {
        RoundedRectangle(cornerRadius: 12).fill(
          LinearGradient(
            colors: [HouseTheme.blue.opacity(0.6), HouseTheme.surface],
            startPoint: .topLeading, endPoint: .bottomTrailing))
        Image(systemName: "tv").font(.system(size: compact ? 25 : 32, weight: .ultraLight))
          .foregroundStyle(HouseTheme.ice)
      }.overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.24), lineWidth: 2))
        .shadow(color: HouseTheme.blue.opacity(0.25), radius: 20, y: 5)
      Rectangle().fill(HouseTheme.secondary).frame(width: 5, height: 7)
      Capsule().fill(HouseTheme.secondary).frame(width: 34, height: 3)
    }.accessibilityHidden(true)
  }
  private var powerIcon: some View {
    Image(systemName: "power").font(.system(size: 23, weight: .medium)).frame(
      width: tight ? 40 : 54, height: tight ? 40 : 54
    )
    .background(
      LinearGradient(
        colors: [HouseTheme.ice, HouseTheme.blue],
        startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle()
    )
    .shadow(color: HouseTheme.blue.opacity(0.35), radius: 16, y: 4)
  }
  private var directionPad: some View {
    ZStack {
      Circle().fill(
        LinearGradient(
          colors: [HouseTheme.surface, HouseTheme.background],
          startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .overlay(Circle().stroke(HouseTheme.border)).shadow(
        color: .black.opacity(0.25), radius: 12, y: 8)
      Circle().stroke(.white.opacity(0.045), lineWidth: 1).padding(8)
      VStack(spacing: 0) {
        direction("up", "chevron.up")
        Spacer(minLength: 0)
        direction("down", "chevron.down")
      }
      HStack(spacing: 0) {
        direction("left", "chevron.left")
        Spacer(minLength: 0)
        direction("right", "chevron.right")
      }
      if let command = keys["ok"] {
        Button {
          store.send(command)
        } label: {
          Text("OK").font(.system(size: 19, weight: .semibold))
            .frame(width: tight ? 50 : compact ? 62 : 72, height: tight ? 50 : compact ? 62 : 72)
            .background(
              LinearGradient(
                colors: [HouseTheme.blue, HouseTheme.blue.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle()
            )
            .overlay(Circle().stroke(HouseTheme.ice.opacity(0.4)))
            .shadow(color: HouseTheme.blue.opacity(0.25), radius: 12)
        }.accessibilityLabel("Confirmar, OK").help("Confirmar")
      }
    }.frame(width: diameter, height: diameter)
  }
  @ViewBuilder private func direction(_ id: String, _ symbol: String) -> some View {
    if let command = keys[id] {
      Button {
        store.send(command)
      } label: {
        Image(systemName: symbol).font(.system(size: 15, weight: .semibold))
          .frame(width: tight ? 40 : 50, height: tight ? 40 : 50).contentShape(Circle())
      }.accessibilityLabel(RemoteCatalog.label(command)).help(RemoteCatalog.label(command))
    }
  }
  @ViewBuilder private func rocker(_ title: String, up: String, down: String, icon: String)
    -> some View
  {
    if keys[up] != nil || keys[down] != nil {
      VStack(spacing: 8) {
        VStack(spacing: 0) {
          rockerKey(up, "plus")
          Image(systemName: icon).font(.system(size: 13)).foregroundStyle(HouseTheme.secondary)
            .frame(height: tight ? 22 : compact ? 30 : 40)
          rockerKey(down, "minus")
        }.background(HouseTheme.surface.opacity(0.8), in: Capsule())
          .overlay(Capsule().stroke(HouseTheme.border))
        Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(HouseTheme.secondary)
      }.frame(width: 54)
    }
  }
  @ViewBuilder private func rockerKey(_ id: String, _ symbol: String) -> some View {
    if let command = keys[id] {
      Button {
        store.send(command)
      } label: {
        Image(systemName: symbol).font(.system(size: 19, weight: .medium))
          .frame(width: 54, height: tight ? 38 : compact ? 44 : 52).contentShape(Capsule())
      }.accessibilityLabel(RemoteCatalog.label(command)).help(RemoteCatalog.label(command))
    }
  }
  private func tile(_ title: String, icon: String, card: Bool) -> some View {
    VStack(spacing: tight ? 4 : card ? 10 : 7) {
      Image(systemName: icon).font(.system(size: tight ? 16 : card ? 21 : 18)).foregroundStyle(
        HouseTheme.ice)
      Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1)
    }.frame(maxWidth: .infinity).frame(
      height: tight ? (card ? 50 : 42) : card ? (compact ? 70 : 82) : 62
    )
    .background(
      HouseTheme.surface.opacity(card ? 0.8 : 0.4),
      in: RoundedRectangle(cornerRadius: card ? 20 : 16)
    )
    .overlay(RoundedRectangle(cornerRadius: card ? 20 : 16).stroke(HouseTheme.border))
  }
  @ViewBuilder private func shortcut(
    _ id: String, _ title: String, _ icon: String, card: Bool = false
  ) -> some View {
    if let command = keys[id] {
      Button {
        store.send(command)
      } label: {
        tile(title, icon: icon, card: card)
      }
      .accessibilityLabel(RemoteCatalog.label(command)).help(RemoteCatalog.label(command))
    }
  }
  private func panelButton(_ title: String, icon: String, panel selection: Panel) -> some View {
    Button {
      panel = selection
    } label: {
      tile(title, icon: icon, card: true)
    }
    .accessibilityLabel("Abrir \(title.lowercased())")
  }
  private var numberPad: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
      ForEach(1...9, id: \.self) { number in padKey("digit\(number)", title: String(number)) }
      padKey("guide", title: "Guia")
      padKey("digit0", title: "0")
      padKey("last", title: "Último")
    }
  }
  private var mediaPad: some View {
    VStack(spacing: 16) {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
        padKey("rewind", symbol: "backward.fill")
        padKey("play", symbol: "play.fill")
        padKey("fastforward", symbol: "forward.fill")
        padKey("record", symbol: "record.circle")
        padKey("pause", symbol: "pause.fill")
        padKey("stop", symbol: "stop.fill")
      }
      if colorKeys.contains(where: { keys[$0] != nil }) {
        HStack(spacing: 8) {
          ForEach(colorKeys, id: \.self) { id in
            padKey(id, title: RemoteCatalog.label(id))
          }
        }
      }
      padKey("netflix", title: "Netflix")
    }
  }
  @ViewBuilder private func padKey(_ id: String, title: String? = nil, symbol: String? = nil)
    -> some View
  {
    if let command = keys[id] {
      Button {
        store.send(command)
      } label: {
        Group {
          if let symbol {
            Image(systemName: symbol)
          } else {
            Text(title ?? RemoteCatalog.label(command))
          }
        }.font(.system(size: colorKeys.contains(id) ? 11 : 16, weight: .medium))
          .frame(maxWidth: .infinity).frame(height: 48)
          .background(HouseTheme.surface, in: RoundedRectangle(cornerRadius: 14))
          .overlay(RoundedRectangle(cornerRadius: 14).stroke(HouseTheme.border))
      }.accessibilityLabel(RemoteCatalog.label(command)).help(RemoteCatalog.label(command))
        .disabled(store.busy || store.sending)
    }
  }
}
