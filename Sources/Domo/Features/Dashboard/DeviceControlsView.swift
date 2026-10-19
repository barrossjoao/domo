import SwiftUI

struct DeviceControlsView: View {
  @ObservedObject var store: HouseStore
  var compact = false
  var showIllustration = true
  @State private var search = ""
  @State private var showExtras = false

  var body: some View {
    VStack(alignment: .leading, spacing: compact ? 12 : 16) {
      HStack {
        Picker(
          "Controle",
          selection: Binding(
            get: { store.selectedID },
            set: { value in
              search = ""
              showExtras = false
              Task { await store.selectRemote(value) }
            })
        ) {
          ForEach(store.remotes) { Text($0.displayName).tag($0.id) }
        }.labelsHidden().disabled(store.busy || store.sending)
        Button {
          Task { await store.selectRemote(store.selectedID, refresh: true) }
        } label: {
          Image(systemName: "arrow.clockwise")
        }
        .help("Recarregar os comandos").accessibilityLabel("Recarregar comandos").disabled(
          store.busy || store.sending)
        Button("Desconectar", action: store.disconnect).font(.caption).buttonStyle(.borderless)
          .disabled(store.busy || store.sending)
      }
      if let remote = store.remote, !store.isAC && !store.isTV {
        Label(remote.displayName, systemImage: store.isAC ? "snowflake" : "tv").font(
          .title2.weight(.semibold))
      }
      if store.commands.isEmpty && !store.busy {
        Text("Nenhum comando disponível.").foregroundStyle(.secondary)
      }
      if store.isAC {
        ClimateControlView(store: store, compact: compact, showIllustration: showIllustration)
      } else if store.isTV {
        TVRemoteView(store: store, compact: compact, showIllustration: showIllustration)
      } else {
        ForEach(store.powerCommands) { command in commandButton(command.name) }
      }
      if !store.extraCommands.isEmpty {
        Button("Todas as funções (\(store.extraCommands.count))") { showExtras = true }
          .buttonStyle(.borderless)
          .popover(isPresented: $showExtras) {
            ScrollView {
              VStack(alignment: .leading, spacing: 14) {
                TextField("Buscar uma função", text: $search).textFieldStyle(.roundedBorder)
                ForEach(RemoteCatalog.categories, id: \.self) { category in
                  let group = store.extraCommands.filter {
                    RemoteCatalog.category($0.name) == category
                      && (search.isEmpty
                        || RemoteCatalog.label($0.name).localizedCaseInsensitiveContains(search))
                  }
                  if !group.isEmpty {
                    Text(category).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    LazyVGrid(
                      columns: [GridItem(.adaptive(minimum: 115))], alignment: .leading, spacing: 8
                    ) {
                      ForEach(group) { command in
                        commandButton(command.name).font(.caption).disabled(
                          store.busy || store.sending)
                      }
                    }
                  }
                }
              }.padding(16)
            }.frame(width: 380, height: 420)
          }
      }
    }
  }
  private func commandButton(_ name: String) -> some View {
    Button(RemoteCatalog.label(name)) { store.send(name) }.buttonStyle(.bordered).frame(
      maxWidth: .infinity)
  }
}
