import Foundation

/// Defines the screenshot capture mode.
enum CaptureMode: String {
    case full = "full"    // full-screen capture
    case area = "area"    // user-selectable area
}

extension Notification.Name {
    /// Fired whenever the capture mode changes.
    static let captureModeDidChange = Notification.Name("captureModeDidChange")
}

struct UserSettings {
    private static let savePathKey     = "savePath"
    private static let captureModeKey  = "captureMode"

    /// Folder where screenshots are saved.
    static var savePath: URL {
        get {
            if let custom = UserDefaults.standard.url(forKey: savePathKey) {
                return custom
            }
            if let pictures = FileManager.default
                .urls(for: .picturesDirectory, in: .userDomainMask)
                .first {
                return pictures.appendingPathComponent("Snipper")
            }
            return FileManager.default
                .homeDirectoryForCurrentUser
                .appendingPathComponent("Snipper")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: savePathKey)
        }
    }

    /// Current capture mode: full or area.
    static var captureMode: CaptureMode {
        get {
            if let raw = UserDefaults.standard.string(forKey: captureModeKey),
               let mode = CaptureMode(rawValue: raw) {
                return mode
            }
            return .full
        }
        set {
            let old = UserDefaults.standard.string(forKey: captureModeKey)
            UserDefaults.standard.set(newValue.rawValue, forKey: captureModeKey)
            if old != newValue.rawValue {
                NotificationCenter.default.post(name: .captureModeDidChange, object: newValue)
            }
        }
    }
}
