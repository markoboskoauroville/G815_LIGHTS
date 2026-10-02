#!/bin/sh
# install.sh: build, then put the login agent in place and start it (no window). Run again after a change.
set -e
cd "$(dirname "$0")"
./build.sh
P=~/Library/LaunchAgents/community.auroville.g815lights.plist
sed "s#\$HOME#$HOME#g" community.auroville.g815lights.plist > "$P"
launchctl bootout gui/$(id -u) "$P" 2>/dev/null || true
osascript -e 'quit app "G815 Lights"' 2>/dev/null || true
sleep 1
launchctl bootstrap gui/$(id -u) "$P"
echo "login agent installed and started: $P"
