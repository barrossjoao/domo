import AppKit
import Combine
import Sparkle

@MainActor
final class AppUpdater: NSObject, ObservableObject, NSMenuItemValidation {
  @Published private(set) var canCheckForUpdates = false
  private let controller = SPUStandardUpdaterController(
    startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

  override init() {
    super.init()
    controller.updater.publisher(for: \.canCheckForUpdates)
      .receive(on: RunLoop.main)
      .assign(to: &$canCheckForUpdates)
  }

  func start() {
    controller.startUpdater()
  }

  @objc func checkForUpdates(_ sender: Any? = nil) {
    guard controller.updater.canCheckForUpdates else { return }
    NSApp.activate(ignoringOtherApps: true)
    controller.checkForUpdates(sender)
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    controller.updater.canCheckForUpdates
  }
}
