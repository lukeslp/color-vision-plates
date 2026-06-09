#!/usr/bin/env python3
"""Generate the Color Vision Test app icon set.

An Ishihara-style plate: a packed field of khaki/olive dots with an
HRR-style triangle figure picked out in orange-red. Deterministic
(fixed seed) so regeneration is reproducible. Writes every size the
AppIcon.appiconset Contents.json references.

Usage: python3 ios/scripts/generate_icon.py
"""

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersample factor for clean dot edges
SEED = 1917  # Ishihara's publication year

OUT_DIR = Path(__file__).resolve().parent.parent / "ColorVisionTest" / "Assets.xcassets" / "AppIcon.appiconset"

SIZES = {
    "Icon-20.png": 20,
    "Icon-29.png": 29,
    "Icon-40.png": 40,
    "Icon-58.png": 58,
    "Icon-60.png": 60,
    "Icon-76.png": 76,
    "Icon-80.png": 80,
    "Icon-87.png": 87,
    "Icon-120.png": 120,
    "Icon-152.png": 152,
    "Icon-167.png": 167,
    "Icon-180.png": 180,
    "Icon-1024.png": 1024,
}

# Classic plate palettes (sRGB). Background: olive/khaki field.
# Figure: orange/vermilion family — high chroma so the triangle stays
# legible at 20 px even for trichromats with the icon at a glance.
BG_COLORS = [
    (148, 138, 84), (164, 152, 96), (130, 124, 78),
    (178, 166, 110), (120, 116, 80), (157, 149, 99),
]
FIG_COLORS = [
    (224, 102, 60), (238, 126, 70), (204, 84, 52),
    (242, 142, 88), (216, 110, 74),
]
CANVAS = (13, 13, 13)  # matches the web --bg #0d0d0d


def in_triangle(px, py, cx, cy, r):
    """Point-in-equilateral-triangle, apex up, circumradius r."""
    verts = []
    for k in range(3):
        ang = -math.pi / 2 + k * 2 * math.pi / 3
        verts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    (x1, y1), (x2, y2), (x3, y3) = verts
    d1 = (px - x2) * (y1 - y2) - (x1 - x2) * (py - y2)
    d2 = (px - x3) * (y2 - y3) - (x2 - x3) * (py - y3)
    d3 = (px - x1) * (y3 - y1) - (x3 - x1) * (py - y1)
    neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (neg and pos)


def main():
    rng = random.Random(SEED)
    s = SIZE * SS
    img = Image.new("RGB", (s, s), CANVAS)
    draw = ImageDraw.Draw(img)

    cx = cy = s / 2
    tri_r = s * 0.34          # figure circumradius
    tri_cy = cy + s * 0.02    # optical centering: triangle reads high otherwise

    # Greedy dot packing with grid acceleration.
    cell = int(s * 0.012)
    grid = {}
    dots = []

    def collides(x, y, r):
        gx, gy = int(x // cell), int(y // cell)
        reach = int(r // cell) + 3
        for ix in range(gx - reach, gx + reach + 1):
            for iy in range(gy - reach, gy + reach + 1):
                for (ox, oy, orad) in grid.get((ix, iy), ()):
                    if (x - ox) ** 2 + (y - oy) ** 2 < (r + orad + s * 0.002) ** 2:
                        return True
        return False

    attempts = 150000
    for _ in range(attempts):
        r = rng.uniform(s * 0.008, s * 0.026)
        x = rng.uniform(r, s - r)
        y = rng.uniform(r, s - r)
        if collides(x, y, r):
            continue
        grid.setdefault((int(x // cell), int(y // cell)), []).append((x, y, r))
        dots.append((x, y, r))

    for (x, y, r) in dots:
        if in_triangle(x, y, cx, tri_cy, tri_r):
            color = rng.choice(FIG_COLORS)
        else:
            color = rng.choice(BG_COLORS)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    base = img.resize((SIZE, SIZE), Image.LANCZOS)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, px in SIZES.items():
        (base if px == SIZE else base.resize((px, px), Image.LANCZOS)).save(OUT_DIR / name)
        print(f"wrote {name} ({px}px)")


if __name__ == "__main__":
    main()
