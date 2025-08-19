import Cocoa

@MainActor
final class PreCaptureController {
    /// Startet direkt die neue Maus-only Interaktion.
    func run() {
        Task { @MainActor in
            await ScreenshotService.shared.captureInteractiveMouseOnly()
        }
    }
}
