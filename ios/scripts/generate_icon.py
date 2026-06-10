#!/usr/bin/env python3
"""Generate the Color Vision Plates app icon appearances.

The source artwork is an Ishihara-style sibling of WhatColor's icon:
both use green/cyan plate dots and orange/red figure dots, while this
app uses a hidden triangle instead of WhatColor's magnifying glass.

Usage: python3 ios/scripts/generate_icon.py
"""

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps

SIZE = 1024
SCRIPT_DIR = Path(__file__).resolve().parent
SOURCE = SCRIPT_DIR / "icon-source.png"
OUT_DIR = (
    SCRIPT_DIR.parent
    / "ColorVisionTest"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
)


def load_source():
    source = Image.open(SOURCE).convert("RGB")
    if source.size != (SIZE, SIZE):
        source = ImageOps.fit(
            source,
            (SIZE, SIZE),
            method=Image.Resampling.LANCZOS,
        )
    return source


def dark_appearance(source):
    """Keep the plate colors while replacing its white field with charcoal."""
    pixels = source.load()
    dark = Image.new("RGB", source.size)
    output = dark.load()

    for y in range(SIZE):
        for x in range(SIZE):
            red, green, blue = pixels[x, y]
            saturation = max(red, green, blue) - min(red, green, blue)
            brightness = max(red, green, blue)

            if brightness > 205 and saturation < 45:
                # Preserve the source's soft edge shading against a dark field.
                shade = max(18, 42 - (brightness - 205) // 3)
                output[x, y] = (shade, shade, shade)
            else:
                output[x, y] = (
                    max(0, int(red * 0.88)),
                    max(0, int(green * 0.88)),
                    max(0, int(blue * 0.88)),
                )

    return ImageEnhance.Contrast(dark).enhance(1.08)


def tinted_appearance(source):
    """Create a high-contrast luminance mask that survives any system tint."""
    pixels = source.load()
    tinted = Image.new("L", source.size)
    output = tinted.load()

    for y in range(SIZE):
        for x in range(SIZE):
            red, green, blue = pixels[x, y]
            saturation = max(red, green, blue) - min(red, green, blue)
            brightness = max(red, green, blue)

            if brightness > 205 and saturation < 45:
                value = 22
            elif red > green * 1.25 and red > blue * 1.45:
                value = 238
            else:
                value = 118
            output[x, y] = value

    return tinted.filter(ImageFilter.GaussianBlur(radius=0.35)).convert("RGB")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source = load_source()

    source.save(OUT_DIR / "Icon-1024.png", optimize=True)
    dark_appearance(source).save(
        OUT_DIR / "Icon-1024-dark.png",
        optimize=True,
    )
    tinted_appearance(source).save(
        OUT_DIR / "Icon-1024-tinted.png",
        optimize=True,
    )

    print("wrote light, dark, and tinted 1024 px app icons")


if __name__ == "__main__":
    main()
