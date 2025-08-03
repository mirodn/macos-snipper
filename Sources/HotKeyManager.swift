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
            callback: { proxy, type, event, refcon in
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                // Debug log
                print("Pressed keyCode: \(keyCode), flags: \(flags.rawValue)")

                // Hotkey: Shift + Control + S
                if flags.contains(.maskControl) &&
                   flags.contains(.maskShift) &&
                   keyCode == 1 { // 'S' key
                    print("Hotkey triggered: Shift + Control + S")
                    DispatchQueue.main.async {
                        ScreenshotService.shared.captureFullScreen()
                    }
                    return nil // Consume the event
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        if let eventTap = eventTap {
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
            print("Hotkey listener started: Shift + Control + S")
        } else {
            print("Failed to create event tap. Check Input Monitoring permissions.")
        }
    }
}
