import AppKit
import CoreGraphics

func createIcon(at url: URL) {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // 背景：渐变金色圆角矩形
    let rect = NSRect(origin: .zero, size: size).insetBy(dx: 100, dy: 100)
    let path = NSBezierPath(roundedRect: rect, xRadius: 100, yRadius: 100)
    
    let gradient = NSGradient(starting: NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.0, alpha: 1.0), // Gold
                             ending: NSColor(calibratedRed: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)) // GoldenRod
    
    gradient?.draw(in: path, angle: -45)
    
    // 边框
    NSColor(calibratedWhite: 1.0, alpha: 0.3).setStroke()
    path.lineWidth = 20
    path.stroke()
    
    // 装饰线（模拟金砖质感）
    let shinePath = NSBezierPath()
    shinePath.move(to: NSPoint(x: rect.minX + 150, y: rect.maxY - 150))
    shinePath.line(to: NSPoint(x: rect.maxX - 150, y: rect.maxY - 150))
    NSColor(calibratedWhite: 1.0, alpha: 0.5).setStroke()
    shinePath.lineWidth = 15
    shinePath.lineCapStyle = .round
    shinePath.stroke()
    
    // 文字 "AU" (金的化学符号)
    let text = "AU"
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 400, weight: .black),
        .foregroundColor: NSColor(calibratedRed: 0.4, green: 0.3, blue: 0.0, alpha: 0.8)
    ]
    let textSize = text.size(withAttributes: attributes)
    let textRect = NSRect(x: (size.width - textSize.width) / 2,
                          y: (size.height - textSize.height) / 2 - 20,
                          width: textSize.width,
                          height: textSize.height)
    text.draw(in: textRect, withAttributes: attributes)
    
    image.unlockFocus()
    
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        try? pngData.write(to: url)
        print("✅ Icon image generated at: \(url.path)")
    }
}

let fileURL = URL(fileURLWithPath: "AppIcon.png")
createIcon(at: fileURL)
