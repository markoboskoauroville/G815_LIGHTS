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
   lands on the keys (the bug in OpenRGB). — **Status:** done (per-key colour through 0x8081, seen on the keys with the camera)
3. Static colours only, no effects. — **Status:** done (static only; the onboard banks hold one still colour, no effect)
4. Per-key brightness, on top of the keyboard's own brightness button. — **Status:** done (each key's own brightness; since v18 squares fitted to the measured steps)
5. Key presets: a few named colours, applied to a group of selected keys. — **Status:** done (presets: named or automatic, drag to reorder)
6. A few memories (profiles) of his settings. — **Status:** done (M1 M2 M3, each its own layout on the Mac)
7. Write to the keyboard's onboard memory, so it lights his profile from power-on with no light show.
   If the keyboard cannot hold per-key static colours, say so plainly. — **Status:** done: the keyboard's memory holds one still colour per zone, not per-key (said in README); per-key comes from the app at every start
8. A row in the star menu; loads with the Mac and re-applies the saved settings at every start. — **Status:** done (the star's row Keyboard and mouse › G815 Lights; login agent; repaint at every start)

## 2.10.2026, 02:20 — see the keyboard through the screen, and the camera's white balance

> Please, I enabled the camera through my screen copy so it's running in a small window. You need to screen capture, not use camera. Actually screen capture on the screen, find the area, and you have the full view and full colors of my keyboard. You can fix it, you can program it, you can do anything now. Also, I'm using my own app. This is my own camera NDI camera. If colors don't match, you need to also update my camera because white balancing is not functioning now. We can use opportunity with these LED lights which are the colors of the light pure spectrum to also calibrate my camera so it gives the true colors. Now white balance is a bit off, it's almost there but it's bit off. So fix my camera and fix my keyboard application.

9. Look at the keyboard through a SCREEN capture of the small window showing his NDI camera (not a Mac camera). — **Status:** started
10. The NDI camera's white balance is a bit off: use the keyboard's pure LED colours to calibrate it, and fix
    the camera (MANTRA_NDI). — **Status:** done in MANTRA_NDI (2.10.2026, v100–v106: the TRIANGLE white balance, true colours against the G815; HANDOVER)

## 2.10.2026, 03:05 — memory buttons on the map, one bank each, saved in the Mac and in the keyboard

> We can simplify and emulate the usage of the keyboard in the visual map of the keyboard. Please also include memory buttons so usage is very simple. I press the memory button and adjust my keyboard settings, basically the colors and brightness of each key, and it stays under that memory as well as my computer as well inside the keyboard. So let's do that. So simple switching the banks of memory visually on the screen and then adjusting the screen colors, and they stay in memory. I think that's the great idea

11. M1 M2 M3 drawn on the map as the keyboard's own memory keys; pressing one switches the bank on screen AND on
    the keyboard; pressing M1..M3 on the real keyboard switches the page too. — **Status:** started
12. Every change is kept under the active bank on the Mac and written into that bank of the keyboard by itself
    (no WRITE button); the keyboard's bank holds one still colour per zone (its limit), the Mac the per-key colours. — **Status:** started

## 2.10.2026, 03:15 — the drawing looks like the real keyboard, and Swift only

> please match exactly the keyboard view to the real keyboard. So my keyboard is black, so keys should be black with lights on. Also, these memory buttons are yellow on the keyboard, so please you have a screenshot and the look in real life should match as close as possible to the view in our app. Also, build a Swift app. Swiftapp should be the default, and then web app is the second. Actually, you don't need to build with webapp at all. We just can focus on Swift. There is no need for web apps anymore. Swift is great and we work with Swift only now

13. The drawing as the real keyboard: black keycaps, the legend lit in the key's colour; the M1 M2 M3 keys
    yellow as on the keyboard (the active one lit). Match the camera picture as closely as possible. — **Status:** done (the drawing as the keyboard; the active M lit)
14. A native Swift app, the only face; no web page. — **Status:** done (v4 and on; the star only opens it) (this replaces the page and the
    Hammerspoon server; the star's row will start the Swift app)

## 2.10.2026, 03:20 — permission given; test, login agent, OpenRGB out, the rest

> Add the permission test all the keyboard. Add the login agent. Okay, I already changed the permissions, so please test it. Open RGB starting automatically, yes. Remove and do all other points. That's great.

15. Input Monitoring granted by Marko: test everything on the real keyboard. — **Status:** started
16. The login agent (paints at every start, no window). — **Status:** done (install.sh writes it; RunAtLoad)
17. OpenRGB out of the login items (he said yes). — **Status:** done (its agent moved to ~/.g815/OpenRGB.plist.removed-2.10.2026; checked 8.10.2026: not in the login items)
18. "All other points": app icon, documents (README, TAKEOVER, LESSONS), registry, handover; then the camera's
    white balance and the MIDI apps as Swift-only. — **Status:** done for this app (icon, README/TAKEOVER/LESSONS, registry, handover; the camera in MANTRA_NDI). The MIDI apps as Swift-only belong to their own projects.

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
9. Test the update on his Mac: the running app goes to the next version by itself. **Status:** done 8.10.2026: v18 running from main, v19 pushed to main from another clone; opening the window made it log `update: v18 → v19: pull and build`, `v19 built, restarting when the window is closed`, and a minute after the window closed `restarting into v19`, then `watching …, v19` (the keyboard handed back and taken over again on the way).

> (8.10.2026) For any chain of commands like this, fix it: merge branch into main and install the same terminal. Always put it in repository manifest. In manifest you always give me the chain of commands so I can just copy-paste one block and it will execute one after the other. Please make that always.

10. Every chain of commands he has to run goes into MANIFEST.md as one block to copy and paste, each command running after the one before (and stopping at the first that fails). Kept up to date by every session: the rule is in CLAUDE.md. **Status:** done: MANIFEST.md (merge this branch into main, push, install), CLAUDE.md

## 8.10.2026 — macros

> Please let's build now macro functions for this keyboard. So when user presses MR button which is still not available in the interface, it will be able to create macros and the macros will be stored on local computer and updated every time the computer starts. The same principles of memory handling as light color of the light, but now we have macros and macro can be run with any key on the keyboard of course G1 to G5, but anyone can be assigned as macro trigger. Let's build macro editor and macro recorder for this keyboard now.

11. Macros: MR (on the keyboard and in the window) records; a macro editor and recorder in the window; kept on the Mac (~/.g815/settings.json) like the colours, per bank M1 M2 M3, put back at every start; any key can trigger one, G1–G5 first of all. **Status:** done in code, v15 (app/Macros.swift, app/MacroViews.swift), compiled by GitHub; not yet run on his Mac: test T1 in TESTS.md. Which bytes G1 and MR really send (HID++ 0x8010, 0x8030) is the open question T1 answers. T1 (his Mac, 8.10.2026 04:13–04:31): the features are there (G keys 0x0a, MR 0x0c), but a repaint loop every 0.77 s (every 0x8010 call makes the keyboard send three empty notes; the M-keys one repainted, the repaint called 0x8010 again). v16: 0x8010 only when the mode changes, notes from G/M/MR never repaint. Also: build/g815 was tracked by git, so every install left the repo "changed" (it blocked the pull, and the v14 updater would never have updated); untracked in v16. T2 (04:47–04:56): no loop, Accessibility on, updater clean; MR sends nothing in onboard mode; a reopen storm while Accessibility was switched on. v17: 1 s pause before a reopen; `g815 probe` to measure MR, G1, M keys; T3 open.

> (8.10.2026) After you build, you need to work with local Claude code for testing. So we are building here and testing in Claude code. It means that in MD need to create MD in repository in GitHub to exchange the test results and give a test task to local CloudCode. And I'm going to copy-paste command between two of you, and you are going to be able to test app on my computer and build it from here from the cloud.

12. TESTS.md in the repo: the cloud session writes the test task, the Claude Code on his Mac runs it on the real keyboard and writes the results back (commit, push); he only carries one line between the two. The rule in CLAUDE.md. **Status:** done: TESTS.md (how a task runs, T1 for the macros), CLAUDE.md, MANIFEST.md starts T1 on the Mac

> (8.10.2026, ~06:15, on the Mac during T3) before we continue, you need to repeat the text test because I was using a computer. I need to tell you this: G keys are repeating, F keys send the same key command. For example, F1 I'm using to transcribe with Speechify this voice to you, and when I press G1 my Speechify is popping up, which is an undesirable result. So how does the original app Logitech G Hub use it? When it's running, the G keys have special treatment. They're not the same as function keys. Please detach G's with functions. They are doing the same thing

13. G1–G5 never type F1–F5. In onboard mode (0x8010 software control off) the keyboard's own profile makes G1 = F1 … G5 = F5, so G1 opens Speechify (his F1). Measured in T3 (probe): with `8010:2:01` the G keys send only HID++ notes (`11 ff 0a 00 01` for G1, `00 10` for G5) and no F key reaches macOS, and MR sends `11 ff 0c 00 01` too — that is how G HUB holds them while it runs. So: the app keeps 0x8010 software control on in every bank, all the time it runs (not only in a bank with a G macro); a G key with no macro does nothing. When the app is not running the onboard profile still says F1–F5: writing G1–G5 to "nothing" in the onboard profiles (0x8100) would cover that too. **Status:** done in v18 on the Mac (8.10.2026), tested on the keyboard: the app holds G1–G5 in every bank and runs the keyboard in host mode (the M light and M keys through the app, LESSONS 17); every bank in the keyboard's memory says \"nothing\" for G1–G5, so with the app stopped G1 typed nothing and Speechify stayed shut. MR is heard in every bank; its own light cannot be set (LESSONS 18).

> (8.10.2026, ~07:00, on the Mac) please finish all pending jobs

14. Done on the Mac this time (the Claude Code on his Mac writes the code and tests it on the keyboard), on the branch,
    then merged into main: item 13 (G keys detached), the MR light, the window notes from T3, the merge, the updater
    test (item 9), the old statuses tidied. **Status:** v18 done and tested on the keyboard (TESTS.md T4); merged into
    main 8.10.2026; the updater test follows with v19.

> (8.10.2026, ~08:15, on the Mac) now you need to work on the brightness slider. Actually, there is no more slider, only plus and minus. And you need to test with the camera the triggering point of the brightness because it's not continuous, it jumps. For each step make plus or minus, so there are no empty steps. Only steps which actually change the brightness exist. Let's do that now you have a camera and you can do it yourself easily

15. The keyboard's brightness: no slider, only − and +; each press goes to the next level the keys really show. The
    levels measured with the camera (0x8040 swept 0–100). **Status:** measured (0 12 25 50 100, LESSONS 20); replaced
    by item 16 before it shipped.

> (8.10.2026, ~08:25, on the Mac) actually, since there are not many levels of brightness, you just make small squares swatches so user can jump directly to brightness level

16. The keyboard's brightness as five small squares, one per real level (OFF 12 25 50 100); a click jumps to it.
    Replaces item 15's − and +. **Status:** done in v18, clicked and read back (square 100 → 100, 12 → 12).

> (8.10.2026, ~08:30, on the Mac) of course, keyboard brightness should also affect each individual key. We need to have a key brightness with the same swatches
> what I mean by that I want to control for each individual key brightness with the same swatches
> or replacing the key brightness slider

17. KEY BRIGHTNESS (each key's own) as the same five squares, in place of its slider. **Status:** done in v18, with its
    own measured steps (item 18).

> (8.10.2026, ~08:35, on the Mac) if there are different steps between total keyboard brightness and each individual key brightness, adjust the new swatches to individual key. Test the key brightness resolution and adjust swatches to fit exactly so we don't lose any values

18. Measure each key's own brightness (its colour scaled, 0x8081) with the camera and give KEY BRIGHTNESS squares
    that fit its real steps, none lost. **Status:** done in v18: 0–44 dark, light from 45 (18 %), then smooth; squares
    OFF 18 30 45 60 80 100 (LESSONS 20). ESC set to 30 and 100 from the squares, read back from settings.json.

## 9.10.2026, ~07:35, on the Mac — brightness of the memory keys

> please, while you are waiting for new instructions from Djapp Cloud, fix my application g815 so I can also change the brightness of memory key and 1 and 2 and m3. Please update my app so it's able to control these settings

19. The lights of the memory keys (M1, M2, M3, and MR if it can be done) get a brightness the user sets in the
    window, like any other key. **Status:** v20 on the Mac, 9.10.2026: the keyboard has no brightness for the M lights,
    only on and off (LESSONS 21), and MR's light cannot be set (LESSONS 18). So M KEYS LIGHT, two squares OFF ON under
    KEYBOARD BRIGHTNESS; lit, they follow the keyboard's brightness. Built, installed, running; the click is his to try (TESTS T5).

## 19.10.2026: ON / OFF at the top of the window

> "When I select any of the apps, the user interface opens up. In the top of every user interface, there will now be an on/off switch ... If I say on, I close it's on ... When I just switch the check mark, and that's how I activate it. This is gone. Let's work like this. This is the workflow now." (Marko, 19.10.2026; the rule in MANTRA_MANIFEST modules/swift-apps.md, "ON / OFF at the top of every window")

The first row of the main window is ON / OFF; OFF stops the engine and quits; closing the window leaves the app on; the star only opens it.

**Status:** v21 built 19.10.2026: G815 LIGHTS ON OFF on the first row (OFF = NSApp.terminate; applicationWillTerminate gives the keyboard its own mode back; the login agent has no KeepAlive, so it stays off). Closing the window already left the keeper running and the reopen already showed it (v1). Restarted through the login agent: old pid 696, new pid 46849 (--background, no window, as it was); the window seen once by screenshot in between. TESTS T6. Marko to try OFF.

## 19.10.2026: ✕ close at the far upper-right corner

> "please unify the position of the close button on every application. It's far upper right corner. There is X to close the dialog in every dialog, same." (Marko, 19.10.2026)

A ✕ at the window's top-right corner, on the ON / OFF row: it closes the window only, the app stays ON. Every other dialog gets the same ✕ in its corner. The title bar and its traffic lights stay.

**Status:** v21: ✕ (SF Symbol xmark, grey #7A8087, 28×28) at the far right of the first row, after v21; performClose, the keeper stays. The preset rename popover has the same ✕ in its corner. Seen by screenshot. Marko to try it (TESTS T6).

## 30.10.2026: PERMISSIONS at the top right

> please make this in every application that needs some permission. If permissions are not set, it needs to have text in the top right: "Permissions." Then I click on it, and it opens me directly to my settings page where I need to set permissions.

**Status:** done in v22 (30.10.2026): PERMISSIONS (amber, the row's own Word) on the ON / OFF row, right of the spacer and left of RECHECK KEYBOARD, v22 and ✕, while Input Monitoring (the light interface, checked strictly: Accessibility does not stand in for it here) or Accessibility (the macros' key tap and playing) is off. A click asks once and opens Privacy_ListenEvent or Privacy_Accessibility, the first missing. Re-read every 2 s, set only on change. At --background (the login agent) nothing is asked any more (it used to ask for Input Monitoring at every start). Built; the login agent restarted with launchctl kickstart -k (pid 581 → 39899). No window open, so not seen on screen.

## 31.10.2026

> Please, in the same app, since it's now by the way, this is about the G815.
> I want the G-keys to control something. The G-keys are the column of keys from G1 to G5. Each key should invoke a module of DaVinci Resolve, in the order in which they are shown on the user interface.
> Pressing the number 1 will trigger number 1, then number 2, then number 3. If I change how many there are, it should also change what it triggers.

> We built a Swift app to control the keyboard. You use that code.

- While DaVinci Resolve is in front, G1–G5 open its pages in the order of its page bar (read live through Accessibility: hidden pages drop out, the keys follow); elsewhere the macros as before. **Status:** built v23 (app/ResolvePages.swift), running; Marko tests

> Yes, it does select those things, those workspaces, but it doesn't actually switch to them. I'm confused about what's going on. How is that possible?

- Found: AXPress lights the page button but Resolve (Qt) does not switch; now resolve.OpenPage through the DaVinci Resolve Actions router (127.0.0.1:8940), the bar still read live for the order. **Status:** done v24 (OpenPage tested: cut, edit, about 0.1 s); Marko tests the keys

- G-key press → a distributed notification to E16 for DaVinci Resolve (its window lights the key). **Status:** done v25

> Yes, that's a great idea, because by default those G keys have no light when I press them.
> So only one key should light at a time, please.

- While Resolve is in front, the G-key of its current page lights on the keyboard, only one at a time; the others dark; back to the bank's colours when Resolve is not in front. **Status:** built v26 (Store.resolveG over paint, followResolve once a second, lit at once on a press); waiting for the camera to see it
