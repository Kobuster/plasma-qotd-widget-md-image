#!/bin/bash

# Test the Quote of the Day widget in an isolated window
# Useful for development and debugging without affecting your desktop

PLUGIN_ID="org.kde.prajjwal.quotewidget"

echo "Testing Quote of the Day widget in isolated window..."
echo "Press Ctrl+C to close the test window"
echo ""

# Check if widget is installed
if ! kpackagetool5 -t Plasma/Applet --show "$PLUGIN_ID" &>/dev/null && \
   ! kpackagetool6 -t Plasma/Applet --show "$PLUGIN_ID" &>/dev/null; then
    echo "ERROR: Widget not installed. Run ./install.sh first."
    exit 1
fi

# Launch in test window
if command -v plasmawindowed &> /dev/null; then
    plasmawindowed "$PLUGIN_ID"
else
    echo "ERROR: plasmawindowed not found"
    echo "Try: plasmoidviewer -a $PLUGIN_ID"
fi
