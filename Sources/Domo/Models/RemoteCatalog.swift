enum RemoteCatalog {
  static let modes = [
    0: "Resfriar", 1: "Aquecer", 2: "Automático", 3: "Ventilar", 4: "Desumidificar",
  ]
  static let fans = [0: "Automática", 1: "Baixa", 2: "Média", 3: "Alta"]
  static let labels: [String: String] = [
    "ad": "Audiodescrição",
    "app": "Aplicativos",
    "aspect": "Proporção da imagem",
    "av": "AV",
    "av1": "AV 1",
    "av2": "AV 2",
    "av3": "AV 3",
    "avmode": "Modo AV",
    "back": "Voltar",
    "blue": "Azul",
    "bs": "BS",
    "caption": "Legendas",
    "changesound": "Alternar áudio",
    "channeldown": "Canal anterior",
    "channelup": "Próximo canal",
    "chdown": "Canal anterior",
    "chup": "Próximo canal",
    "clear": "Limpar",
    "component1": "Componente 1",
    "component2": "Componente 2",
    "cs": "CS",
    "da": "Digital / analógico",
    "dashlist": "Traço / lista",
    "display": "Visor",
    "dlinkeddata": "Dados interativos",
    "down": "Baixo",
    "dualchannel": "Áudio duplo",
    "energysave": "Economia de energia",
    "energysaving": "Economia de energia",
    "exit": "Sair",
    "fastforward": "Avançar",
    "favmarkcharnum": "Favoritos / marcar",
    "favorite": "Favoritos",
    "favorites": "Favoritos",
    "flashback": "Voltar ao anterior",
    "green": "Verde",
    "guide": "Guia de programação",
    "guides": "Guia",
    "hdmi1": "HDMI 1",
    "hdmi2": "HDMI 2",
    "hdmi3": "HDMI 3",
    "hdmi4": "HDMI 4",
    "home": "Início",
    "homepage": "Início",
    "info": "Informações",
    "input": "Fonte de entrada",
    "inputrgbpc": "Entrada RGB / PC",
    "inputtv": "Entrada de TV",
    "languageselection": "Idioma",
    "last": "Último canal",
    "left": "Esquerda",
    "light": "Luz do visor",
    "list": "Lista",
    "livetv": "TV ao vivo",
    "lld": "LLD",
    "menu": "Menu",
    "mute": "Silenciar",
    "navigatedown": "Baixo",
    "navigateleft": "Esquerda",
    "navigateright": "Direita",
    "navigateup": "Cima",
    "netflix": "Netflix",
    "networktv": "TV pela rede",
    "ok": "OK",
    "pause": "Pausar",
    "picturemode": "Modo de imagem",
    "pip": "Imagem sobre imagem",
    "play": "Reproduzir",
    "position": "Posição da imagem",
    "premium": "Premium",
    "previous": "Anterior",
    "programguide": "Guia de programação",
    "programlist": "Lista de canais",
    "qmenu": "Menu rápido",
    "ratio16x9": "Proporção 16:9",
    "record": "Gravar",
    "red": "Vermelho",
    "rewind": "Retroceder",
    "right": "Direita",
    "scale": "Escala da imagem",
    "screensize": "Tamanho da tela",
    "settings": "Configurações",
    "shortcutmenu": "Menu rápido",
    "simplink": "Simplink",
    "size": "Tamanho da imagem",
    "sleep": "Dormir",
    "soundmode": "Modo de som",
    "source": "Fonte de entrada",
    "stop": "Parar",
    "submenu": "Submenu",
    "subtitle": "Legendas",
    "swing": "Oscilação",
    "teletext": "Teletexto",
    "timer": "Timer",
    "timing": "Timer",
    "tool": "Ferramentas",
    "turbo": "Turbo",
    "tv": "TV",
    "tvproglist": "Lista de canais",
    "tvrad": "TV / rádio",
    "tvradio": "TV / rádio",
    "tvvid": "TV / vídeo",
    "up": "Cima",
    "voldown": "Diminuir volume",
    "volumedown": "Diminuir volume",
    "volumeup": "Aumentar volume",
    "volup": "Aumentar volume",
    "yahoo": "Yahoo",
    "yellow": "Amarelo",
  ]
  static let aliases: [String: [String]] = [
    "back": ["back", "return"],
    "blue": ["blue"],
    "channeldown": ["channeldown", "chdown"],
    "channelup": ["channelup", "chup"],
    "digit0": ["channel0", "0"],
    "digit1": ["channel1", "1"],
    "digit2": ["channel2", "2"],
    "digit3": ["channel3", "3"],
    "digit4": ["channel4", "4"],
    "digit5": ["channel5", "5"],
    "digit6": ["channel6", "6"],
    "digit7": ["channel7", "7"],
    "digit8": ["channel8", "8"],
    "digit9": ["channel9", "9"],
    "down": ["navigatedown", "down"],
    "fastforward": ["fastforward"],
    "green": ["green"],
    "guide": ["guide", "programguide", "guides"],
    "home": ["homepage", "home"],
    "input": ["input", "source"],
    "last": ["last"],
    "left": ["navigateleft", "left"],
    "menu": ["menu"],
    "mute": ["mute"],
    "netflix": ["netflix"],
    "ok": ["ok", "confirm", "enter"],
    "pause": ["pause"],
    "play": ["play"],
    "power": ["onoff", "power", "powertoggle"],
    "record": ["record"],
    "red": ["red"],
    "rewind": ["rewind"],
    "right": ["navigateright", "right"],
    "settings": ["settings", "tool"],
    "stop": ["stop"],
    "up": ["navigateup", "up"],
    "volumedown": ["volumedown", "voldown"],
    "volumeup": ["volumeup", "volup"],
    "yellow": ["yellow"],
  ]

  static func normalize(_ name: String) -> String {
    name.lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
  }
  static func power(_ name: String) -> String? {
    switch normalize(name) {
    case "poweron", "on", "ligar": return "Ligar"
    case "poweroff", "off", "desligar": return "Desligar"
    case "onoff", "power", "powertoggle": return "Ligar / desligar"
    default: return nil
    }
  }
  static func label(_ name: String) -> String {
    if let power = power(name) { return power }
    if let c = ClimateChoice(name) {
      var parts = [modes[c.mode]!]
      if let temp = c.temp { parts.append("\(temp) °C") }
      parts.append("Ventilação " + fans[c.fan]!.lowercased())
      return parts.joined(separator: " · ")
    }
    let key = normalize(name)
    if key.hasPrefix("channel"), let number = Int(key.dropFirst(7)) { return String(number) }
    if name == "brightness+" { return "Aumentar brilho" }
    if name == "brightness-" { return "Diminuir brilho" }
    return labels[key] ?? name
  }
  static func tvKeys(_ names: [String]) -> [String: String] {
    var result: [String: String] = [:]
    for (id, aliases) in aliases {
      result[id] = aliases.compactMap { alias in names.first { normalize($0) == alias } }.first
    }
    return result
  }
  static let categories = [
    "Entradas", "Imagem e som", "Canais e transmissão", "Reprodução", "Mais funções",
  ]
  static func category(_ name: String) -> String {
    let key = normalize(name)
    if ["hdmi", "av", "input", "component", "tvvid"].contains(where: key.hasPrefix) || key == "da" {
      return "Entradas"
    }
    if [
      "picture", "sound", "audio", "brightness", "aspect", "size", "scale", "position", "ratio",
      "pip", "3d", "display", "energy", "changesound", "dualchannel",
    ].contains(where: key.contains) {
      return "Imagem e som"
    }
    if ["channel", "program", "guide", "caption", "subtitle", "teletext", "fav", "tvrad", "livetv"]
      .contains(where: key.contains) || key == "tv"
    {
      return "Canais e transmissão"
    }
    if ["play", "pause", "stop", "record", "previous", "forward", "rewind"].contains(
      where: key.contains)
    {
      return "Reprodução"
    }
    return "Mais funções"
  }
}
