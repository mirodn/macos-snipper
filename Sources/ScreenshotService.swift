import Cocoa

class ScreenshotService {
    static let shared = ScreenshotService()

    func captureFullScreen() {
        guard let screenImage = CGDisplayCreateImage(CGMainDisplayID()) else {
            print("Screenshot failed")
            return
        }

        let nsImage = NSImage(cgImage: screenImage, size: NSZeroSize)

        // Copy to clipboard
        copyToClipboard(nsImage)

        // Save to custom or default folder
        saveScreenshot(nsImage)

        print("📸 Screenshot copied to clipboard and saved!")
    }

    private func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private func saveScreenshot(_ image: NSImage) {
        let saveFolder = UserSettings.savePath

        if !FileManager.default.fileExists(atPath: saveFolder.path) {
            do {
                try FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create save folder: \(error)")
                return
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Screenshot_\(formatter.string(from: Date())).png"
        let fileURL = saveFolder.appendingPathComponent(filename)

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
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
