#!/bin/bash
# Build an installable build/com.github.kobuster.noteshuffle.plasmoid
# (install it with: kpackagetool6 -t Plasma/Applet -i build/com.github.kobuster.noteshuffle.plasmoid)
set -e
cd "$(dirname "$0")"
ID=com.github.kobuster.noteshuffle
rm -rf build && mkdir -p "build/$ID"
cp -r package/. "build/$ID/"
(cd build && zip -qr "$ID.plasmoid" "$ID" && rm -rf "$ID")
echo "Built build/$ID.plasmoid"
