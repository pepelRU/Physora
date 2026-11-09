#!/usr/bin/env python3
"""Generate Physora's original app icon and launch artwork.

The mark is an abstract three-orbit atom drawn from scratch with Pillow.
No external artwork, stock image or third-party trademark is used.
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Physora" / "Resources" / "Assets.xcassets"
APPICON = ASSETS / "AppIcon.appiconset"
LAUNCH = ASSETS / "LaunchLogo.imageset"

ACCENT = (56, 169, 255)
ACCENT_BRIGHT = (116, 211, 255)
INK = (5, 12, 24)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def radial_background(size: int) -> Image.Image:
    """A quiet midnight gradient with a soft optical bloom in the centre."""
    small = 512
    pixels = Image.new("RGBA", (small, small))
    p = pixels.load()
    center = small / 2
    for y in range(small):
        for x in range(small):
            dx = (x - center) / center
            dy = (y - center) / center
            distance = min(1.0, math.sqrt(dx * dx + dy * dy))
            # Base midnight gradient, slightly lighter at top-left.
            top_light = max(0.0, 1.0 - (x + y) / (small * 2))
            r = int(lerp(4, 10, top_light))
            g = int(lerp(9, 22, top_light))
            b = int(lerp(18, 39, top_light))
            # Blue optical bloom behind the atom.
            bloom = max(0.0, 1.0 - distance) ** 2.6
            r = int(lerp(r, 18, bloom * 0.72))
            g = int(lerp(g, 51, bloom * 0.72))
            b = int(lerp(b, 82, bloom * 0.72))
            p[x, y] = (r, g, b, 255)

    return pixels.resize((size, size), Image.Resampling.LANCZOS)


def glow_circle(
    image: Image.Image,
    center: tuple[int, int],
    radius: int,
    color: tuple[int, int, int],
    alpha: int,
    blur: int,
) -> None:
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(*color, alpha))
    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def rotated_orbit(
    base: Image.Image,
    size: int,
    angle: float,
    ring_color: tuple[int, int, int],
    opacity: int,
    width: int,
) -> None:
    """Draw a rotated ellipse onto the icon with smooth anti-aliasing."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx = cy = size / 2
    rx, ry = size * 0.298, size * 0.102
    draw.ellipse(
        (cx - rx, cy - ry, cx + rx, cy + ry),
        outline=(*ring_color, opacity),
        width=width,
    )

    # One restrained specular highlight makes the thin ring feel dimensional.
    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hd = ImageDraw.Draw(highlight)
    hd.arc(
        (cx - rx, cy - ry, cx + rx, cy + ry),
        start=202,
        end=318,
        fill=(225, 247, 255, min(255, opacity + 45)),
        width=max(2, width // 2),
    )
    layer.alpha_composite(highlight)
    rotated = layer.rotate(angle, resample=Image.Resampling.BICUBIC, center=(cx, cy))
    base.alpha_composite(rotated)


def draw_atom(size: int = 4096) -> Image.Image:
    image = radial_background(size).convert("RGBA")
    draw = ImageDraw.Draw(image)
    c = size // 2

    # Very subtle ambient bloom around the orbits.
    glow_circle(image, (c, c), int(size * 0.30), (31, 153, 255), 28, int(size * 0.055))
    glow_circle(image, (c, c), int(size * 0.16), (56, 169, 255), 34, int(size * 0.04))

    width = max(6, int(size * 0.0145))
    for angle, color, opacity, w in (
        (-31, (76, 188, 255), 220, width),
        (31, (56, 169, 255), 205, int(width * 0.92)),
        (89, (128, 218, 255), 175, int(width * 0.85)),
    ):
        rotated_orbit(image, size, angle, color, opacity, max(3, w))

    # Electrons sit on the rings, each with a small atmospheric halo.
    electrons = [
        (int(c + size * 0.270), int(c - size * 0.045), 1.00),
        (int(c - size * 0.185), int(c + size * 0.168), 0.85),
        (int(c + size * 0.064), int(c + size * 0.262), 0.70),
    ]
    for ex, ey, strength in electrons:
        rad = int(size * 0.022 * strength)
        glow_circle(image, (ex, ey), int(rad * 3.1), ACCENT, 58, int(size * 0.018))
        draw = ImageDraw.Draw(image)
        draw.ellipse((ex - rad, ey - rad, ex + rad, ey + rad), fill=ACCENT_BRIGHT)
        inner = max(2, rad // 3)
        draw.ellipse(
            (ex - inner + rad // 5, ey - inner + rad // 5, ex + inner, ey + inner),
            fill=(244, 253, 255, 255),
        )

    # Nucleus: a luminous blue core with a crisp, jewel-like highlight.
    glow_circle(image, (c, c), int(size * 0.082), ACCENT, 118, int(size * 0.033))
    glow_circle(image, (c, c), int(size * 0.052), (135, 223, 255), 175, int(size * 0.016))
    draw = ImageDraw.Draw(image)
    nr = int(size * 0.029)
    draw.ellipse((c - nr, c - nr, c + nr, c + nr), fill=(148, 230, 255, 255))
    nr2 = int(size * 0.021)
    draw.ellipse((c - nr2, c - nr2, c + nr2, c + nr2), fill=(242, 253, 255, 255))
    highlight = max(2, int(size * 0.007))
    hx = c - int(size * 0.007)
    hy = c - int(size * 0.008)
    draw.ellipse((hx - highlight, hy - highlight, hx + highlight, hy + highlight), fill=(255, 255, 255, 255))

    return image


def save_png(image: Image.Image, path: Path, size: int | None = None, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    out = image
    if size is not None and out.size != (size, size):
        out = out.resize((size, size), Image.Resampling.LANCZOS)
    if opaque:
        out.convert("RGB").save(path, "PNG", optimize=True)
    else:
        out.convert("RGBA").save(path, "PNG", optimize=True)


def make_launch_logo(icon: Image.Image, background: str) -> Image.Image:
    """Return a transparent lockup from the icon mark, with a small wordmark."""
    canvas = Image.new("RGBA", (900, 900), (0, 0, 0, 0))
    mark_size = 620
    mark = icon.resize((mark_size, mark_size), Image.Resampling.LANCZOS)

    # Mask the square icon into a circular dark lens for light backgrounds.
    mask = Image.new("L", (mark_size, mark_size), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse((10, 10, mark_size - 10, mark_size - 10), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(2))
    canvas.alpha_composite(Image.composite(mark, Image.new("RGBA", mark.size, (0, 0, 0, 0)), mask), (140, 20))

    draw = ImageDraw.Draw(canvas)
    if background == "dark":
        word_color = (237, 247, 255, 255)
    else:
        word_color = (10, 24, 43, 255)
    dot_color = (*ACCENT, 255)

    font = load_wordmark_font(96)
    draw.text((450, 700), "PHYSORA", anchor="mm", fill=word_color, font=font)
    # Dot after the wordmark echoes the atomic nucleus.
    draw.ellipse((696, 692, 713, 709), fill=dot_color)
    return canvas


def load_wordmark_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "C:/Windows/Fonts/DejaVuSans-Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "arialbd.ttf",
        "DejaVuSans-Bold.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default(size=size)


def main() -> None:
    APPICON.mkdir(parents=True, exist_ok=True)
    LAUNCH.mkdir(parents=True, exist_ok=True)

    icon = draw_atom(4096)
    save_png(icon, APPICON / "AppIcon.png", 1024, opaque=True)
    save_png(icon, APPICON / "AppIcon-Dark.png", 1024, opaque=True)

    # Tinted artwork: a high-contrast monochrome mask on deep neutral ink.
    tinted = ImageOps.grayscale(icon)
    tinted = ImageOps.colorize(tinted, black=(17, 22, 32), white=(248, 251, 255)).convert("RGBA")
    save_png(tinted, APPICON / "AppIcon-Tinted.png", 1024, opaque=True)

    light = make_launch_logo(icon, "light")
    dark = make_launch_logo(icon, "dark")
    for scale, suffix in ((1, ""), (2, "@2x"), (3, "@3x")):
        size = 300 * scale
        # Use a clean padded lockup at each geometry.
        save_png(light, LAUNCH / f"LaunchLogo{suffix}.png", size)
        save_png(dark, LAUNCH / f"LaunchLogo-Dark{suffix}.png", size)


if __name__ == "__main__":
    main()
