import Combine
import Foundation

@MainActor
final class HouseStore: ObservableObject {
  @Published var connected = false
  @Published private(set) var restoring = false
  @Published var remotes: [HouseRemote] = []
  @Published var selectedID = ""
  @Published var commands: [IRCommand] = []
  @Published var busy = false
  @Published var sending = false
  @Published var message = ""
  @Published var hasError = false
  @Published var mode = 0
  @Published var fan = 0
  @Published var temperature = 23
  // shortcut: IR has no state feedback; remember accepted app commands until disconnect.
  @Published private var climatePowerByRemote: [String: Bool] = [:]
  private let client: PositivoClient
  private var cache: [String: [IRCommand]] = [:]
  private var pending: (IRCommand, HouseRemote)?

  init(client: PositivoClient = PositivoClient()) { self.client = client }
  var hasSavedLogin: Bool { client.hasSavedLogin }
  var remote: HouseRemote? { remotes.first { $0.id == selectedID } }
  var names: [String] { commands.map(\.name) }
  var climate: [ClimateChoice] { names.compactMap(ClimateChoice.init) }
  var isAC: Bool { !climate.isEmpty }
  var isTV: Bool {
    !isAC
      && (remote?.name.range(of: "tv|televis", options: [.regularExpression, .caseInsensitive])
        != nil || tvKeys["up"] != nil)
  }
  var tvKeys: [String: String] { RemoteCatalog.tvKeys(names) }
  var modes: [Int] { Array(Set(climate.map(\.mode))).sorted() }
  var fans: [Int] { Array(Set(climate.filter { $0.mode == mode }.map(\.fan))).sorted() }
  var temperatures: [Int] {
    Array(Set(climate.filter { $0.mode == mode && $0.fan == fan }.compactMap(\.temp))).sorted()
  }
  var currentCommand: IRCommand? {
    let choice =
      climate.first { $0.mode == mode && $0.fan == fan && $0.temp == temperature }
      ?? climate.first { $0.mode == mode && $0.fan == fan && $0.temp == nil }
    return commands.first { $0.name == choice?.name }
  }
  var powerCommands: [IRCommand] { commands.filter { RemoteCatalog.power($0.name) != nil } }
  var climatePowerCommand: IRCommand? {
    let commands = powerCommands
    if let toggle = commands.first(where: { RemoteCatalog.power($0.name) == "Ligar / desligar" }) {
      return toggle
    }
    let action = climatePowerByRemote[selectedID] == true ? "Desligar" : "Ligar"
    return commands.first { RemoteCatalog.power($0.name) == action } ?? commands.first
  }
  var extraCommands: [IRCommand] {
    let used = Set(tvKeys.values)
    return commands.filter {
      ClimateChoice($0.name) == nil
        && (isTV ? !used.contains($0.name) : RemoteCatalog.power($0.name) == nil)
    }
  }
  func status(_ text: String, error: Bool = false) {
    message = text
    hasError = error
  }
  private func errorText(_ error: Error) -> String {
    if error is URLError {
      return "Não foi possível acessar a nuvem Positivo. Confira a internet e tente novamente."
    }
    return error.localizedDescription
  }
  func connect(email: String, password: String) async {
    guard !busy && !sending else { return }
    busy = true
    status("Conectando à Positivo…")
    defer { busy = false }
    do {
      await loadRemotes(try await client.connect(email: email, password: password))
      if connected && !hasError, let warning = client.persistenceWarning {
        status(warning, error: true)
      }
    } catch { showError(error) }
  }

  func restoreLogin() async {
    guard !busy && !sending && !connected else { return }
    busy = true
    restoring = true
    status("Reconectando à sua casa…")
    defer {
      busy = false
      restoring = false
    }
    do {
      guard let restored = try await client.restoreConnection() else {
        status("")
        return
      }
      await loadRemotes(restored)
      if connected && !hasError, let warning = client.persistenceWarning {
        status(warning, error: true)
      }
    } catch { showError(error) }
  }

  private func loadRemotes(_ values: [HouseRemote]) async {
    remotes = values
    connected = true
    cache.removeAll()
    climatePowerByRemote.removeAll()
    if let first = remotes.first(where: {
      $0.name.range(
        of: "consul|condicionado|air conditioning", options: [.regularExpression, .caseInsensitive])
        != nil
    }) ?? remotes.first {
      await selectRemote(first.id)
    } else {
      status("Nenhum controle encontrado nesta conta. Confira o aplicativo Positivo.", error: true)
    }
  }

  private func showError(_ error: Error) {
    if let error = error as? PositivoError, error.requiresLogin {
      connected = false
      commands = []
      remotes = []
      cache.removeAll()
      climatePowerByRemote.removeAll()
      pending = nil
    }
    status(errorText(error), error: true)
  }
  func selectRemote(_ id: String, refresh: Bool = false) async {
    guard !sending, let remote = remotes.first(where: { $0.id == id }) else { return }
    busy = true
    selectedID = id
    commands = []
    status("Consultando o controle…")
    defer { busy = false }
    do {
      let keys: [IRCommand]
      if !refresh, let cached = cache[id] {
        keys = cached
      } else {
        keys = try await client.commands(for: remote)
        cache[id] = keys
      }
      commands = keys
      mode = modes.first ?? 0
      fan = fans.first ?? 0
      temperature = 23
      normalizeTemperature()
      status(
        keys.isEmpty ? "Nenhum comando disponível neste controle." : "Controle pronto.",
        error: keys.isEmpty)
    } catch { showError(error) }
  }
  func disconnect() {
    guard !busy && !sending else { return }
    var removalFailed = false
    do { try client.disconnect() } catch { removalFailed = true }
    connected = false
    commands = []
    remotes = []
    cache.removeAll()
    climatePowerByRemote.removeAll()
    pending = nil
    selectedID = ""
    status(
      removalFailed
        ? "Conta desconectada e reconexão automática desativada. O macOS não permitiu apagar o item do Chaves."
        : "Conta desconectada. O acesso salvo foi removido.", error: removalFailed)
  }
  private func normalizeTemperature() {
    let values = temperatures
    if !values.isEmpty, !values.contains(temperature) {
      temperature = values.min(by: { abs($0 - temperature) < abs($1 - temperature) })!
    }
  }
  func changeMode(_ value: Int) {
    guard !busy, modes.contains(value) else { return }
    mode = value
    if !fans.contains(fan) { fan = fans.first ?? 0 }
    normalizeTemperature()
    applySelection()
  }
  func changeFan(_ value: Int) {
    guard !busy, fans.contains(value) else { return }
    fan = value
    normalizeTemperature()
    applySelection()
  }
  func stepTemperature(_ step: Int) {
    let values = temperatures
    guard !busy, let index = values.firstIndex(of: temperature),
      values.indices.contains(index + step)
    else { return }
    setTemperature(values[index + step])
  }
  func setTemperature(_ value: Int) {
    guard !busy, value != temperature, temperatures.contains(value) else { return }
    temperature = value
    applySelection()
  }
  private func applySelection() { if let command = currentCommand { send(command.name) } }
  private func rememberClimatePower(_ name: String, remoteID: String) {
    guard isAC else { return }
    switch RemoteCatalog.power(name) {
    case "Ligar": climatePowerByRemote[remoteID] = true
    case "Desligar": climatePowerByRemote[remoteID] = false
    case "Ligar / desligar":
      climatePowerByRemote[remoteID] = !(climatePowerByRemote[remoteID] ?? false)
    default:
      if ClimateChoice(name) != nil { climatePowerByRemote[remoteID] = true }
    }
  }
  func send(_ name: String) {
    guard !busy, let remote = remote, let command = commands.first(where: { $0.name == name })
    else { return }
    pending = (command, remote)
    guard !sending else { return }
    sending = true
    Task {
      defer { sending = false }
      while let next = pending {
        pending = nil
        status("Enviando: " + RemoteCatalog.label(next.0.name) + "…")
        do {
          try await client.send(next.0, to: next.1)
          rememberClimatePower(next.0.name, remoteID: next.1.id)
          if let warning = client.persistenceWarning {
            status(warning, error: true)
          } else {
            status("Enviado: " + RemoteCatalog.label(next.0.name))
          }
        } catch { showError(error) }
      }
    }
  }
}
