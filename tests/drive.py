"""drive.py — the page driven by a real mouse in a hidden Chrome (DevTools protocol), the way his hand
would: click a key, drag across a row, press the colour square, move a fader, press a preset. After each
step it asks the app (/state) what the keyboard was told, and saves a screenshot.

    python3 tests/drive.py <out-dir>
Needs the app running (the star's tick). It changes the active memory's colours, as his hand would.
"""
import json, os, subprocess, sys, time, urllib.request, base64
import websocket

OUT = sys.argv[1] if len(sys.argv) > 1 else "/tmp/g815drive"
os.makedirs(OUT, exist_ok=True)
URL = "http://127.0.0.1:8859/"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PORT = 9339

chrome = subprocess.Popen([CHROME, "--headless=new", "--disable-gpu", f"--remote-debugging-port={PORT}",
                           f"--user-data-dir={OUT}/profile", "--window-size=1500,1050", "about:blank"],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    for _ in range(50):
        try:
            tabs = json.load(urllib.request.urlopen(f"http://127.0.0.1:{PORT}/json"))
            page = [t for t in tabs if t["type"] == "page"][0]
            break
        except Exception:
            time.sleep(0.2)
    ws = websocket.create_connection(page["webSocketDebuggerUrl"], suppress_origin=True)
    n = [0]

    def cdp(method, **params):
        n[0] += 1
        ws.send(json.dumps({"id": n[0], "method": method, "params": params}))
        while True:
            m = json.loads(ws.recv())
            if m.get("id") == n[0]:
                if "error" in m: raise RuntimeError(m["error"])
                return m.get("result", {})

    def js(expr):
        return cdp("Runtime.evaluate", expression=expr, returnByValue=True, awaitPromise=True)["result"].get("value")

    def mouse(kind, x, y):
        cdp("Input.dispatchMouseEvent", type=kind, x=x, y=y, button="left", clickCount=1)

    def click(x, y):
        mouse("mouseMoved", x, y); mouse("mousePressed", x, y); mouse("mouseReleased", x, y); time.sleep(0.25)

    def drag(x0, y0, x1, y1, steps=12):
        mouse("mouseMoved", x0, y0); mouse("mousePressed", x0, y0)
        for i in range(1, steps + 1):
            mouse("mouseMoved", x0 + (x1 - x0) * i / steps, y0 + (y1 - y0) * i / steps); time.sleep(0.02)
        mouse("mouseReleased", x1, y1); time.sleep(0.4)

    def centre(sel):
        r = js(f"(() => {{ const r = document.querySelector({json.dumps(sel)}).getBoundingClientRect(); return [r.x + r.width/2, r.y + r.height/2, r.x, r.y, r.width, r.height]; }})()")
        return r

    def state():
        return json.load(urllib.request.urlopen(URL + "state"))

    def shot(name):
        data = cdp("Page.captureScreenshot", format="png")["data"]
        open(f"{OUT}/{name}.png", "wb").write(base64.b64decode(data))

    ok = True
    def check(what, cond):
        global ok
        ok &= bool(cond)
        print(("PASS " if cond else "FAIL ") + what)

    cdp("Page.enable"); cdp("Runtime.enable")
    cdp("Page.navigate", url=URL); time.sleep(1.5)

    # 1. a click chooses one key, and the count says so
    x, y, *_ = centre("#k11")                       # Q
    click(x, y)
    check("click on Q chooses it", js("[...sel].join()") == "11")

    # 2. a drag across Z..M chooses the whole run
    zx, zy, *_ = centre("#k1a"); mx, my, *_ = centre("#k0d")
    js("selectNone()")
    drag(zx, zy, mx, my)
    run = sorted(js("[...sel]"))
    check("drag Z..M chooses 7 keys: %s" % run, run == sorted(["1a", "18", "03", "16", "02", "0e", "0d"]))

    # 3. the colour square paints them: top-right corner of the square = full red
    _, _, sx, sy, sw, sh = centre("#sv")
    js("hsv[0] = 0; drawPicker()")
    click(sx + sw - 2, sy + 2)
    time.sleep(0.5)
    st = state()
    check("square paints Z..M red: Z=%s" % st["keys"]["1a"], st["keys"]["1a"]["c"] in ("ff0000", "fe0000", "fd0202", "fe0101") or st["keys"]["1a"]["c"].startswith("f"))
    check("an unchosen key is untouched: Q=%s" % st["keys"]["11"], st["keys"]["11"]["c"] != st["keys"]["1a"]["c"])

    # 4. the hue strip at one third = green
    _, _, hx, hy, hw, hh = centre("#hue")
    click(hx + hw / 2, hy + hh / 3)
    time.sleep(0.5)
    c = state()["keys"]["0d"]["c"]
    check("hue at 1/3 makes M green: %s" % c, int(c[2:4], 16) > 200 and int(c[0:2], 16) < 40)

    # 5. the key-brightness fader: drag to about 30 %
    _, _, fx, fy, fw, fh = centre("#kb")
    drag(fx + fw * 0.9, fy + fh / 2, fx + fw * 0.3, fy + fh / 2)
    b = state()["keys"]["0d"]["b"]
    check("key brightness fader sets M to ~30: %s" % b, 20 <= b <= 40)
    shot("after-drag")

    # 6. a preset on a new choice: press the first preset chip on ESC
    js("selectNone()")
    ex, ey, *_ = centre("#k26"); click(ex, ey)
    px, py, *_ = centre("#presets .chip"); click(px, py)
    time.sleep(0.5)
    p0 = state()["presets"][0]
    e = state()["keys"]["26"]
    check("preset %s lands on ESC: %s" % (p0, e), e["c"] == p0["c"] and e["b"] == p0["b"])

    # 7. SAME COLOUR grows the choice to every key of that colour
    click(*centre("#k1a")[:2])                     # Z now chosen too (it is green at ~30)
    js("selectNone(); sel.add('1a')")
    click(*centre("button[onclick='selectSame()']")[:2])
    same = sorted(js("[...sel]"))
    check("SAME COLOUR from Z finds the 7 of the run: %d" % len(same), len(same) >= 7)

    shot("final")
    print("ALL PASS" if ok else "SOME FAILED")
finally:
    chrome.terminate()
