#!/usr/bin/env python3
"""Generate the Color Vision Test app icon set.

A faithful Python port of the plate-generation math in index.html —
mulberry32 PRNG, Poisson-disk dot packing, CIELAB-with-noise colors via
labToHex — rendering an HRR-style triangle (drawShapeMask geometry)
with the control plate's palette (PLATES[0]: L* 65 warm figure vs
L* 38 cool field). The control palette is the deliberate choice: a
true vanishing plate would be invisible to exactly the people this
app is for, while the control plate is visible to everyone — it is
also what the in-app hero renders.

Deterministic: same seed as the plate (42), no session salt, like the
hero canvas. Writes every size AppIcon.appiconset references.

Usage: python3 ios/scripts/generate_icon.py
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 1024  # logical render size (matches the coordinate space)
SS = 4       # supersample factor for clean dot edges

# Equivalent hero-plate density: index.html uses minR 2.5 / maxR 6.5 on
# a ~360 px plate; scale to the 1024 px icon to preserve the look.
REF = 360.0
MIN_R = 2.5 * SIZE / REF
MAX_R = 6.5 * SIZE / REF
PAD = 0.8 * SIZE / REF  # canPlace spacing padding, scaled

# PLATES[0] — the control plate (index.html). FG/BG as {L, LR, a, aR, b, bR}.
PLATE_SEED = 42
FG = {"L": 65, "LR": 12, "a": 10, "aR": 16, "b": 15, "bR": 16}
BG = {"L": 38, "LR": 12, "a": -6, "aR": 16, "b": -10, "bR": 16}

CANVAS = (13, 13, 13)       # app background #0d0d0d
PLATE_FILL = (17, 17, 17)   # renderPlate's '#111' plate circle

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


# ── mulberry32 (exact 32-bit JS semantics) ──────────────────────────

def _i32(x):
    x &= 0xFFFFFFFF
    return x - 0x100000000 if x >= 0x80000000 else x


def _u32(x):
    return x & 0xFFFFFFFF


def mulberry32(seed):
    state = {"s": _i32(seed)}

    def rng():
        state["s"] = _i32(state["s"] + 0x6D2B79F5)
        s = state["s"]
        t = _i32((_u32(s) ^ (_u32(s) >> 15)) * _i32(1 | s))
        t = _i32(_i32(t + _i32((_u32(t) ^ (_u32(t) >> 7)) * _i32(61 | t))) ^ t)
        return (_u32(t) ^ (_u32(t) >> 14)) / 4294967296

    return rng


# ── labToHex pipeline (CIELAB → XYZ D65 → linear sRGB → gamma) ──────

def lab_to_rgb(L, a, b):
    delta = 6 / 29
    k = 3 * delta * delta

    def f_inv(t):
        return t * t * t if t > delta else k * (t - 4 / 29)

    fy = (L + 16) / 116
    X = 0.95047 * f_inv(fy + a / 500)
    Y = 1.00000 * f_inv(fy)
    Z = 1.08883 * f_inv(fy - b / 200)

    rl = 3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z
    gl = -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z
    bl = 0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z

    def gamma(c):
        c = max(0.0, min(1.0, c))
        return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055

    def byte(v):
        return round(max(0, min(255, v * 255)))

    return (byte(gamma(rl)), byte(gamma(gl)), byte(gamma(bl)))


def rnd_color(cfg, rng):
    return lab_to_rgb(
        cfg["L"] + (rng() - 0.5) * cfg["LR"],
        cfg["a"] + (rng() - 0.5) * cfg["aR"],
        cfg["b"] + (rng() - 0.5) * cfg["bR"],
    )


# ── poissonDiskSample (line-for-line port, same rng call order) ─────

def poisson_disk_sample(cx, cy, plate_r, min_r, max_r, rng):
    cell_size = min_r * 1.5 / math.sqrt(2)
    grid_w = math.ceil(plate_r * 2 / cell_size)
    grid = [-1] * (grid_w * grid_w)
    dots = []
    active = []

    def gi(x, y):
        gx = math.floor((x - cx + plate_r) / cell_size)
        gy = math.floor((y - cy + plate_r) / cell_size)
        if gx < 0 or gx >= grid_w or gy < 0 or gy >= grid_w:
            return -1
        return gy * grid_w + gx

    def can_place(x, y, r):
        if math.hypot(x - cx, y - cy) + r > plate_r - 1:
            return False
        if gi(x, y) < 0:
            return False
        gx = math.floor((x - cx + plate_r) / cell_size)
        gy = math.floor((y - cy + plate_r) / cell_size)
        for dy in range(-3, 4):
            for dx in range(-3, 4):
                nx, ny = gx + dx, gy + dy
                if nx < 0 or nx >= grid_w or ny < 0 or ny >= grid_w:
                    continue
                ni = ny * grid_w + nx
                if grid[ni] >= 0:
                    o = dots[grid[ni]]
                    if math.hypot(x - o["x"], y - o["y"]) < r + o["r"] + PAD:
                        return False
        return True

    def add(x, y):
        r = min_r + rng() * (max_r - min_r)
        if not can_place(x, y, r):
            return False
        i = len(dots)
        dots.append({"x": x, "y": y, "r": r})
        active.append(i)
        idx = gi(x, y)
        if idx >= 0:
            grid[idx] = i
        return True

    add(cx, cy)
    while active:
        ai = math.floor(rng() * len(active))
        src = dots[active[ai]]
        found = False
        for _ in range(30):
            a = rng() * math.pi * 2
            d = min_r * 2 + rng() * min_r * 2.5
            if add(src["x"] + math.cos(a) * d, src["y"] + math.sin(a) * d):
                found = True
                break
        if not found:
            active.pop(ai)
    return dots


# ── triangle mask (drawShapeMask geometry: fill + round stroke) ─────

def triangle_mask(size, cx, cy, plate_r):
    """Rasterize the HRR triangle as drawShapeMask does — apex up,
    filled, plus a round-joined stroke of width plateR*0.06 centered
    on the path. One icon-specific deviation: circumradius 0.52
    instead of the in-app 0.38, because a 0.38 figure turns to mush
    at the 29-58 px icon sizes."""
    r = plate_r * 0.52
    verts = [
        (cx, cy - r),
        (cx + r * 0.866, cy + r * 0.5),
        (cx - r * 0.866, cy + r * 0.5),
    ]
    stroke = plate_r * 0.06
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.polygon(verts, fill=255)
    d.line(verts + [verts[0]], fill=255, width=round(stroke), joint="curve")
    for (vx, vy) in verts:  # round caps at the corners
        d.ellipse([vx - stroke / 2, vy - stroke / 2, vx + stroke / 2, vy + stroke / 2], fill=255)
    return mask.load()


def main():
    s = SIZE
    cx = cy = s / 2
    plate_r = s / 2 - 4 * s / REF  # renderPlate's (size/2 - 4), scaled

    rng = mulberry32(PLATE_SEED)  # hero behavior: raw plate seed, no salt
    dots = poisson_disk_sample(cx, cy, plate_r, MIN_R, MAX_R, rng)
    mask = triangle_mask(s, cx, cy, plate_r)

    img = Image.new("RGB", (s * SS, s * SS), CANVAS)
    draw = ImageDraw.Draw(img)
    draw.ellipse(
        [(cx - plate_r - 2) * SS, (cy - plate_r - 2) * SS,
         (cx + plate_r + 2) * SS, (cy + plate_r + 2) * SS],
        fill=PLATE_FILL,
    )

    # Same per-dot rng order as renderPlate's forEach: 3 calls per dot
    # inside rndColor, mask sampled at floor(x), floor(y).
    for dot in dots:
        px, py = math.floor(dot["x"]), math.floor(dot["y"])
        is_shape = 0 <= px < s and 0 <= py < s and mask[px, py] > 128
        color = rnd_color(FG if is_shape else BG, rng)
        x, y, r = dot["x"] * SS, dot["y"] * SS, dot["r"] * SS
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    base = img.resize((SIZE, SIZE), Image.LANCZOS)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, px in SIZES.items():
        (base if px == SIZE else base.resize((px, px), Image.LANCZOS)).save(OUT_DIR / name)
        print(f"wrote {name} ({px}px)")


if __name__ == "__main__":
    main()
