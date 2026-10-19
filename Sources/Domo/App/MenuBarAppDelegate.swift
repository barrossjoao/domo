import Cocoa
import SwiftUI

@MainActor
final class MenuBarAppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
  private let store = HouseStore()
  private let updater = AppUpdater()
  private var statusItem: NSStatusItem!
  private let popover = NSPopover()
  private var window: NSWindow?
  private var outsideClickMonitor: Any?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    let existing = NSRunningApplication.runningApplications(
      withBundleIdentifier: "br.automatizehouse.mac"
    )
    .first { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    if existing != nil {
      NSApp.terminate(nil)
      return
    }
    configureMainMenu()
    updater.start()
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = statusItem.button {
      let image = NSImage(systemSymbolName: "house", accessibilityDescription: "Domo")
      image?.isTemplate = true
      button.image = image
      button.setAccessibilityLabel("Domo")
      button.toolTip = "Domo — ar-condicionado e TV"
      button.target = self
      button.action = #selector(togglePopover(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    let visibleHeight = (NSScreen.main?.visibleFrame.height ?? 800) - 60
    popover.behavior = .transient
    popover.delegate = self
    popover.contentViewController = NSHostingController(rootView: content())
    popover.contentSize = NSSize(width: 440, height: max(440, min(700, visibleHeight)))
    let workspace = NSWorkspace.shared.notificationCenter
    workspace.addObserver(
      self, selector: #selector(closePopover), name: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil)
    workspace.addObserver(
      self, selector: #selector(workspaceActivated(_:)),
      name: NSWorkspace.didActivateApplicationNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(closePopover), name: NSApplication.didResignActiveNotification,
      object: NSApp)
    NotificationCenter.default.addObserver(
      self, selector: #selector(closePopover),
      name: NSApplication.didChangeScreenParametersNotification,
      object: NSApp)
    Task { await store.restoreLogin() }
  }
  private func configureMainMenu() {
    // AppKit needs an Edit menu to route keyboard shortcuts to the focused text field.
    let menu = NSMenu()
    let application = NSMenuItem(title: "Domo", action: nil, keyEquivalent: "")
    application.submenu = NSMenu(title: "Domo")
    application.submenu?.addItem(updateMenuItem())
    application.submenu?.addItem(.separator())
    application.submenu?.addItem(
      withTitle: "Sair do Domo", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    menu.addItem(application)

    let edit = NSMenuItem(title: "Editar", action: nil, keyEquivalent: "")
    edit.submenu = NSMenu(title: "Editar")
    edit.submenu?.addItem(
      withTitle: "Recortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    edit.submenu?.addItem(
      withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    edit.submenu?.addItem(
      withTitle: "Colar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    edit.submenu?.addItem(
      withTitle: "Selecionar tudo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    menu.addItem(edit)
    NSApp.mainMenu = menu
  }

  private func content() -> DashboardView {
    DashboardView(
      store: store, updater: updater, openWindow: { [weak self] in self?.openWindow() },
      quit: { NSApp.terminate(nil) })
  }
  @objc private func togglePopover(_ sender: Any?) {
    if NSApp.currentEvent?.type == .rightMouseUp, let button = statusItem.button {
      let menu = NSMenu()
      menu.addItem(
        NSMenuItem(title: "Abrir controles", action: #selector(revealPopover), keyEquivalent: ""))
      menu.addItem(
        NSMenuItem(title: "Abrir em janela", action: #selector(openWindow), keyEquivalent: ""))
      menu.addItem(.separator())
      menu.addItem(
        NSMenuItem(title: "Sair do Domo", action: #selector(quit), keyEquivalent: "q"))
      for item in menu.items { item.target = self }
      menu.insertItem(updateMenuItem(), at: 2)
      menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
    } else if popover.isShown {
      popover.performClose(sender)
    } else {
      revealPopover()
    }
  }
  private func updateMenuItem() -> NSMenuItem {
    let item = NSMenuItem(
      title: "Buscar atualizações…", action: #selector(AppUpdater.checkForUpdates(_:)),
      keyEquivalent: "")
    item.target = updater
    return item
  }
  @objc private func revealPopover() {
    guard let button = statusItem?.button else { return }
    let visibleHeight = (button.window?.screen?.visibleFrame.height ?? 800) - 60
    popover.contentSize = NSSize(width: 440, height: max(440, min(700, visibleHeight)))
    NSApp.activate(ignoringOtherApps: true)
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    popover.contentViewController?.view.window?.makeKey()
    if popover.isShown && outsideClickMonitor == nil {
      outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
        matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
      ) { [weak self] _ in
        Task { @MainActor [weak self] in self?.closePopover() }
      }
    }
  }
  @objc private func workspaceActivated(_ notification: Notification) {
    guard
      let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
        as? NSRunningApplication,
      application.processIdentifier != ProcessInfo.processInfo.processIdentifier
    else { return }
    closePopover()
  }
  @objc private func closePopover() {
    if popover.isShown { popover.performClose(nil) }
  }
  func popoverDidClose(_ notification: Notification) {
    removeOutsideClickMonitor()
  }
  private func removeOutsideClickMonitor() {
    if let monitor = outsideClickMonitor {
      NSEvent.removeMonitor(monitor)
      outsideClickMonitor = nil
    }
  }
  @objc private func openWindow() {
    popover.performClose(nil)
    if window == nil {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 560, height: 780),
        styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered,
        defer: false)
      window.title = "Domo"
      window.minSize = NSSize(width: 440, height: 560)
      window.isReleasedWhenClosed = false
      window.contentViewController = NSHostingController(rootView: content())
      window.setContentSize(NSSize(width: 560, height: 740))
      window.center()
      self.window = window
    }
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
  }
  @objc private func quit() { NSApp.terminate(nil) }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
  func applicationWillTerminate(_ notification: Notification) {
    removeOutsideClickMonitor()
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    NotificationCenter.default.removeObserver(self)
  }
}
