#!/bin/sh
# press.sh <name> <key> ["probe calls"] ["note"] — the probe listens while ask.swift shows Marko the key;
# the box goes when he presses it (or clicks it), the probe 1.5 s later, then a camera shot. Output in $OUT/<name>.*
OUT="${OUT:-/tmp/g815press}"; mkdir -p "$OUT"
D=$(cd "$(dirname "$0")/.." && pwd); ASK="${ASK:-$OUT/ask}"
[ -x "$ASK" ] || swiftc -O "$D/tests/ask.swift" -o "$ASK" 2>/dev/null
"$D/build/g815" probe 300 $3 > "$OUT/$1.txt" 2>&1 & P=$!
sleep 0.5
# the voice says only the key, letter by letter ("M R", "G 1")
curl -s -m 2 -o /dev/null -X POST http://127.0.0.1:8837/speak -H 'Content-Type: application/json' \
  -d "{\"text\": \"$(echo "$2" | sed 's/./& /g')\"}" &
if [ -n "$4" ]; then "$ASK" "$2" "$4" --keys none --watch "$OUT/$1.txt" > "$OUT/$1.ask"; else "$ASK" "$2" --keys none --watch "$OUT/$1.txt" > "$OUT/$1.ask"; fi
sleep 1.5; kill $P 2>/dev/null; wait $P 2>/dev/null
"$D/tests/kbshot.sh" "$OUT/$1.png" >/dev/null
echo "== $1 ($2): $(cat "$OUT/$1.ask")"; grep -v 'listening' "$OUT/$1.txt"
