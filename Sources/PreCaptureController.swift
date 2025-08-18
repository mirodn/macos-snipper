import Cocoa

/// Unsichtbares, borderloses Fenster, das Key werden darf.
final class KeyCatcherWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class PreCaptureController {
    private let keyWindow: KeyCatcherWindow
    private var hud: ModeToggleHUD?
    private var localKeyMonitor: Any?
    private var previousPolicy: NSApplication.ActivationPolicy?

    init() {
        let unionFrame = NSScreen.screens.map(\.frame).reduce(NSRect.zero) { $0.union($1) }
        keyWindow = KeyCatcherWindow(
            contentRect: unionFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        keyWindow.isOpaque = false
        keyWindow.backgroundColor = .clear
        keyWindow.level = .mainMenu                // unter HUD (.screenSaver), über Apps
        keyWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        keyWindow.ignoresMouseEvents = true        // nur Tastatur
        keyWindow.hasShadow = false
        keyWindow.isReleasedWhenClosed = false
    }

    func run() {
        // App aktivieren (für `swift run`/VSCode & generell)
        previousPolicy = NSApp.activationPolicy()
        #if DEBUG
        NSApp.setActivationPolicy(.regular)        // nur während Vorab-HUD in DEBUG
        #endif
        NSApp.activate(ignoringOtherApps: true)

        keyWindow.makeKeyAndOrderFront(nil)
        keyWindow.orderFrontRegardless()

        // HUD anzeigen
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        hud = ModeToggleHUD { _ in /* Enter löst aus */ }
        hud?.show(on: screen)

        // Lokaler Key-Monitor (sauberster Weg)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            guard let self else { return ev }
            return self.handleKey(ev) ? nil : ev
        }
    }

    private func handleKey(_ e: NSEvent) -> Bool {
        switch e.keyCode {
        case 53: // Esc
            cleanup()
            return true
        case 36, 76: // Return / Enter
            Task { @MainActor in
                let mode = UserSettings.captureMode
                cleanup()
                switch mode {
                case .full:
                    await ScreenshotService.shared.captureFullScreen()
                case .area:
                    await ScreenshotService.shared.captureAreaSelection()
                }
            }
            return true
        case 123: // ←
            UserSettings.captureMode = .area
            return true
        case 124: // →
            UserSettings.captureMode = .full
            return true
        default:
            return false
        }
    }

    private func cleanup() {
        if let m = localKeyMonitor { NSEvent.removeMonitor(m) }
        localKeyMonitor = nil

        hud?.orderOut(nil)
        hud = nil

        keyWindow.orderOut(nil)

        // Policy zurückstellen (nur relevant in DEBUG)
        #if DEBUG
        if let prev = previousPolicy { NSApp.setActivationPolicy(prev) }
        #endif
    }
}
