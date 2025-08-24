import Cocoa

@MainActor
final class PreCaptureController {
    /// Called from AppDelegate menu or HotkeyManager
    func run() {
        Task { @MainActor in
            await ScreenshotService.shared.captureInteractiveMouseOnly()
        }
    }
}
