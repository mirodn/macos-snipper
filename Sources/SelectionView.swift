// Sources/SelectionView.swift
import Cocoa

final class SelectionView: NSView {
    var onSelectionComplete: ((NSRect) -> Void)?

    // Overlay & drawing
    var dimAlpha: CGFloat = 0.35
    var borderLineWidth: CGFloat = 2.0
    var drawCustomCrosshair: Bool = true

    // State
    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var tracking: NSTrackingArea?
    private var cursorPoint: NSPoint = .zero  // position of our drawn crosshair

    // Always consume events (even though the view is transparent)
    override func hitTest(_ point: NSPoint) -> NSView? { self }
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        window?.acceptsMouseMovedEvents = true
        window?.invalidateCursorRects(for: self)
        // Set initial cursor position immediately (without requiring mouse movement)
        updateCursorPointFromScreen()
        needsDisplay = true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let t = tracking { removeTrackingArea(t) }
        tracking = NSTrackingArea(
            rect: .zero,
            options: [.activeAlways, .inVisibleRect, .mouseMoved, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking!)
    }

    // Keep system cursor as crosshair too (optional fallback)
    override func resetCursorRects() {
        super.resetCursorRects()
        discardCursorRects()
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.crosshair.set()
    }

    // MARK: - Drawing

    private var selectionRect: NSRect? {
        guard let s = startPoint, let c = currentPoint else { return nil }
        return NSRect(
            x: min(s.x, c.x),
            y: min(s.y, c.y),
            width: abs(c.x - s.x),
            height: abs(c.y - s.y)
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let dimColor = NSColor.black.withAlphaComponent(dimAlpha)

        if let rect = selectionRect {
            // Dim everything except the selection rect
            let p = NSBezierPath(rect: bounds)
            p.appendRect(rect)
            p.windingRule = .evenOdd
            dimColor.setFill()
            p.fill()

            // Selection border
            NSColor.white.setStroke()
            let border = NSBezierPath(rect: rect)
            border.lineWidth = borderLineWidth
            border.stroke()
        } else {
            // Immediate dimming
            dimColor.setFill()
            bounds.fill()

            // Draw our own crosshair (visible immediately)
            if drawCustomCrosshair { drawCrosshair(at: cursorPoint) }
        }
    }

    private func drawCrosshair(at p: NSPoint) {
        let path = NSBezierPath()
        let len: CGFloat = 10
        // Horizontal
        path.move(to: NSPoint(x: p.x - len, y: p.y))
        path.line(to: NSPoint(x: p.x + len, y: p.y))
        // Vertical
        path.move(to: NSPoint(x: p.x, y: p.y - len))
        path.line(to: NSPoint(x: p.x, y: p.y + len))

        // White outline for visibility
        NSColor.white.setStroke()
        path.lineWidth = 1.5
        path.stroke()

        // Slight inner contrast
        NSColor.black.withAlphaComponent(0.7).setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    // MARK: - Mouse

    override func mouseMoved(with event: NSEvent) {
        // Move our drawn crosshair even when not dragging
        updateCursorPointFromScreen()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let p = convert(event.locationInWindow, from: nil)
        startPoint = p
        currentPoint = p
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        let rect = selectionRect?.standardized ?? .zero
        onSelectionComplete?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            onSelectionComplete?(.zero)
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Helpers

    private func updateCursorPointFromScreen() {
        guard let win = window else { return }
        let screenPoint = NSEvent.mouseLocation
        let windowPoint = win.convertPoint(fromScreen: screenPoint)
        cursorPoint = convert(windowPoint, from: nil)
    }
}
