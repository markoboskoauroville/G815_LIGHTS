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
