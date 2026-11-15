#!/bin/bash
# Install or upgrade the widget for the current user.
#   ./install.sh            install or upgrade
#   ./install.sh --restart  also restart plasmashell, so a running widget picks up the new code
set -e
cd "$(dirname "$0")"
if kpackagetool6 -t Plasma/Applet -u package 2>/dev/null; then
    echo "Upgraded."
else
    kpackagetool6 -t Plasma/Applet -i package
    echo "Installed. Add it via right-click on the desktop > Add Widgets > Note Shuffle."
fi
if [ "$1" = "--restart" ]; then
    systemctl --user restart plasma-plasmashell.service
fi
