#!/bin/sh
# kbshot.sh <out.png> — the keyboard as the NDI camera sees it, cut out of the scrcpy window
# ("Pixel 7"), turned upright. The window's place is asked from the window server each time.
OUT="${1:-/tmp/kb.png}"
ID=$(swift -e 'import CoreGraphics
let l = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as! [[String: Any]]
for w in l where (w["kCGWindowOwnerName"] as? String) == "scrcpy" { print(w["kCGWindowNumber"]!); break }' 2>/dev/null)
[ -n "$ID" ] || { echo "kbshot: no scrcpy window"; exit 1; }
screencapture -x -o -l "$ID" "$OUT" && sips -r 270 "$OUT" >/dev/null && echo "$OUT"
