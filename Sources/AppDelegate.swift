import Cocoa

/// Application delegate manages the status‐bar item and responds to menu actions.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var preferencesWindow: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configureStatusItem()
        HotkeyManager.shared.startGlobalHotkeyMonitor()
    }

    private func configureStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Screenshot")
        statusItem.button?.toolTip = "macOS Snipper"

        let menu = NSMenu()
        menu.addItem(.init(title: "Take Screenshot", action: #selector(takeScreenshot), keyEquivalent: "s"))
        menu.addItem(.init(title: "Preferences…", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(.init(title: "About Snipper", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(.init(title: "Quit Snipper", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func takeScreenshot() {
        Task { @MainActor in
            switch UserSettings.captureMode {
            case .full:
                await ScreenshotService.shared.captureFullScreen()
            case .area:
                await ScreenshotService.shared.captureAreaSelection()
            }
        }
    }

    @objc private func showPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController()
        }
        preferencesWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "macOS Snipper v1.0"
        alert.informativeText = "Lightweight, open-source screenshot tool for macOS."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
