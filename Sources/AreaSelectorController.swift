// Sources/AreaSelectorController.swift
import Cocoa

@MainActor
final class AreaSelectorController {
    private let window: NSWindow
    private let contentView: SelectionView
    private var continuation: CheckedContinuation<NSRect, Never>?
    private var previousPolicy: NSApplication.ActivationPolicy?
    private var hud: ModeToggleHUD?

    init() {
        let fullFrame = NSScreen.screens.map(\.frame).reduce(NSRect.zero) { $0.union($1) }
        contentView = SelectionView()

        window = NSWindow(
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
        window.makeKeyAndOrderFront(nil)

        contentView.onSelectionComplete = { [weak self] rect in
            self?.finish(with: rect)
        }
    }

    func run() async -> NSRect {
        previousPolicy = NSApp.activationPolicy()
        #if DEBUG
        _ = NSApp.setActivationPolicy(.regular)
        #endif
        NSApp.activate(ignoringOtherApps: true)

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.acceptsMouseMovedEvents = true
        window.invalidateCursorRects(for: contentView)
        contentView.window?.makeFirstResponder(contentView)

        // System-Cursor ausblenden (Crosshair zeichnest du selbst)
        NSCursor.hide()
        contentView.needsDisplay = true

        // HUD einblenden (liegt über dem Overlay, nimmt Maus an)
        hud = ModeToggleHUD { [weak self] newMode in
            Task { @MainActor in
                if newMode == .full {
                    // Sofort zu Full wechseln
                    await ScreenshotService.shared.captureFullScreen()
                    self?.cancel()
                }
            }
        }
        // Auf Screen mit Maus zeigen
        let mouse = NSEvent.mouseLocation
        let target = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        hud?.show(on: target)

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

        #if DEBUG
        if let prev = previousPolicy { _ = NSApp.setActivationPolicy(prev) }
        #endif

        hud?.orderOut(nil)
        hud = nil
        window.orderOut(nil)
    }

    // Optional: HUD relativ zur Auswahl verschieben (callen, wenn du dein Rect kennst)
    func repositionHUD(above rectInScreen: CGRect, padding: CGFloat = 8) {
        hud?.reposition(above: rectInScreen, padding: padding)
    }
}
