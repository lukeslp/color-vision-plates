//  IshiharaWidgetView.swift
//  SwiftUI rendering of one Ishihara plate timeline entry.
//
//  Duplicated verbatim into each app's widget target. Draws the dot field
//  with the SwiftUI Canvas API (the plate is recomputed from the entry's
//  seed at render time, so timeline entries stay tiny), then the hour and
//  minute hands. There is no second hand: widgets render discrete snapshots
//  on a timeline and cannot animate per-second.

import SwiftUI
import WidgetKit

struct IshiharaWidgetView: View {
    let entry: IshiharaEntry

    // House palette, shared by hand with the web clock.
    private static let backdrop = Color(red: 0.047, green: 0.043, blue: 0.035) // #0c0b09
    private static let plateBed = Color(red: 0.067, green: 0.067, blue: 0.067) // #111
    private static let handColor = Color.white
    private static let accent    = Color(red: 0.910, green: 0.325, blue: 0.227) // #e8533a

    var body: some View {
        Canvas { ctx, size in
            let plate = IshiharaPlate.build(
                size: size,
                date: entry.date,
                seed: entry.seed,
                selection: entry.selection
            )
            let c = plate.center
            let R = plate.radius

            // Plate bed + clip to the disc.
            let disc = Path(ellipseIn: CGRect(x: c.x - R * 1.02, y: c.y - R * 1.02,
                                              width: R * 2.04, height: R * 2.04))
            ctx.fill(disc, with: .color(Self.plateBed))
            ctx.clip(to: disc)

            for dot in plate.dots {
                let rect = CGRect(x: dot.x - dot.r, y: dot.y - dot.r,
                                  width: dot.r * 2, height: dot.r * 2)
                ctx.fill(Path(ellipseIn: rect),
                         with: .color(Color(red: dot.red, green: dot.green, blue: dot.blue)))
            }

            // Inner vignette, matching the web clock.
            let vignette = GraphicsContext.Shading.radialGradient(
                Gradient(stops: [
                    .init(color: .black.opacity(0), location: 0.5),
                    .init(color: .black.opacity(0.22), location: 1.0),
                ]),
                center: c, startRadius: 0, endRadius: R)
            ctx.fill(Path(CGRect(x: c.x - R, y: c.y - R, width: R * 2, height: R * 2)),
                     with: vignette)

            guard entry.showHands else { return }

            let minute = Double(Calendar.current.component(.minute, from: entry.date))
            let hour = Double(Calendar.current.component(.hour, from: entry.date)).truncatingRemainder(dividingBy: 12)
            let minuteAngle = minute / 60 * .pi * 2
            let hourAngle = (hour + minute / 60) / 12 * .pi * 2

            drawHand(&ctx, center: c, angle: hourAngle, length: R * 0.52,
                     width: max(3, R * 0.045), color: Self.handColor)
            drawHand(&ctx, center: c, angle: minuteAngle, length: R * 0.80,
                     width: max(2, R * 0.031), color: Self.handColor)

            let capR = max(4, R * 0.035)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - capR, y: c.y - capR, width: capR * 2, height: capR * 2)),
                     with: .color(.white))
            let pinR = max(1.4, R * 0.013)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - pinR, y: c.y - pinR, width: pinR * 2, height: pinR * 2)),
                     with: .color(Self.accent))
        }
        .containerBackground(Self.backdrop, for: .widget)
    }

    private func drawHand(_ ctx: inout GraphicsContext, center: CGPoint, angle: Double,
                          length: CGFloat, width: CGFloat, color: Color) {
        var hand = ctx
        hand.translateBy(x: center.x, y: center.y)
        hand.rotate(by: .radians(angle))
        var path = Path()
        path.move(to: CGPoint(x: 0, y: width * 0.6))
        path.addLine(to: CGPoint(x: 0, y: -length))
        hand.stroke(path, with: .color(color),
                    style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}
