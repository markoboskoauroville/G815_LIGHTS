# G815 Lights

    git clone https://github.com/markoboskoauroville/G815_LIGHTS ~/Developer/G815_LIGHTS && ~/Developer/G815_LIGHTS/install.sh

**Every key of the Logitech G815 its own still colour and brightness, in three banks M1 M2 M3: a Swift app for
this one keyboard, nothing else.** Built 2.10.2026 because OpenRGB showed colours that never reached the keys.

- The window draws the keyboard as it is (black keys, the legend lit in the key's colour, M1 M2 M3 MR yellow).
  Click or drag keys, set a colour (square, hue, RGB, hex, swatches) and a brightness for just those keys;
  presets put a saved colour on a group in one press. Brightness is small squares, one per level the keys really
  show (measured with the camera): the keyboard's OFF 12 25 50 100, a key's own OFF 18 30 45 60 80 100.
- M1 M2 M3 are the keyboard's banks: choosing one in the window switches the keyboard, pressing one on the
  keyboard switches the window. Every change is kept on the Mac (`~/.g815/settings.json`) and, four seconds
  later, written into that bank of the keyboard, which holds one still colour per zone — so the power-on is
  still, never a light show — and the app paints every key the moment the Mac is up.
- Macros (v15): kept on the Mac per bank, played by G1–G5 or any other key; MR on the keyboard records (MR, the key,
  type, MR), and the window has an editor and a recorder.
- G1–G5 are the app's (v18): they never type F1–F5, in any bank, with the app running or not. While the app runs the
  keyboard is in host mode, as under G HUB: the app lights the active M key and switches banks when an M key is
  pressed; quitting gives the keyboard its own mode back on the same bank. MR's own light cannot be set on this
  keyboard (LESSONS 18); the drawing's MR shows it.
- A login agent starts it without a window; the star's row (Keyboard and mouse › G815 Lights) opens the window.
- ON / OFF and ✕ (v21, 19.10.2026, Marko: "In the top of every user interface, there will now be an on/off switch";
  "It's far upper right corner"): the first row reads G815 LIGHTS ON OFF, with the version and a ✕ at the far right.
  OFF gives the keyboard its own mode back and quits (until the star opens it or the next login); ✕ closes the window
  and the keeper stays; a preset's rename box has the same ✕.

| Document | For |
|---|---|
| `MANIFEST.md` | the one block to paste into Terminal now (merge, pull, install) |
| `TESTS.md` | test tasks for the Claude Code on the Mac, and its results |
| `TAKEOVER.md` | putting it on a Mac: build, sign, permission, login agent |
| `LESSONS.md` | what the keyboard really does, measured, and every trap that cost time |
| `momentaryupdates.md` | his requests, word for word, with a status each |

**v23 (31.10.2026): G1–G5 open DaVinci Resolve's pages.** Marko: *"Each key should invoke a module of DaVinci Resolve, in the order in which they are shown on the user interface ... If I change how many there are, it should also change what it triggers."* While Resolve is in front, G(n) presses the n-th button of Resolve's page bar, read live through Accessibility (Media, Photo, Cut, Edit, Fusion, Color, Fairlight, Deliver, ordered by x; a hidden page drops out). Elsewhere G1–G5 play their macros as before.
