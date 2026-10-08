# CLAUDE.md — rules for working in this repo

- **Requests first.** Every request from Marko goes into `momentaryupdates.md` word for word, with a Status line,
  committed before any code.
- **MANIFEST.md, always** (Marko, 8.10.2026: "In manifest you always give me the chain of commands so I can just
  copy-paste one block and it will execute one after the other. Please make that always."). Whenever he has to run
  commands on his Mac (merge a branch into main, pull, install, anything), write them in `MANIFEST.md` as ONE
  fenced `sh` block on one line, joined with `&&`, starting with `cd ~/Developer/G815_LIGHTS`, so one copy-paste
  runs them in order and stops at the first failure. Say what "done" looks like under it. Replace the "Now"
  section each time; never give him a list of separate commands in chat without the same block in the manifest.
  In chat, give the same single block.
- **VERSION** in `app/Views.swift` goes up with every change he will see; the app updates itself from main when it
  is higher (`app/Update.swift`), so work reaches his Mac only through main.
- **No Swift here?** The cloud has no swiftc: push, and read the GitHub build (`.github/workflows/build.yml`).
