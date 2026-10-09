# LESSONS — G815 Lights

Measured on Marko's G815 (USB 046d:c33f, firmware U1 31.02, serial 096D33673635), 2.10.2026.

## 1. OpenRGB's colours did not land because it hard-codes feature indexes

HID++ 2.0 numbers its features per firmware. OpenRGB's G815 driver writes to index 0x0D for effects, 0x08 and
0x0F to set up direct mode. On this firmware 0x0D is **BrightnessControl (0x8040)** and 0x08 is
**DisableKeys (0x4522)**; RGBEffects is 0x0F and PerKeyLightingV2 0x10. So its "mode" commands went to the
brightness feature. Its partial "little frame" also memsets from `n*4 - 1`, wiping the blue of the last key in
the frame. **Always ask the root feature (index 0, function 0) for the index of a feature ID.**

## 2. Per-key colour is RAM; the keyboard's memory holds one effect per zone

Onboard profiles (0x8100): 3 profiles (M1..M3) in sectors 1..3, directory in sector 0, factory copies in
0x0101..0x0103, 16 sectors of 256 bytes, the last two bytes CRC-16/CCITT (poly 0x1021, init 0xFFFF) big-endian —
verified against every stored sector before the first write. Lighting is four 11-byte blocks at 0xD0: logo,
keys, then logo and keys for the dimmed state. 0x01 = static [01 R G B 0…]; found also 0x03 cycle, 0x04 wave,
0x0A breathing. There is no room for per-key colours. So a bank in the keyboard gets the colour most keys show
plus the logo's, and the app paints every key when the Mac is up. The writer reads first, refuses a sector whose
CRC is wrong, skips a sector already so, and reads back after.

## 3. There is no power-on animation switch on this firmware

0x8071 manageNvConfig (fn 3) answers only capability 0x0002; boot-up effect (0x0001) is error 2. The "light
show" at power-on was simply the onboard profile's effect (M1 wave + cycle, M2 breathing cyan, M3 cycle).
Making the profiles static is the cure.

## 4. The keyboard shows true colour; the camera does not

Sent magenta, white, orange: to Marko's eye magenta, white and orange; through the NDI camera blue, bluish,
red. No colour correction belongs in this app. (The camera's white balance is MANTRA_NDI's problem.)

## 5. On this Mac the light interface is a keyboard interface

The vendor collection (usage page 0xFF43, usage 0x0602) lives on the same USB interface as the keys, whose
primary usage is keyboard. Matching on `PrimaryUsagePage` finds nothing; match on `DeviceUsagePage`/
`DeviceUsage`. And opening it needs **Input Monitoring** (0xe00002e2 kIOReturnNotPermitted without it).

## 6. An ad hoc signature loses the permission at every rebuild

TCC stored `cdhash H"f716…"` for the ad hoc app, ignoring the designated requirement written with
`codesign -r=`. The next build had another hash and was refused while the list said "on". Signed with the
self-signed "Mantra Apps" certificate the requirement is identifier + certificate leaf, which every build meets.

## 7. Hammerspoon + hs.task stdin: lost lines, then a frozen Hammerspoon

The first version ran a helper through hs.task and wrote commands with setInput. Two writes close together lost
one line; from then on every answer went to the wrong caller (bank M2 reported "saved" and was never written).
Writing one line at a time then froze Hammerspoon's main thread until the helper was killed. The Swift app owns
the device on one thread of its own (`Wire`), every job in order. Also: hs.json cannot encode a Lua table with
holes (`banks[2]` alone) — the page got nothing back.

## 8. Do not read the memory while it is being written

A `g815 sector 1` from the command line during the app's bank write came back all FF. Read again afterwards:
correct, CRC valid. Two openers interleave their HID++ traffic.

## 9. Two copies of the app fight

macOS's "Quit & Reopen" after granting a permission started a second copy beside the login agent's. Now a
second copy asks the first to show its window (a distributed notification) and exits.

## 10. A panel that grows inside the window blanks it (6.10.2026)

The first RECHECK report was a VStack inside the main VStack. Its eleven lines made the content taller than the
window and the whole window drew empty (the app kept running). The report now floats in an `.overlay`, and the
root view is pinned with `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)`, without
which the content sat a third of the way down after a resize.

## 11. "It resets my layout" is often a bank switch

M1 M2 M3 on the keyboard are banks, each with its own layout. An accidental M press puts the keyboard on that
bank's memory (one colour) and the app follows it. v9 offers BACK TO Mx, a LOCK, and paints again at 1.5, 3, 6 s.

## 12. A synthetic click on an inactive window is swallowed (6.10.2026)

Testing the lasso with Hammerspoon: clicks on LASSO and NONE did nothing while the drag still worked, because
the window was not key and SwiftUI's plain buttons take the first click only to activate. Focus the window
(`w:focus()`, wait half a second) before posting clicks.

## 13. The app updates by building, not by downloading (8.10.2026)

An app downloaded from GitHub is signed ad hoc and would lose Input Monitoring at every update (6). So the
updater pulls main into the repo the app sits in and runs ./build.sh, signed "Mantra Apps", then restarts through
`launchctl kickstart -k` (the login agent has no KeepAlive; launchd kills the job's process group when its app
quits, so a child left to "restart later" would die with it).

## 14. Every 0x8010 call answers with three empty notes (T1, 8.10.2026)

Setting G-key software control (0x8010 fn 2, on or off) makes the keyboard send `11 ff 0a 00…`, `11 ff 0b 00…`,
`11 ff 0c 00…` (G keys, M keys, MR on this firmware). v15 repainted on the M-keys note and called 0x8010 with every
repaint: a loop every 0.77 s, 1,062 repaints in 18 minutes. Send it only when the mode changes; never repaint on news
from these three features.

## 15. Nothing an install writes may be tracked by git (8.10.2026)

build/g815 was committed before build/ went into .gitignore, so every install changed a tracked file: a pull refused,
and the updater (which needs a clean main) would never have updated. Untracked in v16.

## 16. G1–G5 type F1–F5 unless the app holds them; MR speaks only then (T3, 8.10.2026)

Each bank in the keyboard's memory binds G1–G5 at 0x20 (four bytes each): `80 02 00 3a`…`3e` in M1 (HID keyboard,
F1–F5), `1e`…`22` in M2 (1–5); then M1–M3 as `90 0d 00 01`…`03`. With 0x8010 software control off, G1 typed F1 (it
opened Speechify, his F1 key) and MR sent nothing at all. With it on (fn 2, `01`) G1–G5 send only `11 ff 0a 00 <mask>`
and MR `11 ff 0c 00 01`/`00`. v18 holds them always and writes `80 02 00 00` (a key with no usage: nothing) into
G1–G5 of every bank, so they type nothing even with the app stopped.

## 17. Holding the G keys puts the M lights out; host mode gives them back (8.10.2026)

In onboard mode (1) with 0x8010 software control on, the keyboard switches its M1–M3 lights off and ignores 0x8020
fn 1 (it answers, nothing lights). In host mode (2), 0x8020 fn 1 lights the M key asked for (bit 0 M1, 1 M2, 2 M3; bit
3 is error 2), and an M key sends only `11 ff 0b 00 0N`: the keyboard no longer switches or reloads a bank by itself,
the app switches. In host mode the keyboard's own current bank reads 0 and 0x8100 fn 3 is not obeyed, so the app
tells the bank again after going back to mode 1 when it quits. Host mode also starts with every key dark: paint at
once. The ☼ key still works (it sends `11 ff 0d 00…`); one press from 12% goes to 0.

## 18. MR's light cannot be set on this G815 (8.10.2026)

0x8030 has only function 0 (it answers count 0); function 1 is HID++ error 7 (no such function) in both modes.
0x8020 refuses a fourth bit, and of the free per-key indexes only 2e 61 63–67 are accepted, none of them MR. The window
shows MR's state instead.

## 19. A test that needs his hand: a box that goes when the key comes (8.10.2026)

Voice cues alone were too slow (presses fell outside the probe's window), and "any key closes it" failed because he
keeps working. `tests/ask.swift` shows the key on the big screen and closes only when the probe's output or
`~/.g815/log.txt` shows that key's own line (`--keys none --watch … --match …`), or when he clicks it; `tests/press.sh`
runs the probe with it and takes a camera shot after. The voice says only the key's name.

## 20. Brightness has steps: five for the keyboard, a dead zone for a key (8.10.2026)

Measured with the camera. The keyboard's own brightness (0x8040; getInfo says max 100, 5 steps): 0–11 off, 12–24,
25–49, 50–99 and 100 are the only levels the keys show; the window offers exactly 0 12 25 50 100. A key's own colour
(0x8081): 0–44 is as dark as 0 even at keyboard brightness 100, light starts at 45 (18 %), small stairs to 64, then
smooth to 255. So a key's brightness squares start at 18 %, and a weak channel of a colour (orange's blue) goes out
before the others when a key is dimmed.

## 21. The M lights have no brightness of their own: on or off (9.10.2026)

Marko asked for the brightness of M1, M2, M3 and MR. The keyboard offers none: 0x8020 (v0) has fn 0 (count: 3) and
fn 1 (a bit per M key, host mode only, LESSONS 17), nothing else; 0x8071 has two zones only (cluster 0 at location 2,
the keys; cluster 1 at location 1, the logo) and no M zone; 0x8040 is the whole keyboard (getInfo: max 100, 5
steps); M1–M3 are not among the per-key indexes 0x8081 accepts, and MR's light cannot be set at all (LESSONS 18). So
v20 gives what exists: M KEYS LIGHT, OFF or ON, kept in settings.json (`mLight`) and sent with every host-mode set-up;
lit, an M key shines at the keyboard's brightness. Not measured with the camera on 9.10.2026 (no camera on the
keyboard that morning): whether 0x8040 really dims the M lights is still to be seen.
