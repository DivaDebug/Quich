// 繪製 Quich 的 app icon（深藍底、字母 Q、琥珀色閃電尾巴）
// 用法：swift scripts/make-icon.swift <輸出資料夾>
// 會在輸出資料夾產生 AppIcon.icns（打包用）與 AppIcon.png（1024×1024 預覽用）
import AppKit

let outputDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")

let background = NSColor(srgbRed: 0x0C / 255, green: 0x44 / 255, blue: 0x7C / 255, alpha: 1)
let ringColor = NSColor(srgbRed: 0xE6 / 255, green: 0xF1 / 255, blue: 0xFB / 255, alpha: 1)
let boltColor = NSColor(srgbRed: 0xEF / 255, green: 0x9F / 255, blue: 0x27 / 255, alpha: 1)

// 依指定邊長畫出整個圖示並回傳 PNG；每個尺寸各自重畫，小尺寸也保持銳利
func renderIcon(size: Int) -> Data {
    let canvas = CGFloat(size)
    // macOS 圖示規範：主體約佔畫布 80%，置中，四周留白給陰影
    let bodySize = canvas * 824 / 1024
    let bodyOrigin = (canvas - bodySize) / 2
    // 設計稿以 160×160 為單位，換算成實際像素
    let unit = bodySize / 160

    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // 翻轉成 y 軸向下，讓座標跟設計稿（SVG）一致
    ctx.translateBy(x: 0, y: canvas)
    ctx.scaleBy(x: 1, y: -1)

    // 底部的柔和陰影與圓角方形主體
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: canvas * 10 / 1024), blur: canvas * 28 / 1024,
                  color: NSColor.black.withAlphaComponent(0.3).cgColor)
    let body = CGRect(x: bodyOrigin, y: bodyOrigin, width: bodySize, height: bodySize)
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: 36 * unit, cornerHeight: 36 * unit, transform: nil))
    ctx.setFillColor(background.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.translateBy(x: bodyOrigin, y: bodyOrigin)
    ctx.scaleBy(x: unit, y: unit)

    // Q 的圓圈
    ctx.setStrokeColor(ringColor.cgColor)
    ctx.setLineWidth(16)
    ctx.addEllipse(in: CGRect(x: 76 - 40, y: 72 - 40, width: 80, height: 80))
    ctx.strokePath()

    // 閃電尾巴：先用背景色描粗邊把圓圈切開，再填上琥珀色
    let bolt = CGMutablePath()
    bolt.move(to: CGPoint(x: 7, y: -40))
    bolt.addLine(to: CGPoint(x: -15, y: 4))
    bolt.addLine(to: CGPoint(x: 1, y: 4))
    bolt.addLine(to: CGPoint(x: -7, y: 40))
    bolt.addLine(to: CGPoint(x: 15, y: -4))
    bolt.addLine(to: CGPoint(x: -1, y: -4))
    bolt.closeSubpath()

    ctx.translateBy(x: 110, y: 108)
    ctx.rotate(by: -.pi / 4)

    ctx.addPath(bolt)
    ctx.setStrokeColor(background.cgColor)
    ctx.setLineWidth(8)
    ctx.setLineJoin(.round)
    ctx.strokePath()

    ctx.addPath(bolt)
    ctx.setFillColor(boltColor.cgColor)
    ctx.fillPath()

    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

// 直接組出 .icns：檔頭 "icns" + 總長度，後面接每個尺寸的「類型代碼 + 長度 + PNG 內容」
func bigEndian(_ value: Int) -> Data {
    withUnsafeBytes(of: UInt32(value).bigEndian) { Data($0) }
}

let entries: [(type: String, size: Int)] = [
    ("icp4", 16), ("icp5", 32), ("ic11", 32), ("icp6", 64), ("ic12", 64),
    ("ic07", 128), ("ic13", 256), ("ic08", 256), ("ic14", 512), ("ic09", 512), ("ic10", 1024),
]
var body = Data()
for entry in entries {
    let png = renderIcon(size: entry.size)
    body.append(entry.type.data(using: .ascii)!)
    body.append(bigEndian(png.count + 8))
    body.append(png)
}
var icns = "icns".data(using: .ascii)!
icns.append(bigEndian(body.count + 8))
icns.append(body)

try! icns.write(to: outputDir.appendingPathComponent("AppIcon.icns"))
try! renderIcon(size: 1024).write(to: outputDir.appendingPathComponent("AppIcon.png"))
print("已輸出 AppIcon.icns 與 AppIcon.png 到 \(outputDir.path)")
