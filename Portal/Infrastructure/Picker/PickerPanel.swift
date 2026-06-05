import AppKit
import SwiftUI

@MainActor
final class PickerPanel: NSPanel {
    convenience init() {
        self.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .popUpMenu
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = false
        self.hidesOnDeactivate = true
        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.backgroundColor = .clear
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    func setContent(_ view: some View) {
        let hosting = NSHostingView(rootView: view)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        self.contentView = hosting
        self.setContentSize(hosting.fittingSize)
    }

    func showAt(point: CGPoint) {
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) })
            ?? NSScreen.main
        else { return }
        let size = self.frame.size
        let screenFrame = screen.visibleFrame
        let clampedX = min(max(point.x, screenFrame.minX), screenFrame.maxX - size.width)
        let clampedY = min(max(point.y - size.height, screenFrame.minY), screenFrame.maxY - size.height)
        self.setFrameOrigin(CGPoint(x: clampedX, y: clampedY))
        self.makeKeyAndOrderFront(nil)
    }
}
