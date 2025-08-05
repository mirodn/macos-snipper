import Cocoa
import ServiceManagement

/// Preferences window: choose save folder + capture mode.
final class PreferencesWindowController: NSWindowController {
    private var pathLabel: NSTextField!
    private var chooseButton: NSButton!
    private var fullRadio: NSButton!
    private var areaRadio: NSButton!

    convenience init() {
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 400, height: 240),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        self.init(window: window)
        setupUI()
        refreshUI()
    }

    private func setupUI() {
        guard let content = window?.contentView else { return }

        pathLabel = NSTextField(labelWithString: "")
        pathLabel.frame = .init(x: 20, y: 180, width: 360, height: 24)
        content.addSubview(pathLabel)

        chooseButton = NSButton(title: "Choose Folder", target: self, action: #selector(didTapChooseFolder))
        chooseButton.frame = .init(x: 20, y: 140, width: 120, height: 32)
        content.addSubview(chooseButton)

        fullRadio = NSButton(radioButtonWithTitle: "Full Screen", target: self, action: #selector(modeChanged(_:)))
        fullRadio.frame = .init(x: 20, y: 100, width: 150, height: 20)
        content.addSubview(fullRadio)

        areaRadio = NSButton(radioButtonWithTitle: "Selection Area", target: self, action: #selector(modeChanged(_:)))
        areaRadio.frame = .init(x: 20, y: 70, width: 150, height: 20)
        content.addSubview(areaRadio)
    }

    private func refreshUI() {
        pathLabel.stringValue = "Save Path: \(UserSettings.savePath.path)"

        switch UserSettings.captureMode {
        case .full:
            fullRadio.state = .on
            areaRadio.state = .off
        case .area:
            fullRadio.state = .off
            areaRadio.state = .on
        }
    }

    @objc private func didTapChooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            UserSettings.savePath = url
            refreshUI()
        }
    }

    @objc private func modeChanged(_ sender: NSButton) {
        UserSettings.captureMode = (sender == fullRadio) ? .full : .area
        refreshUI()
    }
}
