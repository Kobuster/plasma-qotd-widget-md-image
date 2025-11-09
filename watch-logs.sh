#!/bin/bash

# Watch plasmashell logs in real-time
# Useful for debugging issues as they happen

echo "Watching plasmashell logs (Ctrl+C to stop)..."
echo "Look for messages related to: org.kde.prajjwal.quotewidget"
echo ""
echo "================================================================"
echo ""

if command -v journalctl &> /dev/null; then
    journalctl --user -u plasma-plasmashell.service -f
else
    echo "journalctl not available. Trying dmesg..."
    dmesg -w | grep -i plasma
fi
