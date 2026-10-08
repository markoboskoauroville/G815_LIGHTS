# G815 Lights

    git clone https://github.com/markoboskoauroville/G815_LIGHTS ~/Developer/G815_LIGHTS && ~/Developer/G815_LIGHTS/install.sh

**Every key of the Logitech G815 its own still colour and brightness, in three banks M1 M2 M3: a Swift app for
this one keyboard, nothing else.** Built 2.10.2026 because OpenRGB showed colours that never reached the keys.

- The window draws the keyboard as it is (black keys, the legend lit in the key's colour, M1 M2 M3 MR yellow).
  Click or drag keys, set a colour (square, hue, RGB, hex, swatches) and a brightness for just those keys;
  presets put a saved colour on a group in one press; the keyboard's own brightness has its slider too.
- M1 M2 M3 are the keyboard's banks: choosing one in the window switches the keyboard, pressing one on the
  keyboard switches the window. Every change is kept on the Mac (`~/.g815/settings.json`) and, four seconds
  later, written into that bank of the keyboard, which holds one still colour per zone — so the power-on is
  still, never a light show — and the app paints every key the moment the Mac is up.
- A login agent starts it without a window; the star's row (Keyboard and mouse › G815 Lights) opens the window.

| Document | For |
|---|---|
| `MANIFEST.md` | the one block to paste into Terminal now (merge, pull, install) |
| `TAKEOVER.md` | putting it on a Mac: build, sign, permission, login agent |
| `LESSONS.md` | what the keyboard really does, measured, and every trap that cost time |
| `momentaryupdates.md` | his requests, word for word, with a status each |
