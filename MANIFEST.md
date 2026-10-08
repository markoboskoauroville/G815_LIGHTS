# MANIFEST — what to run on the Mac now

One block: copy it, paste it into Terminal, press Return. The commands run one after the other; `&&` stops at the
first one that fails, so nothing runs on top of a failure. Every session that leaves something for the Mac to do
writes the block here (CLAUDE.md).

## Now: test v17 (T3: what MR sends, macros without MR) with the Claude Code on this Mac (8.10.2026)

Pulls v17 and starts Claude Code on test T3 in TESTS.md. It stops the app for a few minutes to measure what MR, G1
and M1–M3 send (you press them when it says), starts the app again, then tests macros on F5 and G1 in TextEdit.

```sh
cd ~/Developer/G815_LIGHTS && git checkout claude/upbeat-mendel-yhjx3q && git pull --ff-only origin claude/upbeat-mendel-yhjx3q && claude "Read TESTS.md and run test T3 as it says. Write the results into TESTS.md, commit and push them, and check the push arrived."
```

Done when Claude Code says "Results pushed". Then tell the cloud: `Test results are in TESTS.md.`

## Always: build and install what main has

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && ./install.sh
```
