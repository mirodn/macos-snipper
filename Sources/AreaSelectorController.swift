import Cocoa

/// Borderless Overlay-Fenster, das Key/Main werden darf – nötig für Maus-Events stabil.
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
    private var hud: ModeToggleHUD?

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
        // App temporär in den Vordergrund bringen → Panels/Overlays werden zuverlässig gezeigt.
        previousPolicy = NSApp.activationPolicy()
        _ = NSApp.setActivationPolicy(.regular)              // <— immer, nicht nur DEBUG
        NSApp.activate(ignoringOtherApps: true)

        // Overlay anzeigen & Crosshair zeichnen
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.acceptsMouseMovedEvents = true
        contentView.window?.makeFirstResponder(contentView)
        NSCursor.hide()
        contentView.needsDisplay = true

        // HUD anzeigen (oben-zentriert). Klick auf "Full Screen" löst sofort aus.
        hud = ModeToggleHUD { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.cancel() // Overlay/HUD schließen
                await ScreenshotService.shared.captureFullScreen()
            }
        }
        hud?.show()

        return await withCheckedContinuation { cont in
            continuation = cont
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
        NSCursor.unhide()

        hud?.orderOut(nil)
        hud = nil

        // ursprüngliche Aktivierungspolicy wiederherstellen
        if let prev = previousPolicy { _ = NSApp.setActivationPolicy(prev) }

        window.orderOut(nil)
    }
}
