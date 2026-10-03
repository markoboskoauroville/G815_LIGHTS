# make_icon.py — G815 Lights' icon (Marko, 3.10.2026: "one big G and ... 815 ... background is black and letters
# can be glowing in the white color"). Draws AppIcon.icns from nothing: python3 make_icon.py
import os, subprocess
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 1024
FONT = "/System/Library/Fonts/SFNSRounded.ttf"
if not os.path.exists(FONT): FONT = "/System/Library/Fonts/Helvetica.ttc"

def font(size, weight=700):
    f = ImageFont.truetype(FONT, size)
    try: f.set_variation_by_axes([weight])
    except Exception: pass
    return f

def icon():
    base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # the macOS tile: 824 square, radius 185, centred, black
    tile = Image.new("L", (S, S), 0)
    ImageDraw.Draw(tile).rounded_rectangle((100, 100, 924, 924), radius=185, fill=255)
    ground = Image.new("RGBA", (S, S), (6, 7, 9, 255))
    base.paste(ground, (0, 0), tile)
    # the letters, white, on their own layer
    text = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(text)
    g, n = font(500, 800), font(190, 700)
    d.text((S / 2, 455), "G", font=g, fill=255, anchor="mm")
    d.text((S / 2, 760), "815", font=n, fill=255, anchor="mm")
    # the glow: the letters blurred wide and soft, then tight, then the letters themselves
    out = base.copy()
    for radius, strength in [(48, 0.55), (18, 0.8), (5, 0.9)]:
        halo = text.filter(ImageFilter.GaussianBlur(radius)).point(lambda v: int(v * strength))
        out.paste(Image.new("RGBA", (S, S), (235, 242, 255, 255)), (0, 0), Image.composite(halo, Image.new("L", (S, S), 0), tile))
    out.paste(Image.new("RGBA", (S, S), (255, 255, 255, 255)), (0, 0), text)
    return out

im = icon()
im.save("icon_1024.png")
os.makedirs("AppIcon.iconset", exist_ok=True)
for s in [16, 32, 128, 256, 512]:
    im.resize((s, s), Image.LANCZOS).save(f"AppIcon.iconset/icon_{s}x{s}.png")
    im.resize((s * 2, s * 2), Image.LANCZOS).save(f"AppIcon.iconset/icon_{s}x{s}@2x.png")
subprocess.run(["iconutil", "-c", "icns", "AppIcon.iconset", "-o", "AppIcon.icns"], check=True)
subprocess.run(["rm", "-rf", "AppIcon.iconset"])
print("AppIcon.icns")
