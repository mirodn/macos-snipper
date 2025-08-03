import Cocoa
import ServiceManagement

class PreferencesWindowController: NSWindowController {

    private var pathLabel: NSTextField!
    private var chooseButton: NSButton!
    private var launchAtLoginCheckbox: NSButton!

    convenience init() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
                               styleMask: [.titled, .closable],
                               backing: .buffered,
                               defer: false)
        window.title = "Preferences"
        self.init(window: window)
        setupUI()
        refreshUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Path Label
        pathLabel = NSTextField(labelWithString: "")
        pathLabel.frame = NSRect(x: 20, y: 130, width: 360, height: 24)
        contentView.addSubview(pathLabel)

        // Choose Folder Button
        chooseButton = NSButton(title: "Choose Folder", target: self, action: #selector(choosePathClicked))
        chooseButton.frame = NSRect(x: 20, y: 90, width: 120, height: 32)
        contentView.addSubview(chooseButton)

        // Launch at Login Checkbox
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Start at Login", target: self, action: #selector(launchAtLoginChanged(_:)))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: 50, width: 200, height: 24)
        contentView.addSubview(launchAtLoginCheckbox)
    }

    private func refreshUI() {
        pathLabel.stringValue = "Save Path: \(UserSettings.savePath.path)"
        launchAtLoginCheckbox.state = UserSettings.launchAtLogin ? .on : .off
    }

    @objc private func choosePathClicked() {
        let panel = NSOpenPanel()
        panel.title = "Choose Screenshot Save Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            UserSettings.savePath = url
            refreshUI()
        }
    }

    @objc private func launchAtLoginChanged(_ sender: NSButton) {
        let enabled = (sender.state == .on)
        UserSettings.launchAtLogin = enabled
        toggleLaunchAtLogin(enabled)
    }

    private func toggleLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("Launch at login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("Launch at login disabled")
                }
            } catch {
                print("Failed to update login setting: \(error)")
            }
        } else {
            print("Launch at login not supported on macOS < 13")
        }
    }
}
