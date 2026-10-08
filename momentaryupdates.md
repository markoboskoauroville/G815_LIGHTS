# G815_LIGHTS — momentary updates

Every request goes here word for word, before any code, with a Status line per item.
"Continue" means: read this file first.

## 2.10.2026, 02:10 — the request that started the app

> please research software called OpenRGB. This software is controlling many many keyboards led lights. I just need section of this application to control my Logitech G815, so it will be specialized only in this one because general one does not have all possible colors. Even if it can show the color, it is not putting it on the led or on my device. So you need to see all the screenshots now on the desk to see how it looks. It's open source, you can find it on GitHub. And we just need to work with G815. A GB showing all colors and work bug free. You can see two views here, and we want to make it available only for this key and use these views to actually change back free my colors on my keyboard. It can become part of the start menu and it needs to load with this computer, so my settings are saved and reload every time my computer starts. It will be nice if it's possible to write the settings in the memory of this keyboard, so when it gets electricity it just shows the profile I created. Because it's very confusing when I open my computer it starts to do some light show and some effects. I want it to be always in my own settings. Basically it will be best if It can work with internal memory, and we use this app just to write to its memory. I need only static colors and each button individual colors. That's all. No effect, nothing. Just a few memories of my settings. If you research the keyboard, it has four memories, and this pure function of this application will be just to change static color and brightness of each keyboard key granularly. So even each keyboard key can have different brightness, and with general brightness of the keyboard there is a button I change overall brightness, but I can also decide about brightness of each key. We also can have something called key presets, so I define few keys and then I easily apply them to the group of keys. Let's do that

Screenshots (Desktop, 2.10.2026 02.09.05 and 02.09.33): OpenRGB 1.0 on this Mac, device "Logitech G815 RGB
Mechanical Gaming Keyboard", Mode Direct, Per-LED; the second view is the LED view (keyboard map), with keys
painted yellow on screen; "Saving Not Supported".

### The items

1. Research OpenRGB's G815 code and the keyboard's own protocol (HID++ 2.0). — **Status:** started 2.10.2026
2. A G815-only app: the keyboard drawn as in OpenRGB's LED view, every key its own colour, and the colour really
   lands on the keys (the bug in OpenRGB). — **Status:** open
3. Static colours only, no effects. — **Status:** open
4. Per-key brightness, on top of the keyboard's own brightness button. — **Status:** open
5. Key presets: a few named colours, applied to a group of selected keys. — **Status:** open
6. A few memories (profiles) of his settings. — **Status:** open
7. Write to the keyboard's onboard memory, so it lights his profile from power-on with no light show.
   If the keyboard cannot hold per-key static colours, say so plainly. — **Status:** open (to research)
8. A row in the star menu; loads with the Mac and re-applies the saved settings at every start. — **Status:** open

## 2.10.2026, 02:20 — see the keyboard through the screen, and the camera's white balance

> Please, I enabled the camera through my screen copy so it's running in a small window. You need to screen capture, not use camera. Actually screen capture on the screen, find the area, and you have the full view and full colors of my keyboard. You can fix it, you can program it, you can do anything now. Also, I'm using my own app. This is my own camera NDI camera. If colors don't match, you need to also update my camera because white balancing is not functioning now. We can use opportunity with these LED lights which are the colors of the light pure spectrum to also calibrate my camera so it gives the true colors. Now white balance is a bit off, it's almost there but it's bit off. So fix my camera and fix my keyboard application.

9. Look at the keyboard through a SCREEN capture of the small window showing his NDI camera (not a Mac camera). — **Status:** started
10. The NDI camera's white balance is a bit off: use the keyboard's pure LED colours to calibrate it, and fix
    the camera (MANTRA_NDI). — **Status:** open; also written into MANTRA_NDI/momentaryupdates.md

## 2.10.2026, 03:05 — memory buttons on the map, one bank each, saved in the Mac and in the keyboard

> We can simplify and emulate the usage of the keyboard in the visual map of the keyboard. Please also include memory buttons so usage is very simple. I press the memory button and adjust my keyboard settings, basically the colors and brightness of each key, and it stays under that memory as well as my computer as well inside the keyboard. So let's do that. So simple switching the banks of memory visually on the screen and then adjusting the screen colors, and they stay in memory. I think that's the great idea

11. M1 M2 M3 drawn on the map as the keyboard's own memory keys; pressing one switches the bank on screen AND on
    the keyboard; pressing M1..M3 on the real keyboard switches the page too. — **Status:** started
12. Every change is kept under the active bank on the Mac and written into that bank of the keyboard by itself
    (no WRITE button); the keyboard's bank holds one still colour per zone (its limit), the Mac the per-key colours. — **Status:** started

## 2.10.2026, 03:15 — the drawing looks like the real keyboard, and Swift only

> please match exactly the keyboard view to the real keyboard. So my keyboard is black, so keys should be black with lights on. Also, these memory buttons are yellow on the keyboard, so please you have a screenshot and the look in real life should match as close as possible to the view in our app. Also, build a Swift app. Swiftapp should be the default, and then web app is the second. Actually, you don't need to build with webapp at all. We just can focus on Swift. There is no need for web apps anymore. Swift is great and we work with Swift only now

13. The drawing as the real keyboard: black keycaps, the legend lit in the key's colour; the M1 M2 M3 keys
    yellow as on the keyboard (the active one lit). Match the camera picture as closely as possible. — **Status:** open
14. A native Swift app, the only face; no web page. — **Status:** open (this replaces the page and the
    Hammerspoon server; the star's row will start the Swift app)

## 2.10.2026, 03:20 — permission given; test, login agent, OpenRGB out, the rest

> Add the permission test all the keyboard. Add the login agent. Okay, I already changed the permissions, so please test it. Open RGB starting automatically, yes. Remove and do all other points. That's great.

15. Input Monitoring granted by Marko: test everything on the real keyboard. — **Status:** started
16. The login agent (paints at every start, no window). — **Status:** open
17. OpenRGB out of the login items (he said yes). — **Status:** open
18. "All other points": app icon, documents (README, TAKEOVER, LESSONS), registry, handover; then the camera's
    white balance and the MIDI apps as Swift-only. — **Status:** open

> (2.10.2026, 03:30) Please remove this glowing effect from my keyboard application. Colors are good, but you don't need to really to use glow. Should be clear.

19. No glow on the legends: clear lit letters in the key's colour. — **Status:** done in v2

## 3.10.2026, morning — the bank after a restart, presets that move, a simpler preset edit

> Work on G815 app first of all. After restart, the special keys with different colors are not remembered. So for example in memory 1, F1 is red, but after I restart the computer and when it's booting up, all keys are orange. Then when I log in the app takes over and then it turns my keyboard to F1, which is red, which supposed to be memory F1 red. But it's not happening for some reason. Updates to interface presets. They need to be drag and dropable so I can rearrange them any way I like. 2. Simplifying edit preset: second row name plus preset. We don't need that. We just need the plus at the end of the row, and then to rename the preset itself. I double click on it any anywhere in the title or color, and then pop up comes for renaming. I can even remove the name completely, and then there is only swatch without the name. And there will be a check marks automatic name when you can add automatic name like white warm dim 25% off your preset name. So there is option plus preset I mean plus preset name. That's the thing, and let's fix that.

20. After a restart the keyboard boots all orange, and at login the app does not put the bank's per-key colours
    (M1: F1 red) back. Find why and fix: at login the active bank's per-key colours must be painted. (The boot
    colour itself is the keyboard's onboard memory: one still colour per zone.) — **Status:** done in v5. Found
    with the Pixel's camera: a replayed login painted fine in 4 s, but a bank reload UNDER the running app
    (M2 → M1) is silent: no report, the bank number unchanged, every key back to the bank's orange. Now: the bank
    is switched at start only if the keyboard is on another one; paint at start and at 3, 10, 30, 60, 120 s; on
    USB arrival, on the keyboard reopening, on any report it sends; and every 15 s the same colours again (a loss
    lasts 15 s at most). Everything goes into ~/.g815/log.txt, so the next real restart can be read back.
21. Presets drag and drop: rearrange them in any order, kept. — **Status:** done in v6; his test 3.10.2026: works
22. Preset edit simplified: no second row "name + preset"; only a "+" at the end of the presets row. Double click
    a preset (title or swatch) → a rename pop-up; an empty name leaves only the swatch; a tick "automatic name"
    (e.g. "white warm dim 25%") as the name. — **Status:** done in v6 (the × moved into the pop-up as DELETE); his
    test: double click works

> (3.10.2026, 05:37) please create a simple icon for this application. Make one big G and the other make 815 number in the dark mode so background is black and letters can be glowing in the white color

23. The app's icon: a big G and the number 815, black ground, the letters glowing white. — **Status:** done in v6 (icon/make_icon.py)

> (3.10.2026, morning) I tested drag and drop. It double click works, so one more thing. When I select inside the double click automatic name, then it becomes suffix to name I'm typing. Please don't gray out my name and just in that same box you add automatic name to my name

24. AUTOMATIC NAME in the rename pop-up: never greys the name; ticking it adds the automatic name to his name in
    the same box (a suffix he can still edit), unticking takes it away. — **Status:** done in v7; his test 3.10.2026: works

> (3.10.2026, morning) everything works except I don't want when I press plus that you give an automatic name. The automatic name is only manual addition

25. "+" makes a preset with no name (only the swatch); the automatic name only when he ticks it. — **Status:** done in v8

## 6.10.2026, 10:00

> please update also my app for controlling my keyboard G815. Sometimes it is losing connection with the key, and then when I press M1 for example by accident on my keyboard it resets my layout. But it comes back sometimes, but not always. There was once it didn't come. So please, if you can, add some button to force detection of the keyboard and update the presets. Or yes, if it's not working I manually can kind of force it to recheck keyboard and it is going to scan and inform me what's wrong, why there is no right preset there

1. A button that forces detection of the keyboard and re-sends the presets; when it fails it scans and says what is wrong (why the right preset is not there). The loss: after M1 is pressed by accident the layout resets and does not always come back. **Status:** done, v9 (6.10.2026, 12:55): RECHECK KEYBOARD top right opens the keyboard again from nothing and reports, line by line in a floating panel: Input Monitoring, USB, another program on the keyboard (G HUB, OpenRGB, a second copy), the reopen, each bank's memory (CRC, rewritten if different), keyboard bank against the app's, then paints all. Also: BACK TO Mx after an M key moved him, LOCK Mx (M keys on the keyboard undone), and after any M switch the keys are painted again at 1.5, 3 and 6 s (the keyboard can reload its bank later than the first paint). Tested by clicking RECHECK on his Mac: all green.

## 6.10.2026, 14:40

> please in my G815 keyboard add a selection method with the lasso so I can lasso selection. Please. Thank you

2. Lasso selection: draw a free shape around keys to choose them. **Status:** done, v10: LASSO in the KEYS row (green when on); a drag draws a dashed amber loop, keys whose centre is inside are chosen; shift adds, option takes away; off, the drag paints across keys as before. Tested on his Mac through Hammerspoon: a loop around E R D F chose exactly those four.

## 6.10.2026

> for lasso selection, I mean by lasso is a square selection, so just turn in G815 Lights application instead of free lasso. It needs to draw squares only

3. Square selection instead of the free lasso. **Status:** done, v11: LASSO now draws a dashed amber rectangle from where the drag starts to the pointer, in any direction; keys whose centre is inside are chosen; shift adds, option takes away. Built and installed (old pid 59022, new pid 91582). Not yet tried by hand.

## 8.10.2026

> To selection modes we need to add mode single. That means I can select only one key at the time for modifications.

4. SINGLE selection mode: only one key chosen at a time. **Status:** done in code, v12: SINGLE in the KEYS row (green when on, off again with a second click; LASSO and SINGLE take turns, neither on = drag across keys as before). A click chooses that key alone and its colour comes into the picker; a drag moves the choice from key to key; ALL and SAME COLOUR are grey and do nothing while it is on; turning it on with many keys chosen clears the choice. Written in a cloud session with no Swift compiler: not yet built, installed or tried on his Mac (run ./install.sh).

> (8.10.2026) Can you please add to this repro a Swift workflow so the app compiles in the GitHub?

5. A GitHub workflow that compiles the app. **Status:** done: `.github/workflows/build.yml` runs `SIGN=- ./build.sh` on a macos-15 runner at every push and pull request (and by hand), and keeps the zipped app and build/g815 as a download. `build.sh` signs with "Mantra Apps" unless SIGN says otherwise, so his own builds are unchanged.

> (8.10.2026) Please in the app make the version number which is in the upper right corner clickable so it takes me to GitHub to download the latest version.

6. The version number top right is a link to GitHub, to download the latest version. **Status:** done in code, v13: the version number opens github.com/markoboskoauroville/G815_LIGHTS/releases/latest; the workflow now publishes the release v<VERSION> (zipped app + g815) on every push to main. Until this branch is merged into main there is no release yet, so the page is empty.

> (8.10.2026) Or even if it's possible that this app auto updates when a new version is detected.

> (8.10.2026) This repo can go public.

> (8.10.2026) Test update on my local computer application is running and updated to the next version.

7. The app updates itself when a new version is on GitHub. Asked how (an ad hoc GitHub build loses Input Monitoring, LESSONS 6), he chose "rebuild on this Mac". **Status:** done in code, v14 (app/Update.swift): two minutes after start, every 6 hours and when the window opens, `git fetch origin main` in the repo the app was built from; a higher VERSION there and a clean main → `git pull --ff-only`, ./build.sh (signed Mantra Apps), and a restart through the login agent once the window is closed and the keyboard has no job; the amber note top right ("v15 READY · RESTART") restarts at once and brings the window back. The repo is on another branch or has changes → it only says so. Compiled by GitHub; not yet run on his Mac.
8. The repo public. **Status:** it already is (GitHub answers without a login, 8.10.2026).
9. Test the update on his Mac: the running app goes to the next version by itself. **Status:** open. It needs his Mac (this session runs in the cloud): this branch merged into main, his repo on main with v14 installed, then a v15 on main.

> (8.10.2026) For any chain of commands like this, fix it: merge branch into main and install the same terminal. Always put it in repository manifest. In manifest you always give me the chain of commands so I can just copy-paste one block and it will execute one after the other. Please make that always.

10. Every chain of commands he has to run goes into MANIFEST.md as one block to copy and paste, each command running after the one before (and stopping at the first that fails). Kept up to date by every session: the rule is in CLAUDE.md. **Status:** done: MANIFEST.md (merge this branch into main, push, install), CLAUDE.md

## 8.10.2026 — macros

> Please let's build now macro functions for this keyboard. So when user presses MR button which is still not available in the interface, it will be able to create macros and the macros will be stored on local computer and updated every time the computer starts. The same principles of memory handling as light color of the light, but now we have macros and macro can be run with any key on the keyboard of course G1 to G5, but anyone can be assigned as macro trigger. Let's build macro editor and macro recorder for this keyboard now.

11. Macros: MR (on the keyboard and in the window) records; a macro editor and recorder in the window; kept on the Mac (~/.g815/settings.json) like the colours, per bank M1 M2 M3, put back at every start; any key can trigger one, G1–G5 first of all. **Status:** done in code, v15 (app/Macros.swift, app/MacroViews.swift), compiled by GitHub; not yet run on his Mac: test T1 in TESTS.md. Which bytes G1 and MR really send (HID++ 0x8010, 0x8030) is the open question T1 answers. T1 (his Mac, 8.10.2026 04:13–04:31): the features are there (G keys 0x0a, MR 0x0c), but a repaint loop every 0.77 s (every 0x8010 call makes the keyboard send three empty notes; the M-keys one repainted, the repaint called 0x8010 again). v16: 0x8010 only when the mode changes, notes from G/M/MR never repaint. Also: build/g815 was tracked by git, so every install left the repo "changed" (it blocked the pull, and the v14 updater would never have updated); untracked in v16. T2 (04:47–04:56): no loop, Accessibility on, updater clean; MR sends nothing in onboard mode; a reopen storm while Accessibility was switched on. v17: 1 s pause before a reopen; `g815 probe` to measure MR, G1, M keys; T3 open.

> (8.10.2026) After you build, you need to work with local Claude code for testing. So we are building here and testing in Claude code. It means that in MD need to create MD in repository in GitHub to exchange the test results and give a test task to local CloudCode. And I'm going to copy-paste command between two of you, and you are going to be able to test app on my computer and build it from here from the cloud.

12. TESTS.md in the repo: the cloud session writes the test task, the Claude Code on his Mac runs it on the real keyboard and writes the results back (commit, push); he only carries one line between the two. The rule in CLAUDE.md. **Status:** done: TESTS.md (how a task runs, T1 for the macros), CLAUDE.md, MANIFEST.md starts T1 on the Mac
