import AppKit

// Usage: swift make_icon.swift <output.iconset>
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func render(_ pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let cg = context.cgContext
    let side = CGFloat(pixels)

    // macOS icon grid: an 824/1024 rounded square, centred.
    let inset = side * 100 / 1024
    let tile = CGRect(x: 0, y: 0, width: side, height: side).insetBy(dx: inset, dy: inset)
    let radius = tile.width * 0.2237
    let path = CGPath(roundedRect: tile, cornerWidth: radius, cornerHeight: radius, transform: nil)

    cg.saveGState()
    cg.addPath(path)
    cg.clip()
    cg.setFillColor(CGColor(gray: 0.018, alpha: 1))
    cg.fill(tile)
    let pool = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceGray(),
        colors: [CGColor(gray: 1, alpha: 0.26), CGColor(gray: 1, alpha: 0)] as CFArray,
        locations: [0, 1])!
    let center = CGPoint(x: tile.midX, y: tile.minY + tile.height * 0.12)
    cg.drawRadialGradient(pool, startCenter: center, startRadius: 0, endCenter: center, endRadius: tile.width * 0.62, options: [])

    let config = NSImage.SymbolConfiguration(pointSize: tile.width * 0.46, weight: .regular)
        .applying(.init(paletteColors: [.white]))
    let symbol = NSImage(systemSymbolName: "apple.logo", accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
    let box = CGRect(
        x: tile.midX - symbol.size.width / 2, y: tile.midY - symbol.size.height / 2,
        width: symbol.size.width, height: symbol.size.height)
    cg.setShadow(offset: .zero, blur: tile.width * 0.09, color: CGColor(gray: 1, alpha: 0.75))
    symbol.draw(in: box)
    symbol.draw(in: box)
    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try render(points).write(to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(points * 2).write(to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
