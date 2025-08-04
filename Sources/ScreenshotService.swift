// ScreenshotService.swift

import Cocoa
import AudioToolbox

// MARK: - ScreenCapturing Protocol

/// Abstraction for screen capture so we can inject a mock in tests.
protocol ScreenCapturing {
    func capture() -> CGImage?
}

/// Default implementation that captures the main display.
struct DefaultCapturer: ScreenCapturing {
    func capture() -> CGImage? {
        CGDisplayCreateImage(CGMainDisplayID())
    }
}

// MARK: - ScreenshotService

class ScreenshotService {
    /// Singleton instance for production usage.
    static let shared = ScreenshotService()

    private let capturer: ScreenCapturing

    /// Designated initializer with dependency injection.
    /// Uses DefaultCapturer by default.
    init(capturer: ScreenCapturing = DefaultCapturer()) {
        self.capturer = capturer
    }

    /// Captures the full screen, copies it to the clipboard,
    /// saves it to disk, and plays a shutter sound.
    func captureFullScreen() {
        guard let cgImage = capturer.capture() else {
            print("Screenshot failed: no image returned")
            return
        }

        let nsImage = NSImage(cgImage: cgImage, size: .zero)

        copyToClipboard(nsImage)
        saveScreenshot(nsImage)
        AudioServicesPlaySystemSound(1108)

        print("Screenshot copied to clipboard and saved")
    }

    /// Extracts PNG data from the captured screen image.
    /// Useful for unit testing without file I/O.
    func makePNGData() -> Data? {
        guard let cgImage = capturer.capture() else {
            return nil
        }

        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        guard
            let tiffData = nsImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return nil
        }

        return pngData
    }

    // MARK: - Private Helpers

    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private func saveScreenshot(_ image: NSImage) {
        let saveFolder = UserSettings.savePath

        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: saveFolder.path) {
            do {
                try FileManager.default.createDirectory(
                    at: saveFolder,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("Failed to create save folder: \(error)")
                return
            }
        }

        // Build filename with timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Screenshot_\(formatter.string(from: Date())).png"
        let fileURL = saveFolder.appendingPathComponent(filename)

        // Convert image to PNG and write to disk
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            print("Failed to convert image to PNG")
            return
        }

        do {
            try pngData.write(to: fileURL)
            print("Screenshot saved at \(fileURL.path)")
        } catch {
            print("Failed to save screenshot: \(error)")
        }
    }
}
