#!/usr/bin/env python3
"""Generate deterministic premium raster assets for Zoo Drop."""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Zoo Drop" / "Assets.xcassets"
RNG = random.Random(240503)


def lerp(a: int, b: int, t: float) -> int:
    return round(a + (b - a) * t)


def mix(c1: tuple[int, int, int, int], c2: tuple[int, int, int, int], t: float) -> tuple[int, int, int, int]:
    return tuple(lerp(a, b, t) for a, b in zip(c1, c2))  # type: ignore[return-value]


def ensure_group(name: str) -> Path:
    path = ASSETS / name
    path.mkdir(parents=True, exist_ok=True)
    contents = path / "Contents.json"
    if not contents.exists():
        contents.write_text(
            json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n",
            encoding="utf-8",
        )
    return path


def write_imageset(group: str, name: str, image: Image.Image) -> None:
    group_path = ensure_group(group)
    set_path = group_path / f"{name}.imageset"
    set_path.mkdir(parents=True, exist_ok=True)
    filename = f"{name}.png"
    image.save(set_path / filename, optimize=True, compress_level=9)
    payload = {
        "images": [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (set_path / "Contents.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def vertical_gradient(size: tuple[int, int], stops: list[tuple[float, tuple[int, int, int, int]]]) -> Image.Image:
    width, height = size
    img = Image.new("RGBA", size)
    pix = img.load()
    stops = sorted(stops)
    for y in range(height):
        pos = y / max(1, height - 1)
        lower = stops[0]
        upper = stops[-1]
        for i in range(len(stops) - 1):
            if stops[i][0] <= pos <= stops[i + 1][0]:
                lower, upper = stops[i], stops[i + 1]
                break
        span = max(0.0001, upper[0] - lower[0])
        t = max(0.0, min(1.0, (pos - lower[0]) / span))
        color = mix(lower[1], upper[1], t)
        for x in range(width):
            pix[x, y] = color
    return img


def ellipse_layer(size: tuple[int, int], count: int, palette: list[tuple[int, int, int, int]], blur: float) -> Image.Image:
    width, height = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    for _ in range(count):
        radius = RNG.randint(width // 18, width // 5)
        x = RNG.randint(-radius, width)
        y = RNG.randint(-radius, height)
        color = RNG.choice(palette)
        draw.ellipse((x, y, x + radius * 2, y + radius * 2), fill=color)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def add_noise_alpha(img: Image.Image, alpha: int = 10) -> Image.Image:
    width, height = img.size
    noise = Image.new("RGBA", img.size, (0, 0, 0, 0))
    pix = noise.load()
    for y in range(0, height, 2):
        for x in range(0, width, 2):
            value = RNG.randint(-alpha, alpha)
            color = (255, 255, 255, max(0, value)) if value > 0 else (0, 0, 0, max(0, -value))
            pix[x, y] = color
    return Image.alpha_composite(img, noise.filter(ImageFilter.GaussianBlur(0.35)))


def draw_leaf(draw: ImageDraw.ImageDraw, cx: float, cy: float, scale: float, angle: float, color: tuple[int, int, int, int]) -> None:
    points = []
    for i in range(24):
        t = i / 23
        theta = (t - 0.5) * math.pi
        radius = math.sin(t * math.pi)
        x = math.cos(theta) * 34 * radius * scale
        y = (t - 0.5) * 140 * scale
        ca, sa = math.cos(angle), math.sin(angle)
        points.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    for i in range(23, -1, -1):
        t = i / 23
        theta = (t - 0.5) * math.pi
        radius = math.sin(t * math.pi)
        x = -math.cos(theta) * 34 * radius * scale
        y = (t - 0.5) * 140 * scale
        ca, sa = math.cos(angle), math.sin(angle)
        points.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    draw.polygon(points, fill=color)


def safari_sky() -> Image.Image:
    img = vertical_gradient(
        (1024, 1536),
        [
            (0.0, (38, 72, 132, 255)),
            (0.32, (76, 166, 186, 255)),
            (0.68, (255, 188, 112, 255)),
            (1.0, (251, 128, 92, 255)),
        ],
    )
    img = Image.alpha_composite(img, ellipse_layer(img.size, 28, [(255, 242, 196, 28), (92, 224, 204, 18)], 58))
    draw = ImageDraw.Draw(img, "RGBA")
    for i in range(10):
        x = 90 + i * 112 + RNG.randint(-32, 32)
        y = RNG.randint(88, 620)
        r = RNG.randint(2, 5)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(255, 250, 210, 155))
    return add_noise_alpha(img, 7)


def safari_horizon() -> Image.Image:
    img = Image.new("RGBA", (1024, 1536), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((-260, 1030, 1284, 1690), fill=(58, 139, 92, 220))
    draw.ellipse((-180, 1110, 1180, 1710), fill=(34, 101, 83, 235))
    for x in range(-80, 1100, 110):
        h = RNG.randint(190, 360)
        trunk_w = RNG.randint(10, 20)
        draw.rounded_rectangle((x + 42, 1010 - h, x + 42 + trunk_w, 1215), radius=8, fill=(60, 87, 61, 210))
        crown = (x, 890 - h, x + 130, 1030 - h)
        draw.ellipse(crown, fill=(33, 122, 86, 220))
        draw.ellipse((crown[0] + 34, crown[1] - 36, crown[2] + 34, crown[3] - 16), fill=(48, 153, 104, 205))
    draw.rectangle((0, 1250, 1024, 1536), fill=(52, 112, 74, 245))
    for i in range(70):
        x = RNG.randint(0, 1024)
        y = RNG.randint(1210, 1536)
        length = RNG.randint(20, 70)
        color = RNG.choice([(103, 183, 95, 120), (180, 211, 90, 90), (38, 105, 68, 130)])
        draw.line((x, y, x + RNG.randint(-14, 18), y - length), fill=color, width=RNG.randint(2, 5))
    return img.filter(ImageFilter.GaussianBlur(0.2))


def safari_canopy() -> Image.Image:
    img = Image.new("RGBA", (1024, 1536), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    palette = [(20, 84, 70, 185), (36, 128, 86, 155), (100, 178, 90, 120), (238, 188, 77, 105)]
    for _ in range(115):
        edge = RNG.choice(["top", "left", "right"])
        if edge == "top":
            cx, cy = RNG.randint(-40, 1064), RNG.randint(-70, 230)
            angle = RNG.uniform(-0.9, 0.9)
        elif edge == "left":
            cx, cy = RNG.randint(-95, 90), RNG.randint(0, 1120)
            angle = RNG.uniform(-1.5, 0.2)
        else:
            cx, cy = RNG.randint(934, 1120), RNG.randint(0, 1120)
            angle = RNG.uniform(-0.2, 1.5)
        draw_leaf(draw, cx, cy, RNG.uniform(0.55, 1.4), angle, RNG.choice(palette))
    return img.filter(ImageFilter.GaussianBlur(0.35))


def aurora_overlay() -> Image.Image:
    img = Image.new("RGBA", (1024, 1536), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for band in range(5):
        points = []
        y_base = 250 + band * 115
        for x in range(-80, 1120, 50):
            y = y_base + math.sin((x + band * 71) / 118) * (64 + band * 7)
            points.append((x, y))
        color = RNG.choice([(99, 247, 198, 52), (255, 205, 106, 42), (93, 172, 255, 48)])
        draw.line(points, fill=color, width=RNG.randint(48, 82), joint="curve")
    for _ in range(95):
        x, y = RNG.randint(0, 1024), RNG.randint(80, 1030)
        r = RNG.choice([1, 1, 2, 3])
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(255, 249, 208, RNG.randint(70, 180)))
    return img.filter(ImageFilter.GaussianBlur(2.0))


def glass_sheen() -> Image.Image:
    img = Image.new("RGBA", (768, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for y in range(256):
        t = y / 255
        alpha = int(72 * max(0.0, 1.0 - t * 1.8))
        draw.line((36, y, 732, y), fill=(255, 255, 255, alpha), width=1)
    draw.rounded_rectangle((28, 22, 740, 234), radius=88, outline=(255, 255, 255, 130), width=4)
    draw.rounded_rectangle((60, 42, 708, 102), radius=44, fill=(255, 255, 255, 86))
    for offset, alpha in [(0, 105), (22, 70), (45, 38)]:
        draw.line((70 + offset, 214, 700 + offset, 34), fill=(255, 255, 255, alpha), width=18)
    return img.filter(ImageFilter.GaussianBlur(0.35))


def button_glow() -> Image.Image:
    img = Image.new("RGBA", (768, 384), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for i in range(40, 0, -1):
        alpha = int(4.8 * i)
        draw.rounded_rectangle((64 - i, 86 - i, 704 + i, 298 + i), radius=96 + i, fill=(255, 210, 92, alpha))
    draw.rounded_rectangle((64, 86, 704, 298), radius=92, fill=(255, 197, 73, 118))
    draw.rounded_rectangle((80, 103, 688, 282), radius=78, fill=(255, 255, 255, 35))
    return img.filter(ImageFilter.GaussianBlur(2.2))


def glow_ring(size: int, palette: list[tuple[int, int, int]]) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    cx = cy = size // 2
    for i in range(size // 2 - 8, size // 5, -9):
        t = i / (size // 2)
        color = palette[int(t * (len(palette) - 1)) % len(palette)]
        draw.ellipse((cx - i, cy - i, cx + i, cy + i), outline=(*color, int(92 * (1 - abs(t - 0.62)))), width=7)
    for _ in range(32):
        a = RNG.random() * math.tau
        radius = RNG.randint(size // 4, size // 2 - 24)
        x = cx + math.cos(a) * radius
        y = cy + math.sin(a) * radius
        r = RNG.randint(4, 14)
        color = RNG.choice(palette)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*color, RNG.randint(120, 220)))
    return img.filter(ImageFilter.GaussianBlur(1.0))


def sparkle_cluster() -> Image.Image:
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for _ in range(44):
        x, y = RNG.randint(48, 464), RNG.randint(48, 464)
        r = RNG.randint(3, 18)
        color = RNG.choice([(255, 244, 170), (117, 235, 207), (255, 153, 118), (255, 255, 255)])
        draw.line((x - r, y, x + r, y), fill=(*color, RNG.randint(130, 230)), width=RNG.randint(2, 5))
        draw.line((x, y - r, x, y + r), fill=(*color, RNG.randint(130, 230)), width=RNG.randint(2, 5))
        if RNG.random() < 0.45:
            draw.ellipse((x - r // 3, y - r // 3, x + r // 3, y + r // 3), fill=(*color, 190))
    return img.filter(ImageFilter.GaussianBlur(0.25))


def soft_particle() -> Image.Image:
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for r in range(112, 3, -4):
        alpha = int(180 * (1 - r / 112) ** 1.45)
        draw.ellipse((128 - r, 128 - r, 128 + r, 128 + r), fill=(255, 230, 128, alpha))
    draw.ellipse((100, 92, 146, 138), fill=(255, 255, 255, 132))
    return img.filter(ImageFilter.GaussianBlur(1.2))


def starburst() -> Image.Image:
    img = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    cx = cy = 256
    for i in range(28):
        a = i / 28 * math.tau
        length = 170 + (i % 4) * 34
        width = 9 if i % 2 else 16
        end = (cx + math.cos(a) * length, cy + math.sin(a) * length)
        draw.line((cx, cy, *end), fill=(255, 224, 123, 72), width=width)
    draw.ellipse((150, 150, 362, 362), fill=(255, 232, 126, 78))
    draw.ellipse((210, 210, 302, 302), fill=(255, 255, 255, 185))
    return img.filter(ImageFilter.GaussianBlur(1.3))


def merge_ribbons() -> Image.Image:
    img = Image.new("RGBA", (768, 768), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    colors = [(73, 225, 182, 155), (255, 201, 91, 150), (255, 124, 118, 125)]
    for i, color in enumerate(colors):
        points = []
        for x in range(80, 690, 28):
            y = 384 + math.sin((x + i * 88) / 76) * (92 + i * 12)
            points.append((x, y))
        draw.line(points, fill=color, width=42 - i * 6, joint="curve")
    return img.filter(ImageFilter.GaussianBlur(1.8))


def reward_banner(title_color: tuple[int, int, int, int], accent: tuple[int, int, int, int], kind: str) -> Image.Image:
    img = Image.new("RGBA", (1200, 520), (0, 0, 0, 0))
    base = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(base, "RGBA")
    draw.rounded_rectangle((54, 64, 1146, 456), radius=82, fill=title_color)
    for i in range(42):
        alpha = int(3.5 * (42 - i))
        draw.rounded_rectangle((54 - i, 64 - i, 1146 + i, 456 + i), radius=82 + i, outline=(*accent[:3], alpha), width=2)
    draw.rounded_rectangle((88, 92, 1112, 220), radius=58, fill=(255, 255, 255, 48))
    for x in range(110, 1100, 96):
        r = RNG.randint(10, 28)
        y = RNG.randint(120, 388)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(*accent[:3], RNG.randint(38, 90)))
    if kind == "daily":
        draw.ellipse((785, 106, 1040, 364), fill=(255, 224, 94, 230))
        draw.ellipse((844, 154, 981, 290), fill=(255, 255, 255, 74))
        draw.rounded_rectangle((158, 282, 610, 364), radius=40, fill=(26, 81, 72, 130))
    elif kind == "event":
        for i in range(7):
            x = 760 + i * 42
            draw.polygon([(x, 118), (x + 34, 306), (x - 44, 306)], fill=(*accent[:3], 145))
        draw.rounded_rectangle((146, 274, 680, 370), radius=48, fill=(255, 255, 255, 44))
    else:
        draw.rounded_rectangle((744, 132, 1040, 342), radius=62, fill=(255, 255, 255, 48))
        draw.ellipse((802, 166, 982, 346), fill=(*accent[:3], 185))
        draw.rounded_rectangle((144, 278, 690, 374), radius=48, fill=(18, 68, 95, 120))
    return Image.alpha_composite(img, base.filter(ImageFilter.GaussianBlur(0.15)))


def eye_open() -> Image.Image:
    img = Image.new("RGBA", (256, 160), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((28, 20, 228, 140), fill=(255, 250, 230, 245))
    draw.ellipse((78, 22, 178, 140), fill=(37, 91, 97, 255))
    draw.ellipse((106, 52, 154, 118), fill=(17, 35, 42, 255))
    draw.ellipse((98, 44, 122, 70), fill=(255, 255, 255, 220))
    draw.arc((26, 18, 230, 142), 190, 350, fill=(42, 39, 43, 220), width=10)
    return img


def eye_blink() -> Image.Image:
    img = Image.new("RGBA", (256, 160), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((34, 72, 222, 92), radius=12, fill=(42, 39, 43, 230))
    draw.arc((30, 35, 226, 126), 12, 168, fill=(255, 245, 215, 170), width=10)
    return img.filter(ImageFilter.GaussianBlur(0.2))


def sleepy_lid() -> Image.Image:
    img = Image.new("RGBA", (256, 160), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.pieslice((26, 0, 230, 170), 180, 360, fill=(247, 174, 114, 210))
    draw.arc((30, 8, 226, 152), 185, 355, fill=(61, 49, 47, 180), width=8)
    return img.filter(ImageFilter.GaussianBlur(0.45))


def eye_sparkle() -> Image.Image:
    img = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for r, alpha in [(66, 34), (42, 56), (20, 120)]:
        draw.ellipse((96 - r, 96 - r, 96 + r, 96 + r), fill=(255, 255, 255, alpha))
    draw.line((34, 96, 158, 96), fill=(255, 255, 255, 220), width=7)
    draw.line((96, 34, 96, 158), fill=(255, 255, 255, 220), width=7)
    draw.line((56, 56, 136, 136), fill=(255, 234, 132, 160), width=4)
    draw.line((136, 56, 56, 136), fill=(255, 234, 132, 160), width=4)
    return img.filter(ImageFilter.GaussianBlur(0.35))


def cheek_glow() -> Image.Image:
    img = Image.new("RGBA", (256, 160), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for r in range(72, 2, -5):
        alpha = int(80 * (1 - r / 72) ** 1.2)
        draw.ellipse((128 - r, 80 - r * 0.58, 128 + r, 80 + r * 0.58), fill=(255, 129, 132, alpha))
    return img.filter(ImageFilter.GaussianBlur(1.5))


def vignette() -> Image.Image:
    size = (1024, 1536)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    alpha = Image.new("L", size, 0)
    pix = alpha.load()
    cx, cy = size[0] / 2, size[1] / 2
    max_dist = math.hypot(cx, cy)
    for y in range(size[1]):
        for x in range(size[0]):
            d = math.hypot((x - cx) * 0.82, (y - cy) * 0.68) / max_dist
            pix[x, y] = int(max(0.0, min(1.0, (d - 0.34) / 0.36)) * 132)
    img.putalpha(alpha.filter(ImageFilter.GaussianBlur(18)))
    return ImageChops.multiply(Image.new("RGBA", size, (24, 38, 50, 255)), img)


def main() -> None:
    write_imageset("Backgrounds", "premium_safari_sky", safari_sky())
    write_imageset("Backgrounds", "premium_safari_horizon", safari_horizon())
    write_imageset("Backgrounds", "premium_safari_canopy", safari_canopy())
    write_imageset("Backgrounds", "premium_safari_aurora", aurora_overlay())
    write_imageset("Backgrounds", "premium_safari_vignette", vignette())

    write_imageset("FX", "fx_button_glass_sheen", glass_sheen())
    write_imageset("FX", "fx_button_gold_glow", button_glow())
    write_imageset("FX", "fx_merge_glow_ring", glow_ring(768, [(77, 229, 190), (255, 211, 102), (255, 132, 117)]))
    write_imageset("FX", "fx_merge_ribbons", merge_ribbons())
    write_imageset("FX", "fx_sparkle_cluster", sparkle_cluster())
    write_imageset("FX", "fx_soft_gold_particle", soft_particle())
    write_imageset("FX", "fx_reward_starburst", starburst())

    write_imageset("EventBanners", "banner_daily_reward", reward_banner((38, 132, 119, 242), (255, 218, 96, 255), "daily"))
    write_imageset("EventBanners", "banner_safari_event", reward_banner((50, 105, 167, 242), (106, 238, 194, 255), "event"))
    write_imageset("EventBanners", "banner_zoo_pass", reward_banner((107, 77, 155, 242), (255, 205, 96, 255), "pass"))

    write_imageset("Animals", "animal_eye_open_overlay", eye_open())
    write_imageset("Animals", "animal_eye_blink_overlay", eye_blink())
    write_imageset("Animals", "animal_sleepy_lid_overlay", sleepy_lid())
    write_imageset("Animals", "animal_eye_sparkle_overlay", eye_sparkle())
    write_imageset("Animals", "animal_cheek_glow_overlay", cheek_glow())


if __name__ == "__main__":
    main()
