# TAKEOVER — G815 Lights on a Mac

**Version 4** (`VERSION` in `app/Views.swift`, shown top right in the window). macOS 14+, Apple Silicon, swiftc
only (no Xcode project).

1. **The signing certificate.** Builds are signed with **"Mantra Apps"**, a self-signed code-signing
   certificate in the login keychain (made 2.10.2026 with openssl: CN "Mantra Apps", extendedKeyUsage
   codeSigning, imported with `-T /usr/bin/codesign`). macOS ties Input Monitoring to the signer, so the
   permission survives every rebuild. On a Mac without it, make it the same way, or change `build.sh` to
   `codesign -s -` and accept re-granting the permission after every build (LESSONS 6).
2. **Build and install:** `./install.sh` builds `build/G815 Lights.app` and `build/g815`, writes
   `~/Library/LaunchAgents/community.auroville.g815lights.plist` (the app with `--background`, RunAtLoad) and
   starts it. Run it again after any change.
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
| `app/Store.swift` | banks, presets, painting, writing banks, following the keyboard's M keys |
| `app/Views.swift` | the window (CAMERA language), the keyboard drawing, the picker |
| `app/main.swift` | the app: one copy only, login/background, wake and poll |
| `layout.json` | his keyboard, key by key: light index, legend, place (ISO Enter, 5€, AltGr, no key left of Z) |
| `tests/kbshot.sh` | the keyboard as his NDI camera sees it (the scrcpy window "Pixel 7"), upright |
| `tests/click.swift` | a real mouse click or drag, for testing the window |
| `tests/drive.py`, `tests/keycolour.py` | the old web page's driver (gone with the page), and a colour meter |

## The keyboard's command line

    build/g815 features                       every HID++ feature and its index on this firmware
    build/g815 set 26:ff0000 37:00ff00        light index : rrggbb (Esc red, F1 green)
    build/g815 brightness [0-100]   mode [1|2]   sector <hex>   onboard <1|2|3|all> <keys> <logo>
    build/g815 call <feature> <fn> [bytes]    one raw HID++ call

**Never read or write the memory from the command line while the app runs a bank write** (LESSONS 8).
A backup of the factory memory as found on 2.10.2026 is in `~/.g815/backup-2.10.2026/`.

## Never proven

- What the keyboard does in the first second of power-on was seen by Marko, not by a camera (the camera's
  phone sits on the same hub and went dark with it). He saw: his colours, a short black, his colours again.
- The wake-from-sleep repaint has not been watched (it is the same `paintAll` as a replug).
- The G HUB "user-stored lighting" slots (Brightness+8/+9 in the manual) were not explored.
