# TESTS — the cloud builds, the Mac tests

Two Claude Codes work on this app (Marko, 8.10.2026: "we are building here and testing in Claude code ... I'm going to
copy-paste command between two of you"):

- **the cloud session** writes the code, has GitHub compile it, and writes the test task below;
- **the Claude Code on Marko's Mac** (in `~/Developer/G815_LIGHTS`) runs the task on the real keyboard and writes the
  results into this file, then commits and pushes.

Marko carries one line each way:

- to the Mac (Terminal), from MANIFEST.md: the block that fetches the branch and starts Claude Code on the task;
- back to the cloud: `Test results are in TESTS.md.`

## For the Claude Code on the Mac: how to run a task

1. Work on the branch named in the task, never on main: `git fetch origin <branch> && git checkout <branch> &&
   git pull --ff-only origin <branch>`.
2. Do not change the app's code (app/, src/, build.sh, install.sh). Fixes are made in the cloud. You may write
   scripts under `tests/` if a step needs one.
3. Permissions (Input Monitoring, Accessibility) and pressing keys on the keyboard are Marko's acts: ask him, say
   exactly what to press, and wait for him to say done. Read what happened from `~/.g815/log.txt`
   (`tail -n 100 ~/.g815/log.txt`); quote the lines, they are the evidence.
4. Write the results under the task's **Results** heading: per step PASS, FAIL or NOT RUN, what was seen, the log
   lines. Anything odd, write it, even if the step passed.
5. Then (all of it; the cloud reads only what is on GitHub): `git add TESTS.md && git commit -m "TESTS: results T<n>" && git pull --rebase origin <branch> && git push
   origin <branch>`. Check it arrived: `git status` must say "up to date with 'origin/<branch>'". Only then tell
   Marko: "Results pushed. Tell the cloud: Test results are in TESTS.md."

---

## T1 — macros (v15), 8.10.2026

**Branch:** `claude/upbeat-mendel-yhjx3q` · **Status:** failed at step 1: a repaint loop every 0.77 s (every 0x8010 call makes the keyboard send three empty notes on 0x0a 0x0b 0x0c; the M-keys note repainted, the repaint called 0x8010 again). Fixed in v16; steps 2–10 go on in T2.

What v15 does: macros kept in `~/.g815/settings.json`, per bank. G1–G5 and MR speak HID++ (features 0x8010 and
0x8030); any other key is caught through an event tap that needs Accessibility, which also plays macros. MR on the
keyboard: MR → the key → type → MR. In the window, MR in the drawing (or MACROS in the KEYS row) shows the editor.

The HID++ part is the unknown: which bytes G1 and MR really send. Steps 3 and 4 are the ones that matter most.

1. **Build and install.** `./install.sh`. Expect `built build/g815 and build/G815 Lights.app (v15)` and the login
   agent started. Then `sleep 5; tail -n 40 ~/.g815/log.txt`: expect `macros: G keys feature 0x.., MR feature 0x..`
   and either `macros: key tap on` or nothing about the tap (Accessibility still off).
2. **Accessibility.** Ask Marko to open the window (open "build/G815 Lights.app"), click MR in the drawing, and allow
   G815 Lights in System Settings › Privacy & Security › Accessibility if asked. Within 3 s the log should say
   `macros: Accessibility allowed` and `macros: key tap on`.
3. **G1 and MR on the wire.** Ask Marko to press G1 once, then G5 once, then MR once, then MR again. Copy every new
   line from the log that starts with `G keys:`, `MR:` or `keyboard says:`, with their bytes. (G keys are only
   under the app in a bank with a G-key macro, or while MR waits; so G1/G5 may show nothing before step 4. Say so.)
4. **Record on the keyboard.** Marko opens TextEdit (a new document), then: MR (does its light come on?), G1, types
   `abc`, MR (light off?). Log: `recording for G1 ...`, then `G1 MACRO: 3 keys, on G1 in M1`. Then G1 in TextEdit:
   does `abc` appear? Quote the log lines and say what TextEdit shows.
5. **Any key as trigger.** In the window: MACROS, click F5 on the drawing, then `PUT G1 MACRO HERE`. In TextEdit
   press F5: `abc` should appear, and F5's own action should not happen. Then in the window `TAKE IT AWAY` for F5
   and press F5 again: its own action is back.
6. **Editor.** In the window: `+` (new macro), `+ TEXT`, type `hello`, PLAY with TextEdit in front (click TextEdit
   within the delay, or put the macro on G2 and press G2). Does `hello` appear? Also RECORD → type `xy` → STOP:
   do the steps show `↓ X`, `↑ X`, waits, `↓ Y`, `↑ Y`?
7. **Banks.** Switch to M2 (in the window). The log should say `macros: G1–G5 left to the keyboard`. Press G1:
   nothing from the macro. Back to M1: G1 plays `abc` again.
8. **After a restart of the app.** `launchctl kickstart -k gui/$(id -u)/community.auroville.g815lights`, wait 10 s,
   press G1 in TextEdit: `abc`. Then `grep -c '"uid"' ~/.g815/settings.json` and paste the `macros` part of the file
   (`python3 -c "import json;d=json.load(open('$HOME/.g815/settings.json'));print(json.dumps(d['macros'],indent=1)[:1500]);print([m.get('macros') for m in d['memories']])"`).
9. **RECHECK KEYBOARD.** Click it in the window; copy the report (the lines about Accessibility, G1–G5 and MR).
10. **Colours unchanged.** Are the key colours still right after all this (M1, M2)? Any flicker or loss?

### Results

Run on the Mac, 8.10.2026, 04:13–04:31, branch `claude/upbeat-mendel-yhjx3q`. Pushed after step 1, on Marko's word;
steps 2–10 were not run.

**1. Build and install — PASS, with a loop (FAIL for the app's behaviour).**
`./install.sh` printed `built build/g815 and build/G815 Lights.app (v15)` and `login agent installed and started`.
The log after start:

    04:13:53.252  keyboard on M1, mode 1
    04:13:53.397  keyboard says: 11 ff 0a 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:13:53.399  macros: G keys feature 0x0a, MR feature 0x0c
    04:13:53.399  macros: G1–G5 left to the keyboard
    04:13:53.401  keyboard says: 11 ff 0b 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:13:53.402  MR: 11 ff 0c 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:13:53.476  paint all: bank M1 written

Nothing about the key tap (Accessibility still off), as expected.

**Odd, and it matters: an endless repaint loop.** From the start the keyboard sends three empty messages every
~0.77 s, and the app paints every key each time:

    04:14:21.690  paint all: keyboard spoke
    04:14:21.864  G keys: 11 ff 0a 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:14:21.891  keyboard says: 11 ff 0b 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:14:21.891  MR: 11 ff 0c 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:14:22.495  paint all: keyboard spoke

It was still going at 04:31:03, with no key pressed: `paint all: keyboard spoke` is in the log 1,062 times. Before v15
(up to 8.10.2026 03:11) there were 23 in the whole log. A reading of the code (not changed): `Store.heard` treats
`0b` (byte 3 = 00, not the G-key or MR feature) as "keyboard spoke" → `repaintSoon` → `paintAll` → `syncGKeys`, which
calls `0x8010` function 2 (`[0]`) and asks `index(of:)` again. The keyboard seems to answer every round with these
three zero notifications on `0x0a`, `0x0b` (probably the M-keys feature 0x8020) and `0x0c`. The zero `G keys:` and `MR:`
lines go to `macros.gKeys(0)` and `macros.mr(false)` every 0.77 s. That may hide or disturb real presses in steps 3–4,
and it is a flicker risk for step 10.

**2. Accessibility — NOT RUN.** The window was opened and Marko was asked by voice; no `macros: Accessibility
allowed` or `macros: key tap on` in the log by 04:31.

**3–10 — NOT RUN.**

---

## T2 — macros again, after the loop fix (v16), 8.10.2026

**Branch:** `claude/upbeat-mendel-yhjx3q` · **Status:** loop gone, Accessibility on, updater clean; **MR sends nothing**
in onboard mode (step 3), so 4–10 did not run. Also a reopen storm (422 in 6 s) while Accessibility was switched on.
v17: a 1 s pause before reopening after a failure; T3 measures MR with `g815 probe` and tests the macros without MR.

v16: the G-key mode (0x8010) is sent only when it changes, at start, after a reopen and after a bank switch; the
notes from the G, M and MR features (0x0a 0x0b 0x0c on this keyboard) never repaint, and empty ones are not logged.
`build/g815` and `build/list` are no longer tracked by git (an install changed them, which blocked pulls and made the
updater think the repo was not clean).

0. **Before pulling:** `git checkout -- build/g815 build/list` (the old tracked binaries; the pull removes them from
   git, the install builds g815 again). Then the pull, `./install.sh`: expect `(v16)`.
1. **No loop.** Wait 60 s without touching anything, then
   `grep -c "paint all: keyboard spoke" ~/.g815/log.txt` twice, 60 s apart: the number must not grow (0 or 1 new is
   fine). Quote the last 30 log lines. `git status --short` must not list build/g815.
2. **Accessibility** (Marko's act — ask him, and wait): open the window, click MR in the drawing; System Settings
   opens at Accessibility; switch **G815 Lights** on. Log within 3 s: `macros: Accessibility allowed`,
   `macros: key tap on`. If G815 Lights is not in the list, he adds it with + from `~/Developer/G815_LIGHTS/build`.
3. – 10. **As in T1, steps 3 to 10** (G1 and MR on the wire; record on the keyboard with MR → G1 → `abc` → MR;
   F5 as trigger; the editor; banks; after a restart; RECHECK; colours unchanged). For step 3, with no G-key macro yet,
   G1 shows nothing; press MR first (its light should come on and the log say `G1–G5 under the app`), then G1, and
   quote the `G keys:` and `MR:` lines with their bytes.
11. **Updater check.** `git -C ~/Developer/G815_LIGHTS status --porcelain` after the install: empty (apart from
    TESTS.md while you write it).

### Results

Run on the Mac, 8.10.2026, 04:47–04:56. Stopped after step 3: MR sends nothing, so the rest (recording on the
keyboard and everything built on the G1 macro) could not run.

**0. Pull and install — PASS.** `git checkout -- build/g815 build/list`, fast-forward to `db9cb12`, `./install.sh`:
`built build/g815 and build/G815 Lights.app (v16)`, `login agent installed and started`.

**1. No loop — PASS.** `grep -c "paint all: keyboard spoke"` gave 725, then 725 again 60 s later. (It was 1,062 at the
end of T1, so the log was trimmed in between.) The start, quoted:

    04:49:27.971  start, bank M1
    04:49:27.991  keyboard on M1, mode 1
    04:49:28.140  keyboard says: 11 ff 0a 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
    04:49:28.142  macros: G keys feature 0x0a, MR feature 0x0c
    04:49:28.143  macros: G1–G5 left to the keyboard
    04:49:28.211  paint all: bank M1 written
    04:49:28.362  macros: G1–G5 left to the keyboard
    04:49:28.745  paint all: keyboard spoke
    04:49:30.984  paint all: start + 3 s
    04:49:37.984  paint all: start + 10 s
    04:49:57.984  paint all: start + 30 s
    04:50:27.988  paint all: start + 60 s

Odd but small: the first empty `0a` note arrives before `gIdx` is known, so it is logged as `keyboard says:` and
repaints once. `G1–G5 left to the keyboard` is logged twice at every start (forced sync plus the reopen?). Same after
the restart at 04:54:45.

**2. Accessibility — PASS, with a storm of failed writes.** Marko clicked MR in the window and switched G815 Lights on.

    04:52:06.988  macros: Accessibility allowed
    04:52:07.010  macros: key tap on

While he was doing it (04:51:59.981 – 04:52:05.929) the app wrote and reopened the keyboard in a tight loop:
**422** times `error: write failed (0xe00002e2)` (kIOReturnNotPermitted), each followed by `keyboard opened` and
`paint all: opened`, with `macros: G keys feature none, MR feature none` and one
`error: no answer from feature index 0x10 function 1` in between. It healed by itself at 04:52:06. About 1,600 log
lines in 6 s; the reopen probably wants a pause before retrying.

**3. G1 and MR on the wire — FAIL: MR sends nothing.** Marko pressed MR once (04:52:30), then several times
(04:53–04:54): **no line at all** in the log, not `MR:`, not `keyboard says:`. The MR light did **not** come on. To
rule out a reader dead after the storm, the app was restarted
(`launchctl kickstart -k gui/$(id -u)/community.auroville.g815lights`, 04:54:44, clean start, `keyboard on M1,
mode 1`) and Marko pressed MR again: still nothing, only `paint all: start + 10 s` and `+ 30 s`. G1 was not pressed
(no macro yet, so G1 is left to the keyboard and would show nothing).

So, on this G815, in onboard mode (mode 1), MR produces no HID++ note on feature 0x0c (0x8030), and the keyboard does
not light it by itself. Guess for the cloud: MR notes may need the 0x8030 "software control" call first (as 0x8010
function 2 does for G keys), or host mode (onboard mode off, 0x8100) the way G HUB runs it. Note `mrLight(true)` is
only called after an MR note arrives, so the light can never come on now.

**4–10 — NOT RUN.** 4 (MR → G1 → abc → MR) needs MR. 5, 7 and 8 need the G1 macro from 4. 6 (editor), 9 (RECHECK)
and 10 (colours) could run alone; left for the next round so the MR answer reaches the cloud first. Colours looked
untouched to the eye during the session (not checked key by key).

**11. Updater check — PASS.** `git status --porcelain` after the install: empty.

---

## T3 — what MR, G1 and M1–M3 really send; macros without MR (v17), 8.10.2026

**Branch:** `claude/upbeat-mendel-yhjx3q` · **Status:** open

v17: after a failure the keyboard is reopened at most once a second (T2's storm); the G/M/MR feature indexes are
known before the G-key call (no stray repaint at start); `G1–G5 …` logged only when it changes. New:
`build/g815 probe <seconds> [feature:fn:bytes ...]` makes the calls, then prints everything the keyboard sends.

Part A is a measurement, with the app STOPPED (two programs on the keyboard interleave, LESSONS 8). Paste every
probe's whole output. Marko presses the keys; say exactly when, one key every 3 seconds, and what he sees on the
keyboard (MR light, M lights, did the colours change bank?).

0. Pull, `./install.sh`: expect `(v17)`.
1. Stop the app: `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/community.auroville.g815lights.plist`;
   `pgrep -l G815Lights` must print nothing.
2. `build/g815 features` (the whole list).
3. Read-only: `build/g815 probe 0 8010:0 8020:0 8030:0`.
4. **As it is:** `build/g815 probe 25`. Marko: MR, G1, M2, M1, MR.
5. **G keys under software control:** `build/g815 probe 25 8010:2:01`. Marko: MR, G1, G5, M2, M1, MR. Does M2 still
   switch the bank on its own (colours change)?
6. **MR light by hand:** `build/g815 probe 3 8030:1:01` (MR light on?), then `build/g815 probe 3 8030:1:00`.
7. **M lights by hand:** `build/g815 probe 3 8020:1:01`, then `8020:1:02`, then `8020:1:04`, then `8020:1:00`
   (which M lights?). Then `build/g815 probe 3 8020:1:01` again if M1 is the bank, so its light is right.
8. **Put back:** `build/g815 probe 1 8010:2:00`, then
   `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/community.auroville.g815lights.plist`, wait 10 s;
   `tail -n 30 ~/.g815/log.txt` (no errors), colours right on M1.

Part B, the app running (Accessibility is already on from T2; if `macros: key tap on` is not in the log after start,
say so).

9. **Editor + any key:** window → MACROS. `+` (a new macro), `+ TEXT`, type `hello` in the step. Click **F5** on
   the drawing, `PUT … HERE`. In TextEdit (a new document) press F5: `hello` appears? F5's own action does not
   happen? Then RECORD, type `xy`, STOP: quote the steps shown (`↓ X`, `↑ X`, waits …).
10. **G1:** in the window click **G1** on the drawing, `PUT … HERE` (the same macro). Log: `G1–G5 under the app`.
    In TextEdit press G1: does the macro play? Quote the `G keys:` lines. Then press MR once: any `MR:` line now?
11. **Banks:** M2 in the window → log `G1–G5 left to the keyboard`; G1 plays nothing. M1 → G1 plays again.
12. **After a restart:** `launchctl kickstart -k gui/$(id -u)/community.auroville.g815lights`, 10 s, G1 and F5 in
    TextEdit still play.
13. **Clean up:** in the window, F5 → `TAKE IT AWAY` (F5 types as before). RECHECK KEYBOARD: copy the report.
    Colours right?

### Results

(the Mac's Claude Code writes here)
