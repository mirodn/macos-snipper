import Cocoa

/// Handles mouse events to draw and report a selection rectangle.
final class SelectionView: NSView {
    var onSelectionComplete: ((NSRect) -> Void)?

    private var anchorPoint: NSPoint?
    private var currentPoint: NSPoint?

    override func mouseDown(with event: NSEvent) {
        anchorPoint = convert(event.locationInWindow, from: nil)
        currentPoint = anchorPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard
            let start = anchorPoint,
            let end   = currentPoint
        else { return }

        let selection = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width:  abs(start.x - end.x),
            height: abs(start.y - end.y)
        )
        onSelectionComplete?(selection)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard
            let start = anchorPoint,
            let end   = currentPoint
        else { return }

        // Dim entire screen
        NSColor.black.withAlphaComponent(0.25).setFill()
        bounds.fill()

        // Punch out selection
        let rect = NSRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width:  abs(start.x - end.x),
            height: abs(start.y - end.y)
        )
        NSColor.clear.setFill()
        rect.fill(using: .destinationOut)

        // Draw border
        NSColor.white.setStroke()
        let border = NSBezierPath(rect: rect)
        border.lineWidth = 1
        border.stroke()
    }
}
