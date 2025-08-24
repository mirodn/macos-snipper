import Cocoa

/// Borderless overlay window
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
        // Cover all screens
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
        // Temporarily bring the app to the foreground → ensures overlays/panels are shown reliably
        previousPolicy = NSApp.activationPolicy()
        _ = NSApp.setActivationPolicy(.regular)              // <— always, not only in DEBUG
        NSApp.activate(ignoringOtherApps: true)

        // Show overlay & draw crosshair
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.acceptsMouseMovedEvents = true
        contentView.window?.makeFirstResponder(contentView)
        NSCursor.hide()
        contentView.needsDisplay = true

        // Show HUD (centered at top). Clicking "Full Screen" triggers immediately.
        hud = ModeToggleHUD { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.cancel() // Close overlay/HUD
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

        // Restore the previous activation policy
        if let prev = previousPolicy { _ = NSApp.setActivationPolicy(prev) }

        window.orderOut(nil)
    }
}
