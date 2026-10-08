# MANIFEST — what to run on the Mac now

One block: copy it, paste it into Terminal, press Return. The commands run one after the other; `&&` stops at the
first one that fails, so nothing runs on top of a failure. Every session that leaves something for the Mac to do
writes the block here (CLAUDE.md).

## Now: test the macros (v15) with the Claude Code on this Mac (8.10.2026)

Fetches the branch with v15, puts this folder on it, and starts Claude Code on test T1 in TESTS.md. Claude Code
builds and installs v15 itself, asks you to press keys (G1, MR …) and to allow Accessibility, then writes the
results into TESTS.md and pushes them.

```sh
cd ~/Developer/G815_LIGHTS && git fetch origin claude/upbeat-mendel-yhjx3q && git checkout claude/upbeat-mendel-yhjx3q && git pull --ff-only origin claude/upbeat-mendel-yhjx3q && claude "Read TESTS.md and run test T1 as it says. Write the results into TESTS.md, commit and push them."
```

Done when Claude Code says "Results pushed". Then tell the cloud session: `Test results are in TESTS.md.`

While this folder is on the test branch, the app does not update itself from main (it says so top right); the
"Always" block below puts it back on main.

## Always: build and install what main has

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && ./install.sh
```
