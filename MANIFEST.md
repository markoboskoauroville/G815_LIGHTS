# MANIFEST — what to run on the Mac now

One block: copy it, paste it into Terminal, press Return. The commands run one after the other; `&&` stops at the
first one that fails, so nothing runs on top of a failure. Every session that leaves something for the Mac to do
writes the block here (CLAUDE.md).

## Now: test v16 (the loop fixed) with the Claude Code on this Mac (8.10.2026)

Puts back the two old built programs git tracked (the pull takes them out of git), pulls v16, and starts Claude Code
on test T2 in TESTS.md. It installs v16, checks the loop is gone, then asks you to allow Accessibility and to press
keys (MR, G1, typing in TextEdit).

```sh
cd ~/Developer/G815_LIGHTS && git checkout claude/upbeat-mendel-yhjx3q && git checkout -- build/g815 build/list && git pull --ff-only origin claude/upbeat-mendel-yhjx3q && claude "Read TESTS.md and run test T2 as it says. Write the results into TESTS.md, commit and push them, and check the push arrived."
```

Done when Claude Code says "Results pushed". Then tell the cloud: `Test results are in TESTS.md.`

## Always: build and install what main has

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && ./install.sh
```
