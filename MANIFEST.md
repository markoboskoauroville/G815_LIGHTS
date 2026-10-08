# MANIFEST — what to run on the Mac now

One block: copy it, paste it into Terminal, press Return. The commands run one after the other; `&&` stops at the
first one that fails, so nothing runs on top of a failure. Every session that leaves something for the Mac to do
writes the block here (CLAUDE.md).

## Now: merge the work into main and install it (8.10.2026)

The branch `claude/upbeat-mendel-yhjx3q` holds v12–v14: SINGLE selection, the GitHub build, the version number
that opens GitHub, and the app updating itself. This puts it on main, sends main to GitHub, builds and installs.

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && git fetch origin claude/upbeat-mendel-yhjx3q && git merge --no-edit origin/claude/upbeat-mendel-yhjx3q && git push origin main && ./install.sh
```

Done when the last line says `built build/g815 and build/G815 Lights.app (v14)` and then `login agent installed
and started`. The window shows v14 top right.

## Always: build and install what main has

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && ./install.sh
```
