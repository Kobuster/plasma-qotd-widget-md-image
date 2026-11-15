#!/bin/bash
# Remove the widget for the current user.
set -e
kpackagetool6 -t Plasma/Applet -r com.github.kobuster.noteshuffle
