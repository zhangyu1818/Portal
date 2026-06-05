import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: create-dmg-background.swift <output.png>\n".utf8))
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let size = NSSize(width: 660, height: 420)
guard let imageRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bitmapFormat: [],
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("failed to create dmg background bitmap\n".utf8))
    exit(1)
}

imageRep.size = size

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: imageRep)

let bounds = NSRect(origin: .zero, size: size)
NSColor(calibratedRed: 0.965, green: 0.972, blue: 0.968, alpha: 1).setFill()
bounds.fill()

let minorGrid = NSColor(calibratedRed: 0.81, green: 0.85, blue: 0.84, alpha: 0.24)
let majorGrid = NSColor(calibratedRed: 0.69, green: 0.75, blue: 0.73, alpha: 0.20)

for x in stride(from: 0, through: Int(size.width), by: 22) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: CGFloat(x) + 0.5, y: 0))
    path.line(to: NSPoint(x: CGFloat(x) + 0.5, y: size.height))
    path.lineWidth = 1
    (x.isMultiple(of: 88) ? majorGrid : minorGrid).setStroke()
    path.stroke()
}

for y in stride(from: 0, through: Int(size.height), by: 22) {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 0, y: CGFloat(y) + 0.5))
    path.line(to: NSPoint(x: size.width, y: CGFloat(y) + 0.5))
    path.lineWidth = 1
    (y.isMultiple(of: 88) ? majorGrid : minorGrid).setStroke()
    path.stroke()
}

let vignette = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.36),
    NSColor.white.withAlphaComponent(0.00),
])
vignette?.draw(
    in: bounds.insetBy(dx: -120, dy: -90),
    relativeCenterPosition: NSPoint(x: 0, y: 0)
)

NSGraphicsContext.restoreGraphicsState()

guard
    let pngData = imageRep.representation(using: .png, properties: [:])
else {
    FileHandle.standardError.write(Data("failed to render dmg background\n".utf8))
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)
