import Cocoa
import ServiceManagement

class PreferencesWindowController: NSWindowController {

    private var pathLabel: NSTextField!
    private var chooseButton: NSButton!

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
    }

    private func refreshUI() {
        pathLabel.stringValue = "Save Path: \(UserSettings.savePath.path)"
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

}
