# MANIFEST — what to run on the Mac now

One block: copy it, paste it into Terminal, press Return. The commands run one after the other; `&&` stops at the
first one that fails, so nothing runs on top of a failure. Every session that leaves something for the Mac to do
writes the block here (CLAUDE.md).

## Now: send the T1 results to GitHub (8.10.2026)

The test results were written into TESTS.md on the Mac but never reached GitHub, so the cloud cannot read them.
This checks the folder is on the test branch, commits TESTS.md if it is not committed yet, and pushes.

```sh
cd ~/Developer/G815_LIGHTS && test "$(git branch --show-current)" = claude/upbeat-mendel-yhjx3q && git add TESTS.md && (git diff --cached --quiet || git commit -m "TESTS: results T1") && git pull --rebase origin claude/upbeat-mendel-yhjx3q && git push origin claude/upbeat-mendel-yhjx3q && git log --oneline -1
```

Done when the last line shows a commit like `TESTS: results T1`. Then tell the cloud: `Test results are in TESTS.md.`
If it stops at once with no message, the folder is on another branch: send the cloud the output of
`cd ~/Developer/G815_LIGHTS && git status && git log --oneline -3`.

## Always: build and install what main has

```sh
cd ~/Developer/G815_LIGHTS && git checkout main && git pull --ff-only origin main && ./install.sh
```
