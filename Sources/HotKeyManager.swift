import Cocoa

class HotkeyManager {
    static let shared = HotkeyManager()
    private var eventTap: CFMachPort?

    func startListening() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, _, event, refcon in
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                // Hotkey: Ctrl + Option + Cmd + S
                if flags.contains(.maskControl) &&
                   flags.contains(.maskAlternate) &&
                   flags.contains(.maskCommand) &&
                   keyCode == 1 { // 'S' key
                    DispatchQueue.main.async {
                        ScreenshotService.shared.captureFullScreen()
                    }
                    return nil
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Failed to create event tap. Check Input Monitoring permissions.")
        }
    }
}
