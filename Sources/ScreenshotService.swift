import Cocoa
import AudioToolbox
import ScreenCaptureKit

// MARK: – Dependency Protocols

/// Allows injecting a CGImage capture provider (unit tests).
protocol ScreenCapturing {
    func captureMainDisplay() -> CGImage?
}

struct DefaultCapturer: ScreenCapturing {
    func captureMainDisplay() -> CGImage? {
        CGDisplayCreateImage(CGMainDisplayID())
    }
}

/// Allows injecting sound playback (unit tests).
protocol SoundPlaying {
    func play(_ systemSoundID: SystemSoundID)
}

struct DefaultSoundPlayer: SoundPlaying {
    func play(_ systemSoundID: SystemSoundID) {
        AudioServicesPlaySystemSound(systemSoundID)
    }
}

// MARK: – ScreenshotService

@MainActor
final class ScreenshotService {
    static let shared = ScreenshotService()

    private let capturer: ScreenCapturing
    private let soundPlayer: SoundPlaying

    private init(
        capturer: ScreenCapturing = DefaultCapturer(),
        soundPlayer: SoundPlaying = DefaultSoundPlayer()
    ) {
        self.capturer    = capturer
        self.soundPlayer = soundPlayer
    }

    /// Generates PNG data of the main display (for unit tests).
    func makePNGData() -> Data? {
        guard let cgImage = capturer.captureMainDisplay() else { return nil }
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        guard
            let tiff = nsImage.tiffRepresentation,
            let rep  = NSBitmapImageRep(data: tiff),
            let png  = rep.representation(using: .png, properties: [:])
        else {
            return nil
        }
        return png
    }

    // MARK: Public API

    /// Captures the entire main display.
    func captureFullScreen() async {
        if #available(macOS 15, *) {
            guard await ensurePermission() else {
                print("Screen-capture permission denied")
                return
            }
            guard let screen = NSScreen.main else {
                print("No main screen available")
                return
            }
            if let shot = await captureRegion(screen.frame) {
                finalize(shot)
            } else {
                print("ScreenCaptureKit full-screen failed")
            }
        } else {
            // Legacy path for macOS 14.x
            guard let cg = capturer.captureMainDisplay() else {
                print("Legacy CGDisplayCreateImage failed")
                return
            }
            finalize(NSImage(cgImage: cg, size: .zero))
        }
    }

    /// Lets the user drag out a rectangle, then captures that area.
    func captureAreaSelection() async {
        guard #available(macOS 15, *) else {
            print("Area selection requires macOS 15+")
            return
        }
        guard await ensurePermission() else {
            print("Screen-capture permission denied")
            return
        }

        let selector = AreaSelectorController()
        let rect     = await selector.run()
        if let shot = await captureRegion(rect) {
            finalize(shot)
        } else {
            print("ScreenCaptureKit area selection failed")
        }
    }

    // MARK: – Internal Helpers

    private func finalize(_ image: NSImage) {
        copyToClipboard(image)
        saveToDisk(image)
        soundPlayer.play(1108)
        print("Screenshot saved")
    }

    private func copyToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    private func saveToDisk(_ image: NSImage) {
        let folder = UserSettings.savePath
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        let formatter = DateFormatter()
        formatter.timeZone   = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Screenshot_\(formatter.string(from: Date())).png"
        let url      = folder.appendingPathComponent(filename)

        guard
            let tiff = image.tiffRepresentation,
            let rep  = NSBitmapImageRep(data: tiff),
            let png  = rep.representation(using: .png, properties: [:])
        else {
            print("Failed to convert image to PNG")
            return
        }

        do {
            try png.write(to: url)
        } catch {
            print("Write error:", error)
        }
    }

    // MARK: – ScreenCaptureKit Integration

    @available(macOS 15, *)
    private func captureRegion(_ rect: NSRect) async -> NSImage? {
        guard
            let screen = NSScreen.screens.first(where: { $0.frame.contains(rect.origin) }),
            let did    = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
            let share  = try? await SCShareableContent.current
        else {
            return nil
        }

        let myPID = NSRunningApplication.current.processIdentifier
        let meApp = (try? await share.applications)?.first { $0.processID == myPID }

        guard let scDisplay = share.displays.first(where: { $0.displayID == did }) else {
            return nil
        }

        let filter = SCContentFilter(display: scDisplay, excludingApplications: meApp.map { [$0] } ?? [], exceptingWindows: [])

        // Convert to ScreenCaptureKit coords
        let maxY = screen.frame.maxY
        let sourceRect = CGRect(
            x: rect.minX - screen.frame.minX,
            y: maxY   - rect.maxY,
            width: rect.width,
            height: rect.height
        )

        let scaleFactor = CGFloat(filter.pointPixelScale)
        let config = SCStreamConfiguration().then {
            $0.sourceRect  = sourceRect
            $0.width       = Int(rect.width  * scaleFactor)
            $0.height      = Int(rect.height * scaleFactor)
            $0.showsCursor = false
        }

        do {
            let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            return NSImage(cgImage: cgImage, size: .init(width: rect.width, height: rect.height))
        } catch {
            print("ScreenCaptureKit error:", error)
            return nil
        }
    }

    @available(macOS 15, *)
    private func ensurePermission() async -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        CGRequestScreenCaptureAccess()
        try? await Task.sleep(nanoseconds: 200_000_000)
        return CGPreflightScreenCaptureAccess()
    }
}

// MARK: – Tiny Binding Helper
private extension SCStreamConfiguration {
    /// Allows inline mutation returning self.
    func then(_ block: (SCStreamConfiguration) -> Void) -> SCStreamConfiguration {
        block(self)
        return self
    }
}
