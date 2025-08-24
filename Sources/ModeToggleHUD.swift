import Cocoa
import SwiftUI

/// Callback when the user taps "Full Screen" in the HUD.
typealias FullScreenTapHandler = () -> Void

private struct ModeToggleView: View {
    @State private var mode: CaptureMode = .area
    let onFullScreenTap: FullScreenTapHandler

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
            Picker("", selection: $mode) {
                Text("Selection").tag(CaptureMode.area)
                Text("Full Screen").tag(CaptureMode.full)
            }
            .pickerStyle(.segmented)
            .frame(width: 220)
            // macOS 14+: new signature with (old, new)
            .onChange(of: mode) { _, newMode in
                if newMode == .full { onFullScreenTap() }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
        .onAppear { mode = .area } // always start with Selection
        .onHover { isHover in
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

    init(onFullScreenTap: @escaping FullScreenTapHandler) {
        let style: NSWindow.StyleMask = [.nonactivatingPanel, .fullSizeContentView]
        super.init(contentRect: .init(x: 0, y: 0, width: 260, height: 48),
                   styleMask: style, backing: .buffered, defer: false)

        isFloatingPanel = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        // always displayed above the overlay
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        ignoresMouseEvents = false
        worksWhenModal = true
        becomesKeyOnlyIfNeeded = true

        let hv = NSHostingView(rootView: ModeToggleView(onFullScreenTap: onFullScreenTap))
        hv.translatesAutoresizingMaskIntoConstraints = false
        contentView = hv
        hosting = hv

        hv.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor).isActive = true
        hv.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor).isActive = true
        hv.topAnchor.constraint(equalTo: contentView!.topAnchor).isActive = true
        hv.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor).isActive = true
    }

    /// Shows the HUD centered at the top of the active screen (robust, without relying on NSScreen.main).
    func show(yOffset: CGFloat = 72) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
                  ?? NSScreen.screens.first
        guard let screen else { return }

        let vf = screen.visibleFrame
        let size = contentView?.fittingSize ?? NSSize(width: 260, height: 48)
        let x = vf.midX - size.width / 2
        let y = vf.maxY - yOffset - size.height
        setFrame(.init(x: x, y: y, width: size.width, height: size.height), display: true)
        orderFrontRegardless()
    }

    /// Positions the HUD above a rectangle (e.g. above the current selection).
    func reposition(above rectInScreen: CGRect, padding: CGFloat = 10) {
        let size = contentView?.fittingSize ?? frame.size
        let x = rectInScreen.midX - size.width / 2
        let y = rectInScreen.maxY + padding
        setFrame(.init(x: x, y: y, width: size.width, height: size.height), display: false)
    }
}
