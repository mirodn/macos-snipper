import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        HotkeyManager.shared.startListening()
        print("macOS Snipper started – Hotkey: Ctrl+Option+Cmd+S")
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera", accessibilityDescription: "Screenshot")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Take Fullscreen Screenshot", action: #selector(takeScreenshot), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func takeScreenshot() {
        ScreenshotService.shared.captureFullScreen()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
