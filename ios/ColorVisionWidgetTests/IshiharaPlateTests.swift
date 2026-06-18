//  IshiharaPlateTests.swift
//  Guards the plate science from drift between the two duplicated copies.
//  Mirrors the discipline of the web repo's color-math parity test: the
//  CIELAB pipeline and the confusion-line DEFS are pinned, and the field
//  build is checked for determinism.

import XCTest
import CoreGraphics
// IshiharaPlate.swift is compiled directly into this test target (see the
// test target's `sources:` in project.yml) rather than imported: iOS app
// extensions don't export their Swift module for @testable import, so the
// test bundle carries its own copy of the renderer — fine here, since we
// verify logic, not symbol identity.

final class IshiharaPlateTests: XCTestCase {

    // A neutral L=65 grey must come back with equal RGB channels near 0.63;
    // this anchors the whole CIELAB -> sRGB pipeline.
    func testNeutralGreyRoundsTrip() {
        let (r, g, b) = IshiharaPlate.labToRGB(65, 0, 0)
        XCTAssertEqual(r, g, accuracy: 0.001)
        XCTAssertEqual(g, b, accuracy: 0.001)
        XCTAssertEqual(r, 0.63, accuracy: 0.03)
    }

    // The confusion-line pairs are the contract with the printed/web plates.
    // fg and bg must share L and LR for every type (no luminance leak).
    func testDefsLuminanceParity() {
        for (_, pair) in IshiharaPlate.defs {
            XCTAssertEqual(pair.fg.L, pair.bg.L, "figure/ground L must match")
            XCTAssertEqual(pair.fg.LR, pair.bg.LR, "figure/ground L jitter must match")
        }
    }

    // Exact DEFS values, pinned so an accidental edit fails loudly.
    func testDefsValuesPinned() {
        let protan = IshiharaPlate.defs[.protan]!
        XCTAssertEqual(protan.fg.a, -39); XCTAssertEqual(protan.bg.a, 45)
        let deutan = IshiharaPlate.defs[.deutan]!
        XCTAssertEqual(deutan.fg.a, -23); XCTAssertEqual(deutan.bg.a, 53)
        let tritan = IshiharaPlate.defs[.tritan]!
        XCTAssertEqual(tritan.fg.b, 53); XCTAssertEqual(tritan.bg.b, -55)
    }

    // mulberry32 is deterministic and stays in range.
    func testPRNGDeterministicAndBounded() {
        let a = Mulberry32(123_456)
        let b = Mulberry32(123_456)
        for _ in 0..<1000 {
            let va = a.next(), vb = b.next()
            XCTAssertEqual(va, vb)
            XCTAssertGreaterThanOrEqual(va, 0)
            XCTAssertLessThan(va, 1)
        }
    }

    // Same seed + size + selection -> byte-identical field. This is what
    // keeps the two app copies producing the same plate.
    func testBuildIsDeterministic() {
        let size = CGSize(width: 320, height: 320)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let seed = IshiharaPlate.seed(for: date, radius: 150)

        let one = IshiharaPlate.build(size: size, date: date, seed: seed, selection: .fixed(.deutan))
        let two = IshiharaPlate.build(size: size, date: date, seed: seed, selection: .fixed(.deutan))

        XCTAssertEqual(one.dots.count, two.dots.count)
        XCTAssertGreaterThan(one.dots.count, 100, "the field should pack hundreds of dots")
        for (d1, d2) in zip(one.dots, two.dots) {
            XCTAssertEqual(d1.x, d2.x); XCTAssertEqual(d1.y, d2.y)
            XCTAssertEqual(d1.red, d2.red); XCTAssertEqual(d1.green, d2.green); XCTAssertEqual(d1.blue, d2.blue)
        }
    }

    // The hidden numeral tracks the wall-clock hour (1...12).
    func testNumberIsTwelveHour() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 17; comps.hour = 15; comps.minute = 0
        let date = Calendar.current.date(from: comps)!
        let result = IshiharaPlate.build(size: CGSize(width: 200, height: 200),
                                         date: date,
                                         seed: 42,
                                         selection: .fixed(.protan))
        XCTAssertEqual(result.number, "3")
    }

    // Regression: the hidden numeral must render in the CENTRE of the plate.
    // The mask is rasterised with UIGraphicsImageRenderer, which defaults to
    // the screen scale; if the buffer and the sampling loop disagree on pixel
    // dimensions, the figure is flung into a corner (and can vanish entirely
    // at 3x). Classify figure dots by chroma — deutan fg is green-dominant,
    // bg magenta-dominant — and assert their centroid sits near the centre.
    func testFigureRendersCentred() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 17; comps.hour = 3; comps.minute = 0
        let date = Calendar.current.date(from: comps)!
        let size = CGSize(width: 158, height: 158)
        let seed = IshiharaPlate.seed(for: date, radius: 75)
        let plate = IshiharaPlate.build(size: size, date: date, seed: seed, selection: .fixed(.deutan))

        let figure = plate.dots.filter { $0.green > $0.red }
        XCTAssertGreaterThan(figure.count, 10, "the hidden digit should colour a cluster of dots")

        let cx = figure.reduce(CGFloat(0)) { $0 + $1.x } / CGFloat(figure.count)
        let cy = figure.reduce(CGFloat(0)) { $0 + $1.y } / CGFloat(figure.count)
        let offX = abs(cx - plate.center.x) / plate.radius
        let offY = abs(cy - plate.center.y) / plate.radius
        XCTAssertLessThan(offX, 0.25, "figure centroid drifted in x (\(offX) of R) — mask scale bug?")
        XCTAssertLessThan(offY, 0.25, "figure centroid drifted in y (\(offY) of R) — mask scale bug?")
    }
}
