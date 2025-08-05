import Cocoa

/// Presents a transparent overlay window for area selection.
/// Returns the dragged rect via its async `run()` method.
@MainActor
final class AreaSelectorController {
    private let window: NSWindow
    private let contentView: SelectionView
    private var continuation: CheckedContinuation<NSRect, Never>?

    init() {
        // Cover all screens
        let fullFrame = NSScreen.screens
        .map { $0.frame }
        .reduce(NSRect.zero) { $0.union($1) }
        contentView = SelectionView()
        window = NSWindow(
            contentRect: fullFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = contentView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = false
        window.makeKeyAndOrderFront(nil)

        contentView.onSelectionComplete = { [weak self] rect in
            self?.finish(with: rect)
        }
    }

    /// Shows the window, suspends until user completes selection.
    func run() async -> NSRect {
        NSApp.activate(ignoringOtherApps: true)
        return await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    private func finish(with rect: NSRect) {
        continuation?.resume(returning: rect)
        continuation = nil
        window.orderOut(nil)
    }
}
