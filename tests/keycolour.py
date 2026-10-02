"""keycolour.py <png> [x0 y0 x1 y1] — the colour the camera sees on lit keys: the mean of the
brightest pixels (the legends), and that colour's hue. Used to compare what was sent with what is seen."""
import sys, colorsys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGB')
if len(sys.argv) > 5: im = im.crop(tuple(int(v) for v in sys.argv[2:6]))
px = [p for p in im.getdata() if max(p) > 60]
px.sort(key=lambda p: -sum(p)); px = px[:max(20, len(px) // 5)]
if not px: print("dark"); sys.exit()
r, g, b = (sum(p[i] for p in px) / len(px) for i in range(3))
h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
print("rgb %3d %3d %3d  hue %3d  sat %.2f  (%d px)" % (r, g, b, h * 360, s, len(px)))
