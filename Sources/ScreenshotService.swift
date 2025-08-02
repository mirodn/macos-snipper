import Cocoa

class ScreenshotService {
    static let shared = ScreenshotService()

    func captureFullScreen() {
        guard let screenImage = CGDisplayCreateImage(CGMainDisplayID()) else {
            print("Screenshot failed")
            return
        }
        let nsImage = NSImage(cgImage: screenImage, size: NSZeroSize)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
        print("📸 Screenshot copied to clipboard!")
    }
}
