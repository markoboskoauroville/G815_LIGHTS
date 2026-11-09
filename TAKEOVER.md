# TAKEOVER — G815 Lights on a Mac

**State 5.11.2026: v29** (GitHub release, installed into build/ where the login agent runs it, signed "Mantra Apps"):
right-click any key in the drawing → REPLACE WITH THE NEXT KEY I PRESS / REPLACE WITH › (groups) / BACK TO; per bank
(`Bank.remaps`, key id → Mac key code), G1–G5 too, the cap shows →NEW; modifiers, media keys and ☼ cannot be replaced.
The updater installs GitHub's release v<N> and signs it here (never build.sh on the Mac).


**Version 18** (`VERSION` in `app/Views.swift`, shown top right in the window). macOS 14+, Apple Silicon, swiftc
only (no Xcode project).

1. **The signing certificate.** Builds are signed with **"Mantra Apps"**, a self-signed code-signing
   certificate in the login keychain (made 2.10.2026 with openssl: CN "Mantra Apps", extendedKeyUsage
   codeSigning, imported with `-T /usr/bin/codesign`). macOS ties Input Monitoring to the signer, so the
   permission survives every rebuild. On a Mac without it, make it the same way, or change `build.sh` to
   `codesign -s -` and accept re-granting the permission after every build (LESSONS 6).
2. **Build and install:** `./install.sh` builds `build/G815 Lights.app` and `build/g815`, writes
   `~/Library/LaunchAgents/community.auroville.g815lights.plist` (the app with `--background`, RunAtLoad) and
   starts it. Run it again after any change.
   GitHub builds the same with `SIGN=- ./build.sh` (`.github/workflows/build.yml`, ad hoc signature, on every
   push): a red build there means the Swift does not compile.
   The app updates itself (v14, `app/Update.swift`): it fetches main in this repo, and when VERSION there is
   higher it pulls, runs `./build.sh` and restarts. Only from a clean checkout on main; anything else it only
   reports top right. So: develop on a branch, merge into main, bump VERSION, and every Mac running it follows.
3. **Input Monitoring** (System Settings › Privacy & Security › Input Monitoring): **G815 Lights** on. The
   light interface shares the keyboard's USB interface, so opening it needs this; without it the window says
   `could not open the G815 (0xe00002e2)`. Granting it is Marko's own act.
4. **No other lighting software.** OpenRGB's login agent was moved out of the way to
   `~/.g815/OpenRGB.plist.removed-2.10.2026`; G HUB is not installed. Either would paint over this app.
5. **The star's row** is `MANTRA_STAR/apps/g815.lua` (`load("g815")`, folder Keyboard and mouse): it only
   opens the app or quits it.

## The files

| File | What |
|---|---|
| `src/hidpp.swift` | the wire: HID++ 2.0 over IOKit, features looked up by ID (never by a fixed index) |
| `src/lights.swift` | per-key colour (0x8081), brightness (0x8040), onboard mode (0x8100) |
| `src/onboard.swift` | the keyboard's memory: read/write a sector, CRC-16/CCITT, the 4 lighting blocks |
| `src/main.swift`, `src/serve.swift` | `build/g815`, the same wire as a command line, for tests |
| `app/Wire.swift` | the one thread that owns the keyboard; jobs in order, reopens after a replug |
| `app/Store.swift` | banks, presets, painting, writing banks; host mode, G1–G5, MR and the M keys (syncGKeys, mPressed, release) |
| `app/Macros.swift`, `app/MacroViews.swift` | macros: recorder, player, the key tap (Accessibility), the editor |
| `app/Update.swift` | the self-update from main |
| `app/Views.swift` | the window (CAMERA language), the keyboard drawing, the picker |
| `app/main.swift` | the app: one copy only, login/background, wake and poll |
| `layout.json` | his keyboard, key by key: light index, legend, place (ISO Enter, 5€, AltGr, no key left of Z) |
| `tests/kbshot.sh` | the keyboard as his NDI camera sees it (the scrcpy window "Pixel 7"), upright |
| `tests/click.swift` | a real mouse click or drag, for testing the window |
| `tests/ask.swift`, `tests/press.sh` | a key for Marko to press, in a box that goes when that key arrives; the probe and a camera shot with it (LESSONS 19) |
| `tests/drive.py`, `tests/keycolour.py` | the old web page's driver (gone with the page), and a colour meter |

## The keyboard's command line

    build/g815 features                       every HID++ feature and its index on this firmware
    build/g815 set 26:ff0000 37:00ff00        light index : rrggbb (Esc red, F1 green)
    build/g815 brightness [0-100]   mode [1|2]   sector <hex>   onboard <1|2|3|all> <keys> <logo>
    build/g815 call <feature> <fn> [bytes]    one raw HID++ call
    build/g815 probe <s> [feature:fn:bytes …] the calls, then everything the keyboard sends for <s> seconds

**Never read or write the memory from the command line while the app runs a bank write** (LESSONS 8).
A backup of the factory memory as found on 2.10.2026 is in `~/.g815/backup-2.10.2026/`.

## Never proven

- What the keyboard does in the first second of power-on was seen by Marko, not by a camera (the camera's
  phone sits on the same hub and went dark with it). He saw: his colours, a short black, his colours again.
- The wake-from-sleep repaint has not been watched (it is the same `paintAll` as a replug).
- Host mode across a sleep and a real boot (the app takes it over again at every open; not watched through a night).
- The G HUB "user-stored lighting" slots (Brightness+8/+9 in the manual) were not explored.

## 31.10.2026, v23–v27: G1–G5 for DaVinci Resolve
app/ResolvePages.swift: Resolve in front → G(n) = the n-th button of its page bar, read live through AX (hidden pages drop out); the switch is resolve.OpenPage through the router (127.0.0.1:8940; AXPress only lights the button). Store.resolveG over paint: the current page's G-key orange, the other G-keys dark; followResolve once a second; the bank's colours back when Resolve leaves the front. Each press → distributed notification community.auroville.g815.gkey (E16 for DaVinci Resolve lights it). Runs from build/ as a login agent: `launchctl kickstart -k gui/$(id -u)/community.auroville.g815lights` after a build. Checked on the Pixel camera 31.10.2026.


## From the former README (9.11.2026)

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

**v25–v26 (31.10.2026): the G-keys light for Resolve.** Marko: *"by default those G keys have no light when I press them. So only one key should light at a time."* While Resolve is in front, the G-key of its current page (resolve.GetCurrentPage, once a second; at once on a press) is orange and the other G-keys are dark; when Resolve is not in front the bank's own colours come back. Every press is also told to E16 for DaVinci Resolve (distributed notification `community.auroville.g815.gkey`), whose window lights that key.

**v30 (8.11.2026): NIGHT, an API for other apps.** Distributed notification `community.auroville.g815lights.night`, userInfo
`["on": "1"]`: every light dark except ⌃ ⌥ ⌘ (both sides) and F1 at grey 50 (the lowest a key surely shows); `["on": "0"]`:
the bank back. Screen Brightness Darkening the Screen (Mantra) v9 sends it with ⌃⌥⌘F1. Only G815 Lights writes to the
keyboard: an app writing to it directly is painted over within seconds (seen 8.11.2026).

## v32 (9.11.2026)
The NIGHT API answers every call with the notification community.auroville.g815lights.night.ack; the keyboard is reopened from scratch on every night call (stale handle after a reconnect); the stuck paintQueued flag that dropped later paints is cleared. Log ~/.g815/log.txt.
