#!/bin/bash

# Uninstall the Quote of the Day widget completely

PLUGIN_ID="org.kde.prajjwal.quotewidget"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"

echo "Uninstalling Quote of the Day widget..."
echo ""

# Remove via package tools
if command -v kpackagetool5 &> /dev/null; then
    echo "Removing via kpackagetool5..."
    kpackagetool5 -t Plasma/Applet --remove "$PLUGIN_ID" 2>/dev/null || true
fi

if command -v kpackagetool6 &> /dev/null; then
    echo "Removing via kpackagetool6..."
    kpackagetool6 -t Plasma/Applet --remove "$PLUGIN_ID" 2>/dev/null || true
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing installation directory..."
    rm -rf "$INSTALL_DIR"
    echo "✓ Removed $INSTALL_DIR"
fi

echo ""
echo "Uninstallation complete!"
echo ""
echo "To apply changes, restart plasmashell:"
echo "  killall plasmashell && kstart5 plasmashell"
echo ""
echo "Note: This does not remove your quotes folder or configuration."
echo "Quotes folder remains at: ~/Documents/Quotes"
