# macos-snipper

A lightweight **open-source screenshot tool for macOS**, inspired by Windows Snipping Tool.

## Features Implementation Status

| Feature               |  Status |
| --------------------- |  ------ |
| Global Hotkey: **Shift + Ctrl + S** → Fullscreen screenshot to clipboard | ✅  |
| Menubar App (no Dock icon) | ✅ |
| Custom Save Path: Screenshots automatically stored in a chosen folder | ✅ |
| App Icon & DMG Installer for a native macOS feel |  ✅ |
| Region selection (drag to capture part of the screen)   | ✅ |
| Include timestamps    |  ✅  |
| Multiple Output Formats   |  ❌     |
| Cloud Upload Integration        |   ❌     |

## Hotkeys

| Action            |  Shortcut |
| --------------------- |  ------ |
| Fullscreen Shot| `Shift + Ctrl + S` |

> (Custom hotkeys coming soon!)

## Installation

- Download the **DMG** from [Releases](https://github.com/mirodn/macos-snipper/releases)
- Drag the app into `Applications`
- Grant permissions in **System Settings**:
  - **Screen Recording**
  - **Input Monitoring**

## Development

### Setting up Development Environment

To contribute or test changes to **macos-snipper**, you can build and run the app locally with the provided `Makefile`.

#### Common Commands

| Command               | Description     |
| --------------------- | --------------- |
| `make build`         | Build the app   |
| `make build-universal` | Build universal binary (Intel + Apple Silicon) |
| `make bundle`        | Create app bundle |
| `make sign`          | Code sign the app |
| `make run-local`     | Run the app locally |
| `make show-app`      | Open the built app in Finder |
| `make tcc-reset`     | Reset TCC permissions for the app |
|`make uninstall-local` | Uninstall the locally built app |

## Contribution

Contributions are welcome!
Fork the repo, create a branch, and submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
