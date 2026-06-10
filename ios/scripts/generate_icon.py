#!/usr/bin/env python3
"""Generate the Color Vision Test app icon set.

Family sibling of the What Color Is This? icon (../../whatcolor):
the same six-wedge color wheel on the same near-black field with the
same white center disc — but where whatcolor's disc holds a "?"
(identify a color), this one holds the HRR screening triangle (test
your color vision). Geometry and palette were sampled from
whatcolor's Icon-1024.png so the two read as siblings on a home
screen.

Writes the three single-size (1024 px) appearance variants the asset
catalog references — light (mark on the dark field), dark (mark on
transparency; the system supplies its backdrop), and tinted
(luminance-separated grayscale + alpha). Xcode renders every device
size from these.

Usage: python3 ios/scripts/generate_icon.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersample factor for clean edges

# Sampled from whatcolor's Icon-1024.png.
FIELD = (26, 26, 26)
DISC = (242, 242, 242)
GLYPH = (17, 17, 17)
WHEEL_OUTER = 296 / 512  # of half-width
WHEEL_INNER = 168 / 512  # = white disc radius
# Clockwise from top, matching whatcolor's wedge order.
WEDGES = [
    (212, 64, 65),    # red
    (205, 103, 23),   # orange
    (205, 159, 10),   # gold
    (34, 207, 98),    # green
    (57, 122, 230),   # blue
    (142, 75, 202),   # purple
]

# Triangle: circumradius as a fraction of the disc radius, with a
# round-joined stroke so the corners aren't razor-sharp (the "?" has
# rounded terminals; this keeps the same visual weight).
TRI_R = 0.62
TRI_STROKE = 0.16

OUT_DIR = Path(__file__).resolve().parent.parent / "ColorVisionTest" / "Assets.xcassets" / "AppIcon.appiconset"


def draw_mark(disc_color, wedge_colors, glyph_color, background):
    """Render the wheel + disc + triangle at SIZE*SS on `background`
    (an RGBA tuple; use alpha 0 for the dark/tinted variants)."""
    s = SIZE * SS
    cx = cy = s / 2
    outer = WHEEL_OUTER * s / 2
    inner = WHEEL_INNER * s / 2

    img = Image.new("RGBA", (s, s), background)
    d = ImageDraw.Draw(img)

    # Six 60-degree wedges, clockwise from 12 o'clock. PIL's pieslice
    # measures degrees clockwise from 3 o'clock in y-down coordinates.
    box = [cx - outer, cy - outer, cx + outer, cy + outer]
    for i, color in enumerate(wedge_colors):
        start = -90 + i * 60
        d.pieslice(box, start, start + 60, fill=color + (255,))

    d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=disc_color + (255,))

    r = inner * TRI_R
    verts = [
        (cx, cy - r),
        (cx + r * math.cos(math.radians(30)), cy + r * math.sin(math.radians(30))),
        (cx - r * math.cos(math.radians(30)), cy + r * math.sin(math.radians(30))),
    ]
    stroke = r * TRI_STROKE
    fill = glyph_color + (255,)
    d.polygon(verts, fill=fill)
    d.line(verts + [verts[0]], fill=fill, width=round(stroke), joint="curve")
    for (vx, vy) in verts:  # round caps on the corners
        d.ellipse([vx - stroke / 2, vy - stroke / 2, vx + stroke / 2, vy + stroke / 2], fill=fill)

    return img.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # Light (default + App Store marketing): fully opaque.
    light = draw_mark(DISC, WEDGES, GLYPH, FIELD + (255,)).convert("RGB")
    light.save(OUT_DIR / "Icon-1024.png")
    print("wrote Icon-1024.png (light)")

    # Dark: same mark on transparency; the system supplies the backdrop.
    dark = draw_mark(DISC, WEDGES, GLYPH, (0, 0, 0, 0))
    dark.save(OUT_DIR / "Icon-1024-dark.png")
    print("wrote Icon-1024-dark.png (dark)")

    # Tinted: grayscale + alpha, separated on luminance so the mark
    # survives any tint color.
    tinted = draw_mark((235, 235, 235), [(120, 120, 120)] * 6, (30, 30, 30), (0, 0, 0, 0))
    tinted.save(OUT_DIR / "Icon-1024-tinted.png")
    print("wrote Icon-1024-tinted.png (tinted)")


if __name__ == "__main__":
    main()
