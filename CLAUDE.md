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
- **Testing goes through TESTS.md** (Marko, 8.10.2026: "we are building here and testing in Claude code ... I'm going
  to copy-paste command between two of you"). The cloud session writes the code and a numbered test task (T1, T2 …)
  in `TESTS.md`: the branch, numbered steps, what to expect, what log lines to quote. The Claude Code on his Mac runs
  it on the real keyboard, writes the results under the task, commits and pushes. MANIFEST.md's "Now" block is what
  starts it on the Mac; he brings back "Test results are in TESTS.md". Read the results before the next change, and
  mark the task's Status (open / passed / failed: what next).
- **When Marko asks the Mac to finish the work** (8.10.2026: "please finish all pending jobs"), the Claude Code on his
  Mac writes the code too, tests it on the keyboard, and writes its results as a T task in `TESTS.md` like any other,
  so the cloud reads where things stand before its next change.
- **VERSION** in `app/Views.swift` goes up with every change he will see; the app updates itself from main when it
  is higher (`app/Update.swift`), so work reaches his Mac only through main.
- **No Swift here?** The cloud has no swiftc: push, and read the GitHub build (`.github/workflows/build.yml`).
