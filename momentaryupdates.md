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
