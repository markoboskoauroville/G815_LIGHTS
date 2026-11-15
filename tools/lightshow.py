#!/usr/bin/env python3
"""lightshow.py — 10 moving patterns on the G815 through `g815 serve` (no new build needed).
Liveness display for the camera (Marko, 15.11.2026). Usage: lightshow.py [seconds_per_pattern=25]
Stop: kill the PID in ~/.g815/lightshow.pid  (or: pkill -f lightshow.py). A bank repaint is `g815` app's own."""
import json, math, os, random, subprocess, sys, time, colorsys, signal

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
KB = json.load(open(os.path.join(ROOT, "layout.json")))["keys"]
SEC = float(sys.argv[1]) if len(sys.argv) > 1 else 25.0
G815 = os.path.join(ROOT, "build", "g815")

keys = []
for k in KB:
    keys.append(dict(i=int(k["id"], 16), cx=k["x"] + k["w"] / 2, cy=k["y"] + k["h"] / 2, x=k["x"], y=k["y"], l=k["l"]))
W, H = 24.0, 7.5
frow = sorted([k for k in keys if abs(k["y"] - 1.25) < .01 and (k["l"].startswith("F") or k["l"] == "ESC")], key=lambda k: k["x"])
main = [k for k in keys if k["y"] >= 2.4]
# border = main block keys on the outer ring
def ring_order():
    cx = sum(k["cx"] for k in main) / len(main); cy = sum(k["cy"] for k in main) / len(main)
    return sorted(main, key=lambda k: math.atan2(k["cy"] - cy, k["cx"] - cx))

proc = subprocess.Popen([G815, "serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
last = {}
_fullat = [0.0]
def send(frame):
    if time.time() - _fullat[0] > 2: last.clear(); _fullat[0] = time.time()   # the app repaints its bank every 15 s: resend all every 2 s
    parts = []
    for i, c in frame.items():
        if last.get(i) != c:
            parts.append("%02x:%02x%02x%02x" % (i, *c)); last[i] = c
    if not parts: return
    proc.stdin.write("paint " + " ".join(parts) + "\n"); proc.stdin.flush()
    proc.stdout.readline()

def hsv(h, s=1, v=1):
    r, g, b = colorsys.hsv_to_rgb(h % 1, s, v); return (int(r * 255), int(g * 255), int(b * 255))
BLACK = (0, 0, 0)
def blank(): return {k["i"]: BLACK for k in keys}

# 3x5 digits
FONT = {"0":"111101101101111","1":"010110010010111","2":"111001111100111","3":"111001111001111","4":"101101111001001",
        "5":"111100111001111","6":"111100111101111","7":"111001001001001","8":"111101111101111","9":"111101111001111"}
rows_y = sorted({k["y"] for k in main})  # 5 rows 2.5..6.5
def cell(k):  # (col,row) grid cell of a main key
    return (int(k["cx"] - 1.5), rows_y.index(k["y"]))
cellkeys = {}
for k in main: cellkeys.setdefault(cell(k), []).append(k)

def p_sweep(t, f):
    pos = (t * 8) % (W + 4) - 2
    for k in keys:
        d = abs(k["cx"] - pos); 
        if d < 2: f[k["i"]] = hsv(t * .05, 1, 1 - d / 2)
def p_rainbow(t, f):
    for k in keys: f[k["i"]] = hsv(k["cx"] / 14 - t * .4 + k["cy"] * .03)
def p_digits(t, f):
    s = int(t) % 100; txt = "%02d" % s
    for n, ch in enumerate(txt):
        for j, bit in enumerate(FONT[ch]):
            if bit == "1":
                col, row = 2 + n * 4 + j % 3, j // 3
                for k in cellkeys.get((col + 1, row), []): f[k["i"]] = (255, 255, 255) if n == 0 else (255, 160, 0)
    for k in main:  # dim background so the digits stand out
        f.setdefault(k["i"], (0, 0, 25))
def p_rain(t, f, st={}):
    if "d" not in st or st.get("t0") != getattr(p_rain, "t0", None): st["d"] = []; st["t0"] = p_rain.t0
    if random.random() < 0.45: st["d"].append([random.uniform(1.5, 16), 1.0, random.uniform(5, 9)])
    nd = []
    for d in st["d"]:
        d[1] += d[2] * .06
        if d[1] < 7.5: nd.append(d)
    st["d"] = nd
    for d in nd:
        for k in main:
            if abs(k["cx"] - d[0]) < .7:
                dy = d[1] - k["cy"]
                if 0 <= dy < 2.2: f[k["i"]] = (0, int(255 * (1 - dy / 2.2)), 255)
def p_ripple(t, f):
    cx, cy = 8.7, 4.5
    for k in keys:
        d = math.hypot(k["cx"] - cx, (k["cy"] - cy) * 1.6)
        v = max(0, math.cos((d - t * 6) * 1.2)) ** 3
        f[k["i"]] = hsv(.55 + d * .02, 1, v)
def p_scan(t, f):
    y = 1.2 + (abs(((t * 3) % 12) - 6) / 6) * 6
    for k in keys:
        d = abs(k["cy"] - y)
        if d < 1.1: f[k["i"]] = (0, int(255 * (1.1 - d) / 1.1), 60)
def p_checker(t, f):
    ph = int(t) % 2
    for k in keys: f[k["i"]] = (255, 0, 80) if (int(k["cx"]) + int(k["cy"]) + ph) % 2 == 0 else (0, 40, 255)
def p_chase(t, f):
    ring = ring_order(); n = len(ring)
    for j, k in enumerate(ring):
        d = (j - t * 12) % n
        if d < 12: f[k["i"]] = hsv(j / n, 1, 1 - d / 12)
def p_sparkle(t, f, st={}):
    for k in random.sample(keys, 10): st[k["i"]] = 1.0
    for i in list(st):
        st[i] -= .12
        if st[i] <= 0: del st[i]
        else: f[i] = (int(255 * st[i]), int(255 * st[i]), int(255 * st[i] ** 2))
def p_heart(t, f):
    ph = (t * 1.1) % 1
    v = max(math.exp(-((ph - .1) / .06) ** 2), .7 * math.exp(-((ph - .3) / .08) ** 2))
    for k in keys: f[k["i"]] = (int(255 * v), 0, int(30 * v))

PATTERNS = [("sweep", p_sweep), ("rainbow", p_rainbow), ("seconds-digits", p_digits), ("rain", p_rain), ("ripple", p_ripple),
            ("scan", p_scan), ("checker-1Hz", p_checker), ("border-chase", p_chase), ("sparkle", p_sparkle), ("heartbeat", p_heart)]

def counter(f):  # F-row: binary seconds (F1..F6, blue) + ESC heartbeat toggling each second
    s = int(time.time()) % 60
    fk = [k for k in frow if k["l"] != "ESC"]
    for b in range(6):
        on = (s >> b) & 1
        f[fk[b]["i"]] = (255, 255, 0) if on else (40, 0, 0)
    for k in fk[6:]: f[k["i"]] = (0, 0, 0)
    esc = [k for k in frow if k["l"] == "ESC"][0]
    f[esc["i"]] = (0, 255, 0) if s % 2 else (255, 0, 0)

def stop(*a):
    try: os.remove(os.path.expanduser("~/.g815/lightshow.pid"))
    except OSError: pass
    sys.exit(0)
signal.signal(signal.SIGTERM, stop); signal.signal(signal.SIGINT, stop)
os.makedirs(os.path.expanduser("~/.g815"), exist_ok=True)
open(os.path.expanduser("~/.g815/lightshow.pid"), "w").write(str(os.getpid()))
log = open(os.path.expanduser("~/.g815/lightshow.log"), "a")
while True:
    for name, fn in PATTERNS:
        t0 = time.time(); p_rain.t0 = t0
        print(time.strftime("%H:%M:%S"), name, file=log, flush=True)
        while time.time() - t0 < SEC:
            t = time.time() - t0; f = blank(); fn(t, f); counter(f)
            try: send(f)
            except Exception as e:
                print("send failed", e, file=log, flush=True); time.sleep(1)
                proc.kill(); proc = subprocess.Popen([G815, "serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1); last.clear()
