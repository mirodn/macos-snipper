import Cocoa

/// Monitors Shift+Control+S globally.
@MainActor
final class HotkeyManager {
    static let shared = HotkeyManager()

    func startGlobalHotkeyMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard
                event.modifierFlags.contains([.control, .shift]),
                event.charactersIgnoringModifiers?.lowercased() == "s"
            else { return }

            Task { @MainActor in
                await ScreenshotService.shared.captureInteractiveMouseOnly()
            }
        }
    }
}
