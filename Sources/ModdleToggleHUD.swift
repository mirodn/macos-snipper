import Cocoa
import SwiftUI

extension Notification.Name {
    static let hudHoverChanged = Notification.Name("HUDHoverChanged")
}

private struct ModeToggleView: View {
    @State private var mode: CaptureMode = UserSettings.captureMode
    var didChange: (CaptureMode) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
            Picker("", selection: $mode) {
                Text("Selection").tag(CaptureMode.area)
                Text("Full Screen").tag(CaptureMode.full)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
        .onChange(of: mode) { newMode in
            UserSettings.captureMode = newMode
            didChange(newMode)
        }
        .onAppear {
            mode = UserSettings.captureMode
            NotificationCenter.default.addObserver(forName: .captureModeDidChange, object: nil, queue: .main) { note in
                if let m = note.object as? CaptureMode { mode = m }
            }
        }
        .onHover { isHover in
            NotificationCenter.default.post(name: .hudHoverChanged, object: isHover)
            if isHover {
                NSCursor.unhide()
                NSCursor.arrow.set()
            }
        }
        .accessibilityIdentifier("ModeToggleHUD")
    }
}

final class ModeToggleHUD: NSPanel {
    private var hosting: NSHostingView<ModeToggleView>?

    init(didChange: @escaping (CaptureMode) -> Void) {
        let style: NSWindow.StyleMask = [.nonactivatingPanel, .fullSizeContentView]
        super.init(contentRect: .init(x: 0, y: 0, width: 260, height: 48),
                   styleMask: style, backing: .buffered, defer: false)

        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // Liegt sicher über dem Overlay
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        ignoresMouseEvents = false
        worksWhenModal = true
        becomesKeyOnlyIfNeeded = true

        let hv = NSHostingView(rootView: ModeToggleView(didChange: didChange))
        hv.translatesAutoresizingMaskIntoConstraints = false
        contentView = hv
        hosting = hv

        hv.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor).isActive = true
        hv.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor).isActive = true
        hv.topAnchor.constraint(equalTo: contentView!.topAnchor).isActive = true
        hv.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor).isActive = true
    }

    func show(on screen: NSScreen? = NSScreen.main, yOffset: CGFloat = 72) {
        guard let screen else { return }
        let vf = screen.visibleFrame
        let size = contentView?.fittingSize ?? NSSize(width: 260, height: 48)
        let x = vf.midX - size.width / 2
        let y = vf.maxY - yOffset - size.height
        setFrame(.init(x: x, y: y, width: size.width, height: size.height), display: true)
        orderFrontRegardless()
    }

    func reposition(above rectInScreen: CGRect, padding: CGFloat = 10) {
        let size = contentView?.fittingSize ?? frame.size
        let x = rectInScreen.midX - size.width / 2
        let y = rectInScreen.maxY + padding
        setFrame(.init(x: x, y: y, width: size.width, height: size.height), display: false)
    }
}
