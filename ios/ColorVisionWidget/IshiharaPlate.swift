//  IshiharaPlate.swift
//  Canonical Swift port of the Ishihara colorblind-clock plate renderer.
//
//  Source of truth: /home/coolhand/html/clocks/ishihara/index.html
//  This file is DUPLICATED verbatim into each app's widget target
//  (WhatColor, ColorVisionPlates). It must stay identical across copies;
//  IshiharaPlateTests.swift guards the color science from drift.
//
//  Pure renderer: no SwiftUI / WidgetKit. Given a size + seed + selection
//  it returns a deterministic dot field with the current hour hidden as a
//  numeral along a real color-confusion line (protan / deutan / tritan).
//  The figure and ground share L (no luminance leak) so the numeral
//  separates purely on chroma, exactly like a printed Ishihara plate.

import CoreGraphics
import UIKit

// MARK: - Plate types

/// The deficiency a given plate is tuned against.
enum PlateType {
    case protan   // red-blind
    case deutan   // green-blind
    case tritan   // blue-yellow
}

/// What the widget is configured to show. `.mixed` rotates the type each
/// regeneration with the same weighting as the web clock.
enum PlateSelection: Equatable {
    case mixed
    case fixed(PlateType)
}

// MARK: - Deterministic PRNG (mulberry32, ported verbatim)

/// Reference type so it can be threaded through the packing routine by
/// reference. Matches the JS `mulberry32` bit-for-bit via UInt32 overflow
/// arithmetic (`&+`, `&*`) and logical right shifts.
final class Mulberry32 {
    private var a: UInt32
    init(_ seed: UInt32) { a = seed }

    func next() -> Double {
        a = a &+ 0x6D2B7_9F5
        var t = a
        t = (t ^ (t >> 15)) &* (t | 1)
        t = (t &+ ((t ^ (t >> 7)) &* (t | 61))) ^ t
        return Double(t ^ (t >> 14)) / 4_294_967_296.0
    }
}

// MARK: - Renderer

struct IshiharaPlate {

    /// One packed dot. Colour stored as linear-free sRGB components in
    /// 0...1 so the renderer stays UI-framework agnostic (the view turns
    /// these into a `Color`).
    struct Dot {
        let x: CGFloat
        let y: CGFloat
        let r: CGFloat
        let red: Double
        let green: Double
        let blue: Double
    }

    struct Result {
        let dots: [Dot]
        let number: String
        let type: PlateType
        let radius: CGFloat
        let center: CGPoint
    }

    /// Confusion-line figure/ground pairs, copied exactly from the web
    /// clock's `DEFS` (themselves lifted from verified test plates). `fg`
    /// and `bg` share L and LR — the figure is chroma-only.
    struct LabBox { let L, LR, a, aR, b, bR: Double }
    struct Pair { let fg: LabBox; let bg: LabBox }

    static let defs: [PlateType: Pair] = [
        .protan: Pair(
            fg: LabBox(L: 65, LR: 10, a: -39, aR: 6, b: -3, bR: 8),
            bg: LabBox(L: 65, LR: 10, a:  45, aR: 6, b:  5, bR: 8)),
        .deutan: Pair(
            fg: LabBox(L: 65, LR: 10, a: -23, aR: 6, b:  9, bR: 8),
            bg: LabBox(L: 65, LR: 10, a:  53, aR: 6, b: -3, bR: 8)),
        .tritan: Pair(
            fg: LabBox(L: 50, LR: 12, a: -23, aR: 8, b:  53, bR: 8),
            bg: LabBox(L: 50, LR: 12, a:  41, aR: 8, b: -55, bR: 8)),
    ]

    /// XOR salt mixed into the per-minute seed (matches the web clock).
    static let salt: UInt32 = 0x9E37

    /// Build a deterministic seed for a given moment + plate dimension,
    /// mirroring the web clock's minute-bucket seed.
    static func seed(for date: Date, radius: CGFloat) -> UInt32 {
        let minuteBucket = UInt32(truncatingIfNeeded: Int(date.timeIntervalSince1970 / 60))
        // Multiply in UInt32 (matches the JS unsigned 32-bit seed math; the
        // signed-Int intermediate could wrap differently at huge radii).
        let dim = UInt32(truncatingIfNeeded: Int(radius.rounded())) &* 131
        return (minuteBucket ^ salt ^ dim)
    }

    // MARK: CIELAB -> sRGB (ported verbatim from labToHex)

    static func labToRGB(_ L: Double, _ a: Double, _ b: Double) -> (Double, Double, Double) {
        let delta = 6.0 / 29.0
        let k = 3 * delta * delta
        func fInv(_ t: Double) -> Double { t > delta ? t * t * t : k * (t - 4.0 / 29.0) }
        let fy = (L + 16) / 116
        let X = 0.95047 * fInv(fy + a / 500)
        let Y = 1.00000 * fInv(fy)
        let Z = 1.08883 * fInv(fy - b / 200)
        let rl =  3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z
        let gl = -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z
        let bl =  0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z
        func gamma(_ c: Double) -> Double {
            let v = max(0, min(1, c))
            return v <= 0.0031308 ? 12.92 * v : 1.055 * pow(v, 1 / 2.4) - 0.055
        }
        return (gamma(rl), gamma(gl), gamma(bl))
    }

    private static func jitter(_ box: LabBox, _ rng: Mulberry32) -> (Double, Double, Double) {
        let L = box.L + (rng.next() - 0.5) * box.LR
        let a = box.a + (rng.next() - 0.5) * box.aR
        let b = box.b + (rng.next() - 0.5) * box.bR
        return labToRGB(L, a, b)
    }

    // MARK: Numeral mask

    /// Rasterise the numeral to a top-down boolean coverage mask. Uses
    /// UIGraphicsImageRenderer (UIKit top-left origin, upright text) so
    /// the buffer is orientation-correct by construction — row 0 is the
    /// visual top, matching the web `getImageData` sampling.
    static func numeralMask(size: Int, value: String) -> [Bool] {
        let w = max(1, size)
        var mask = [Bool](repeating: false, count: w * w)

        let fontSize = CGFloat(value.count > 1 ? Double(w) * 0.42 : Double(w) * 0.55)
        let font = UIFont.systemFont(ofSize: fontSize, weight: .black)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: para,
        ]
        let ns = NSString(string: value)

        // Draw into a full-width rect so the paragraph's .center alignment
        // handles horizontal placement (metric-independent). Vertically,
        // centre on the glyph cap-height — the visual centre of a digit —
        // which mirrors the web clock's textBaseline='middle' intent better
        // than the font's full line box would.
        let topY = CGFloat(w) / 2 - font.ascender + font.capHeight / 2
        let drawRect = CGRect(x: 0, y: topY, width: CGFloat(w), height: CGFloat(w))

        // Rasterise at scale 1 so the pixel buffer is exactly w×w — the
        // sampling loop below indexes it as w×w. The default format uses the
        // screen scale (2x/3x), producing a 2w/3w-wide buffer; reading only
        // the first w columns and rows then captures a single quadrant of the
        // centred glyph and flings the figure into the bottom-right of the
        // plate (and at 3x drops it off the sampled region entirely).
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: w), format: format)
        let image = renderer.image { _ in
            ns.draw(in: drawRect, withAttributes: attrs)
        }

        guard let cg = image.cgImage,
              let provider = cg.dataProvider,
              let data = provider.data else { return mask }
        let ptr = CFDataGetBytePtr(data)
        let rowBytes = cg.bytesPerRow
        let bpp = cg.bitsPerPixel / 8
        guard let ptr, bpp >= 1 else { return mask }

        for y in 0..<w {
            let row = y * rowBytes
            for x in 0..<w {
                let base = row + x * bpp
                // White-on-clear text: every channel is 255 inside the
                // glyph and 0 outside, so OR-ing the bytes is order- and
                // alpha-layout independent.
                var covered = false
                for c in 0..<min(bpp, 4) where ptr[base + c] > 128 { covered = true; break }
                mask[y * w + x] = covered
            }
        }
        return mask
    }

    // MARK: Poisson-disk packing (ported verbatim)

    private static func poisson(cx: CGFloat, cy: CGFloat, plateR: CGFloat,
                                minR: CGFloat, maxR: CGFloat, rng: Mulberry32) -> [(x: CGFloat, y: CGFloat, r: CGFloat)] {
        let cellSize = minR * 1.5 / CGFloat(2).squareRoot()
        let gridW = Int(ceil(plateR * 2 / cellSize))
        guard gridW > 0 else { return [] }
        var grid = [Int](repeating: -1, count: gridW * gridW)
        var dots: [(x: CGFloat, y: CGFloat, r: CGFloat)] = []
        var active: [Int] = []

        func gridIndex(_ x: CGFloat, _ y: CGFloat) -> Int {
            let gx = Int(floor((x - cx + plateR) / cellSize))
            let gy = Int(floor((y - cy + plateR) / cellSize))
            if gx < 0 || gx >= gridW || gy < 0 || gy >= gridW { return -1 }
            return gy * gridW + gx
        }
        func canPlace(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Bool {
            if hypot(x - cx, y - cy) + r > plateR - 1 { return false }
            if gridIndex(x, y) < 0 { return false }
            let gx = Int(floor((x - cx + plateR) / cellSize))
            let gy = Int(floor((y - cy + plateR) / cellSize))
            for dy in -3...3 {
                for dx in -3...3 {
                    let nx = gx + dx, ny = gy + dy
                    if nx < 0 || nx >= gridW || ny < 0 || ny >= gridW { continue }
                    let ni = ny * gridW + nx
                    if grid[ni] >= 0 {
                        let o = dots[grid[ni]]
                        if hypot(x - o.x, y - o.y) < r + o.r + 0.8 { return false }
                    }
                }
            }
            return true
        }
        @discardableResult
        func add(_ x: CGFloat, _ y: CGFloat) -> Bool {
            let r = minR + CGFloat(rng.next()) * (maxR - minR)
            if !canPlace(x, y, r) { return false }
            let i = dots.count
            dots.append((x, y, r))
            active.append(i)
            let idx = gridIndex(x, y)
            if idx >= 0 { grid[idx] = i }
            return true
        }

        add(cx, cy)
        while !active.isEmpty {
            let ai = Int(rng.next() * Double(active.count))
            let src = dots[active[ai]]
            var found = false
            for _ in 0..<30 {
                let ang = rng.next() * Double.pi * 2
                let d = Double(minR) * 2 + rng.next() * Double(minR) * 2.5
                if add(src.x + CGFloat(cos(ang) * d), src.y + CGFloat(sin(ang) * d)) {
                    found = true
                    break
                }
            }
            if !found { active.remove(at: ai) }
        }
        return dots
    }

    // MARK: Build

    static func build(size: CGSize, date: Date, seed seedValue: UInt32, selection: PlateSelection) -> Result {
        let w = size.width, h = size.height
        let cx = w / 2, cy = h / 2
        let R = min(w, h) * 0.46

        var hour = Calendar.current.component(.hour, from: date) % 12
        if hour == 0 { hour = 12 }
        let number = String(hour)

        let rng = Mulberry32(seedValue)

        // Always consume one roll so the seed -> field mapping is stable
        // regardless of whether the type is pinned or rotating.
        let roll = rng.next()
        let type: PlateType
        switch selection {
        case .fixed(let t): type = t
        case .mixed:        type = roll < 0.45 ? .deutan : (roll < 0.82 ? .protan : .tritan)
        }
        let pair = defs[type]!

        let maskSize = Int((R * 2).rounded())
        let mask = numeralMask(size: maskSize, value: number)
        let ox = cx - R, oy = cy - R

        let minR = max(2, R * 0.014)
        let maxR = max(4.5, R * 0.036)
        let field = poisson(cx: cx, cy: cy, plateR: R, minR: minR, maxR: maxR, rng: rng)

        var dots: [Dot] = []
        dots.reserveCapacity(field.count)
        for d in field {
            let px = Int(d.x - ox), py = Int(d.y - oy)
            var isShape = false
            if px >= 0, px < maskSize, py >= 0, py < maskSize {
                isShape = mask[py * maskSize + px]
            }
            let (r, g, b) = jitter(isShape ? pair.fg : pair.bg, rng)
            dots.append(Dot(x: d.x, y: d.y, r: d.r, red: r, green: g, blue: b))
        }

        return Result(dots: dots, number: number, type: type, radius: R, center: CGPoint(x: cx, y: cy))
    }
}
