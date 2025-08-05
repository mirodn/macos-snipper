import Cocoa

/// Monitors Shift+Control+S globally (development mode, no Accessibility rights).
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    /// Adds a global key‐down monitor for Shift + Ctrl + S.
    func startGlobalHotkeyMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard
                event.modifierFlags.contains([.control, .shift]),
                event.charactersIgnoringModifiers?.lowercased() == "s"
            else { return }

            Task { @MainActor in
                switch UserSettings.captureMode {
                case .full:
                    await ScreenshotService.shared.captureFullScreen()
                case .area:
                    await ScreenshotService.shared.captureAreaSelection()
                }
            }
        }
    }
}
