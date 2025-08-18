import Cocoa

/// Borderless Overlay-Fenster, das Key/Main werden darf – nötig für Tastatur.
final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AreaSelectorController {
    private let window: OverlayWindow
    private let contentView: SelectionView
    private var continuation: CheckedContinuation<NSRect, Never>?
    private var previousPolicy: NSApplication.ActivationPolicy?
    private var localKeyMonitor: Any?

    init() {
        let fullFrame = NSScreen.screens.map(\.frame).reduce(NSRect.zero) { $0.union($1) }
        contentView = SelectionView()

        window = OverlayWindow(
            contentRect: fullFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.hasShadow = false
        window.contentView = contentView
        window.initialFirstResponder = contentView

        contentView.onSelectionComplete = { [weak self] rect in
            self?.finish(with: rect)
        }
    }

    func run() async -> NSRect {
        // App wirklich in den Vordergrund holen (wichtig für Tastatur)
        previousPolicy = NSApp.activationPolicy()
        #if DEBUG
        _ = NSApp.setActivationPolicy(.regular) // nur Debug/`swift run`, Release bleibt accessory
        #endif
        NSApp.activate(ignoringOtherApps: true)

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.acceptsMouseMovedEvents = true
        window.invalidateCursorRects(for: contentView)
        contentView.window?.makeFirstResponder(contentView)

        // System-Cursor ausblenden (falls du Crosshair zeichnest)
        NSCursor.hide()
        contentView.needsDisplay = true

        // ←/→/Enter/Esc abfangen (nur solange Overlay aktiv)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            guard let self = self else { return ev }
            return self.handleKey(ev) ? nil : ev
        }

        return await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    private func handleKey(_ e: NSEvent) -> Bool {
        switch e.keyCode {
        case 53: // Esc → Abbruch
            cancel()
            return true

        case 36, 76: // Return/Enter
            let mode = UserSettings.captureMode   // bei dir ggf. anders benannt
            if mode == .full {
                Task { @MainActor in
                    await ScreenshotService.shared.captureFullScreen()
                    cancel()
                }
            } else {
                if let r = contentView.currentSelectionRect, r.width > 0, r.height > 0 {
                    finish(with: r)
                } else {
                    NSSound.beep() // erst ziehen, dann Enter
                }
            }
            return true

        case 123: // ←  → Selection/Area
            UserSettings.captureMode = .area
            return true

        case 124: // →  → Full Screen
            UserSettings.captureMode = .full
            return true

        default:
            return false
        }
    }

    private func finish(with rect: NSRect) {
        continuation?.resume(returning: rect)
        cleanup()
    }

    private func cancel() {
        continuation?.resume(returning: .zero)
        cleanup()
    }

    private func cleanup() {
        continuation = nil
        if let m = localKeyMonitor { NSEvent.removeMonitor(m) }
        localKeyMonitor = nil

        NSCursor.unhide()
        #if DEBUG
        if let prev = previousPolicy { _ = NSApp.setActivationPolicy(prev) }
        #endif

        window.orderOut(nil)
    }
}
