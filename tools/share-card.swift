// Draws the link preview card (share.png, 1200×630) shown when someone
// texts or posts getmeridia.app: the grainy gold globe with planet lines,
// the name and the tagline, on midnight velvet.
// Run from the repo root: swift tools/share-card.swift
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let width = 1200, height = 630
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
// Draw with the origin at the top left, like the web page.
ctx.translateBy(x: 0, y: CGFloat(height))
ctx.scaleBy(x: 1, y: -1)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255, green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

// Velvet background with a soft gold glow behind the globe.
ctx.setFillColor(color(0x1F1A33))
ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
let cx: CGFloat = 330, cy: CGFloat = 315, r: CGFloat = 225
let glow = CGGradient(colorsSpace: space, colors: [color(0xD9B36C, 0.22), color(0xD9B36C, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: cx, y: cy), startRadius: r * 0.9,
                       endCenter: CGPoint(x: cx, y: cy), endRadius: r * 1.45, options: [])

// The grainy ball, lit from the upper left.
var seed: UInt64 = 7
func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 11) / CGFloat(1 << 53) }
let cell: CGFloat = 3
var y = cy - r
while y < cy + r {
    var x = cx - r
    while x < cx + r {
        let nx = (x - cx) / r, ny = (y - cy) / r, r2 = nx * nx + ny * ny
        if r2 < 1 {
            let nz = (1 - r2).squareRoot()
            let light = max(0, -0.55 * nx - 0.35 * ny + 0.76 * nz)
            let gold = rnd() < 0.12 + 0.88 * min(1, light * 1.25)
            ctx.setFillColor(gold ? color(0xE8B04A) : color(0x2A2443))
            ctx.fill(CGRect(x: x, y: y, width: cell, height: cell))
        }
        x += cell
    }
    y += cell
}

// Planet lines cut into the gold, their colors glowing inside.
let tilt = 0.35, spin = 0.0
func project(_ lat: Double, _ lon: Double) -> (CGPoint, Double) {
    let x = cos(lat) * sin(lon + spin), z0 = cos(lat) * cos(lon + spin), y0 = sin(lat)
    let yy = y0 * cos(tilt) - z0 * sin(tilt), z = y0 * sin(tilt) + z0 * cos(tilt)
    return (CGPoint(x: cx + CGFloat(x) * r, y: cy - CGFloat(yy) * r), z)
}
let lines: [(Double, UInt32, Bool)] = [(-0.95, 0xFFD173, true), (-0.45, 0x7FE8C4, false), (0.1, 0xFF9EC2, true),
                                       (0.55, 0xB8A0FF, false), (1.05, 0x80BFFF, true)]
ctx.setLineCap(.round)
for (lon, hex, solid) in lines {
    if solid {
        let path = CGMutablePath(); var pen = false
        var lat = -1.45
        while lat <= 1.45 {
            let (p, z) = project(lat, lon)
            if z > 0 { if pen { path.addLine(to: p) } else { path.move(to: p) }; pen = true } else { pen = false }
            lat += 0.03
        }
        ctx.addPath(path); ctx.setStrokeColor(color(0x1F1A33)); ctx.setLineWidth(15); ctx.strokePath()
        ctx.addPath(path); ctx.setStrokeColor(color(hex)); ctx.setLineWidth(6); ctx.strokePath()
    } else {
        var lat = -1.4
        while lat <= 1.4 {
            let (p, z) = project(lat, lon + 0.5 * sin(lat * 1.4))
            if z > 0 {
                ctx.setFillColor(color(0x1F1A33)); ctx.fillEllipse(in: CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18))
                ctx.setFillColor(color(hex)); ctx.fillEllipse(in: CGRect(x: p.x - 5, y: p.y - 5, width: 10, height: 10))
            }
            lat += 0.13
        }
    }
}

// Text, in the site's serif.
func draw(_ text: String, font name: String, size: CGFloat, color hex: UInt32, x: CGFloat, top: CGFloat, width w: CGFloat) -> CGFloat {
    let font = CTFontCreateWithName(name as CFString, size, nil)
    let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key(kCTFontAttributeName as String): font,
                                                NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(hex)]
    let string = NSAttributedString(string: text, attributes: attrs)
    let setter = CTFramesetterCreateWithAttributedString(string)
    let fit = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(), nil, CGSize(width: w, height: 1000), nil)
    ctx.saveGState()
    // Core Text draws upward, so flip back for the text block.
    ctx.translateBy(x: 0, y: top + fit.height)
    ctx.scaleBy(x: 1, y: -1)
    let frame = CTFramesetterCreateFrame(setter, CFRange(), CGPath(rect: CGRect(x: x, y: 0, width: w, height: fit.height), transform: nil), nil)
    CTFrameDraw(frame, ctx)
    ctx.restoreGState()
    return fit.height
}
let textX: CGFloat = 640, textW: CGFloat = 500
var top: CGFloat = 165
top += draw("MERIDIA", font: "IowanOldStyle-Bold", size: 28, color: 0xD9B36C, x: textX, top: top, width: textW) + 14
top += draw("Find where on Earth you shine.", font: "IowanOldStyle-Bold", size: 62, color: 0xF1EAFC, x: textX, top: top, width: textW) + 22
_ = draw("Your birth chart, mapped across the world.  getmeridia.app", font: "IowanOldStyle-Roman", size: 25, color: 0xC9C0E0, x: textX, top: top, width: textW)

let image = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "share.png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, image, nil)
CGImageDestinationFinalize(dest)
print("wrote share.png")
