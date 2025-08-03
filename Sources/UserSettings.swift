import Foundation

struct UserSettings {
    private static let savePathKey = "savePath"
    private static let launchAtLoginKey = "launchAtLogin"

    static var savePath: URL {
        get {
            if let customPath = UserDefaults.standard.url(forKey: savePathKey) {
                return customPath
            } else if let picturesDir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first {
                return picturesDir.appendingPathComponent("Snipper")
            }
            return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Snipper")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: savePathKey)
        }
    }

    static var launchAtLogin: Bool {
        get {
            return UserDefaults.standard.bool(forKey: launchAtLoginKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: launchAtLoginKey)
        }
    }
}
