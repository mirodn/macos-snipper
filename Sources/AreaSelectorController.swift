// Sources/AreaSelectorController.swift
import Cocoa

@MainActor
final class AreaSelectorController {
    private let window: NSWindow
    private let contentView: SelectionView
    private var continuation: CheckedContinuation<NSRect, Never>?
    private var previousPolicy: NSApplication.ActivationPolicy?

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
        window.level = .statusBar              // try .mainMenu if you need stronger focus
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
        // Make sure we are frontmost (helps when running from terminal too)
        previousPolicy = NSApp.activationPolicy()
        #if DEBUG
        _ = NSApp.setActivationPolicy(.regular) // Dock icon while debugging
        #endif
        NSApp.activate(ignoringOtherApps: true)

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.acceptsMouseMovedEvents = true
        window.invalidateCursorRects(for: contentView)
        contentView.window?.makeFirstResponder(contentView)

        // Hide system cursor; our view draws a custom crosshair immediately
        NSCursor.hide()
        contentView.needsDisplay = true

        return await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    private func finish(with rect: NSRect) {
        continuation?.resume(returning: rect)
        continuation = nil

        // Restore system cursor
        NSCursor.unhide()

        #if DEBUG
        if let prev = previousPolicy { _ = NSApp.setActivationPolicy(prev) }
        #endif

        window.orderOut(nil)
    }
}
