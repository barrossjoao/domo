import SwiftUI

struct DashboardView: View {
  @ObservedObject var store: HouseStore
  let openWindow: () -> Void
  let quit: () -> Void
  @State private var showStatus = false

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        HStack {
          Image(systemName: "house.fill").foregroundStyle(HouseTheme.ice)
          Text("Domo").font(.headline)
          Spacer()
          if store.connected && store.hasError {
            Button {
              showStatus = true
            } label: {
              Image(systemName: "exclamationmark.circle.fill").foregroundStyle(HouseTheme.ice)
            }.buttonStyle(.borderless).help(store.message)
              .accessibilityLabel("Atenção: " + store.message)
              .popover(isPresented: $showStatus) {
                Text(store.message).font(.callout).padding(16).frame(width: 300)
              }
          }
          Menu {
            Text(
              "Versão \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")"
            )
            Divider()
            Button("Abrir em janela", action: openWindow)
            Divider()
            Button("Sair do Domo", action: quit).keyboardShortcut("q")
          } label: {
            Image(systemName: "ellipsis.circle").accessibilityLabel("Opções do aplicativo")
          }
          .menuStyle(.borderlessButton).frame(width: 24)
        }.padding(16)
        Divider()
        if store.connected && (store.isAC || store.isTV) {
          panelContent(
            compact: geometry.size.height < 690, showIllustration: geometry.size.height >= 560
          )
          .frame(maxHeight: .infinity, alignment: .top)
        } else {
          ScrollView {
            panelContent(compact: geometry.size.height < 690, showIllustration: true)
          }
        }
      }
    }
    .frame(minWidth: 400, minHeight: 420)
    .background(HouseTheme.backdrop)
    .foregroundStyle(.white)
    .tint(HouseTheme.blue)
    .preferredColorScheme(.dark)
  }
  private func panelContent(compact: Bool, showIllustration: Bool) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      if store.restoring {
        VStack(spacing: 16) {
          ProgressView().controlSize(.large)
          Text("Reconectando à sua casa…").font(.title3.weight(.medium))
          Text("Usando o acesso salvo no Chaves do macOS.")
            .font(.subheadline).foregroundStyle(HouseTheme.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 60)
      } else if store.connected {
        DeviceControlsView(store: store, compact: compact, showIllustration: showIllustration)
      } else {
        LoginView(store: store)
      }
      if !store.connected && !store.message.isEmpty && !store.restoring {
        HStack(alignment: .top, spacing: 8) {
          if store.busy || store.sending {
            ProgressView().controlSize(.small)
          } else {
            Image(systemName: store.hasError ? "exclamationmark.circle" : "checkmark.circle")
          }
          Text(store.message).font(.caption).textSelection(.enabled)
        }.foregroundStyle(HouseTheme.secondary)
          .padding(12).frame(maxWidth: .infinity, alignment: .leading)
          .background(HouseTheme.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
      }
    }.padding(16)
  }

}
