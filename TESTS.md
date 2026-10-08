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

**Branch:** `claude/upbeat-mendel-yhjx3q` · **Status:** open

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

(the Mac's Claude Code writes here)
