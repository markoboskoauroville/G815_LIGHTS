# MANIFEST — what to run on the Mac now

One block: copy it, paste it into Terminal, press Return. The commands run one after the other; `&&` stops at the
first one that fails, so nothing runs on top of a failure. Every session that leaves something for the Mac to do
writes the block here (CLAUDE.md).

## Now: nothing to run (9.10.2026)

v20 is on main and installed on this Mac: M KEYS LIGHT (OFF / ON) under KEYBOARD BRIGHTNESS. Try it: TESTS.md T5.

## Always: build and install what main has

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && ./install.sh
```
