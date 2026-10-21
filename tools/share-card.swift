// Draws the link preview card (share.png, 1200×630) shown when someone
// texts or posts getmeridia.app: a fan of real app screenshots in four
// themes, with the name and tagline.
// Run from the repo root: swift tools/share-card.swift
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let width = 1200, height = 630
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

func load(_ path: String) -> CGImage {
    let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(src, 0, nil)!
}

func canvas() -> CGContext {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(height)); ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(color(0x1F1A33)); ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    // Faint stars.
    var seed: UInt64 = 3
    func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 11) / CGFloat(1 << 53) }
    for _ in 0..<140 {
        let s = 0.8 + rnd() * 1.8
        ctx.setFillColor(color(rnd() < 0.3 ? 0xD9B36C : 0xF1EAFC, 0.25 + rnd() * 0.5))
        ctx.fillEllipse(in: CGRect(x: rnd() * CGFloat(width), y: rnd() * CGFloat(height), width: s, height: s))
    }
    return ctx
}

func glow(_ ctx: CGContext, at p: CGPoint, radius: CGFloat, hex: UInt32, alpha: CGFloat) {
    let g = CGGradient(colorsSpace: space, colors: [color(hex, alpha), color(hex, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(g, startCenter: p, startRadius: 0, endCenter: p, endRadius: radius, options: [])
}

/// A phone with a screenshot, centered at `center`, `w` wide, turned by `angle` radians.
func phone(_ ctx: CGContext, _ image: CGImage, center: CGPoint, w: CGFloat, angle: CGFloat) {
    let h = w * CGFloat(image.height) / CGFloat(image.width)
    let bezel = w * 0.035, corner = w * 0.16
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y); ctx.rotate(by: angle)
    let body = CGRect(x: -w / 2 - bezel, y: -h / 2 - bezel, width: w + bezel * 2, height: h + bezel * 2)
    ctx.setShadow(offset: CGSize(width: 0, height: 24), blur: 50, color: color(0x000000, 0.55))
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: corner + bezel, cornerHeight: corner + bezel, transform: nil))
    ctx.setFillColor(color(0x0D0B16)); ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: corner + bezel, cornerHeight: corner + bezel, transform: nil))
    ctx.setStrokeColor(color(0xFFFFFF, 0.12)); ctx.setLineWidth(1.5); ctx.strokePath()
    let screen = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
    ctx.addPath(CGPath(roundedRect: screen, cornerWidth: corner, cornerHeight: corner, transform: nil)); ctx.clip()
    // Images draw bottom-up in this flipped context, so flip just for the screenshot.
    ctx.translateBy(x: 0, y: h / 2); ctx.scaleBy(x: 1, y: -1)
    ctx.draw(image, in: CGRect(x: -w / 2, y: 0, width: w, height: h))
    ctx.restoreGState()
}

func text(_ ctx: CGContext, _ string: String, font name: String, size: CGFloat, hex: UInt32, x: CGFloat, top: CGFloat, w: CGFloat) -> CGFloat {
    let font = CTFontCreateWithName(name as CFString, size, nil)
    let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font,
                                                NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(hex)]
    let setter = CTFramesetterCreateWithAttributedString(NSAttributedString(string: string, attributes: attrs))
    let fit = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil, CGSize(width: w, height: 1000), nil)
    ctx.saveGState()
    ctx.translateBy(x: 0, y: top + fit.height); ctx.scaleBy(x: 1, y: -1)
    CTFrameDraw(CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: CGRect(x: x, y: 0, width: w, height: fit.height), transform: nil), nil), ctx)
    ctx.restoreGState()
    return fit.height
}

func headline(_ ctx: CGContext, x: CGFloat, top start: CGFloat, w: CGFloat, size: CGFloat = 60) {
    var top = start
    top += text(ctx, "MERIDIA", font: "IowanOldStyle-Bold", size: 26, hex: 0xD9B36C, x: x, top: top, w: w) + 12
    top += text(ctx, "Find where on Earth you shine.", font: "IowanOldStyle-Bold", size: size, hex: 0xF1EAFC, x: x, top: top, w: w) + 20
    _ = text(ctx, "Your birth chart, mapped across the world.", font: "IowanOldStyle-Roman", size: 25, hex: 0xC9C0E0, x: x, top: top, w: w)
}

func save(_ ctx: CGContext, _ name: String) {
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil); CGImageDestinationFinalize(dest)
    print("wrote", name)
}

// The card: a fan of themed phones.
do {
    let ctx = canvas()
    glow(ctx, at: CGPoint(x: 340, y: 315), radius: 380, hex: 0xB8A0FF, alpha: 0.18)
    let shots = [("theme-lavaLounge", -0.24, CGPoint(x: 190, y: 330)), ("theme-crimson", -0.08, CGPoint(x: 290, y: 300)),
                 ("theme-thirdEye", 0.08, CGPoint(x: 390, y: 300)), ("theme-discoBall", 0.24, CGPoint(x: 490, y: 330))]
    for (name, angle, center) in shots {
        phone(ctx, load("shots/\(name).jpg"), center: center, w: 190, angle: CGFloat(angle))
    }
    headline(ctx, x: 660, top: 190, w: 500, size: 54)
    save(ctx, "share.png")
}
