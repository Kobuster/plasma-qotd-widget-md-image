#!/bin/bash

# Debug helper for Quote of the Day Plasmoid
# Shows detailed information about the widget installation and state

set -e

PLUGIN_ID="org.kde.prajjwal.quotewidget"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}Quote of the Day - Debug Information${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check Plasma version
echo -e "${YELLOW}[Plasma Version]${NC}"
if command -v plasmashell &> /dev/null; then
    plasmashell --version
else
    echo -e "${RED}plasmashell not found!${NC}"
fi
echo ""

# Check installation directory
echo -e "${YELLOW}[Installation Directory]${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}✓ Installed at: $INSTALL_DIR${NC}"
    echo "  Contents:"
    ls -lah "$INSTALL_DIR"
    echo ""
    echo "  Files structure:"
    tree "$INSTALL_DIR" 2>/dev/null || find "$INSTALL_DIR" -type f
else
    echo -e "${RED}✗ Not found at: $INSTALL_DIR${NC}"
fi
echo ""

# Check package tools
echo -e "${YELLOW}[Package Tools]${NC}"
if command -v kpackagetool5 &> /dev/null; then
    echo -e "${GREEN}✓ kpackagetool5 available${NC}"
    echo "  Installed packages:"
    kpackagetool5 -t Plasma/Applet --list | grep -i quote || echo "  (no quote widgets found)"
fi

if command -v kpackagetool6 &> /dev/null; then
    echo -e "${GREEN}✓ kpackagetool6 available${NC}"
    echo "  Installed packages:"
    kpackagetool6 -t Plasma/Applet --list | grep -i quote || echo "  (no quote widgets found)"
fi
echo ""

# Check metadata files
echo -e "${YELLOW}[Metadata Files]${NC}"
if [ -f "$INSTALL_DIR/metadata.desktop" ]; then
    echo -e "${GREEN}✓ metadata.desktop (Plasma 5)${NC}"
    cat "$INSTALL_DIR/metadata.desktop"
elif [ -f "$INSTALL_DIR/metadata.json" ]; then
    echo -e "${GREEN}✓ metadata.json (Plasma 6)${NC}"
    cat "$INSTALL_DIR/metadata.json"
else
    echo -e "${RED}✗ No metadata file found${NC}"
fi
echo ""

# Check core files
echo -e "${YELLOW}[Core Files]${NC}"
for file in "contents/ui/main.qml" "contents/config/main.xml" "contents/config/config.qml" "contents/ui/configGeneral.qml"; do
    if [ -f "$INSTALL_DIR/$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file${NC}"
    fi
done
echo ""

# Check configuration
echo -e "${YELLOW}[Configuration]${NC}"
CONFIG_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
if [ -f "$CONFIG_FILE" ]; then
    echo "Active widget instances:"
    grep -A 5 "$PLUGIN_ID" "$CONFIG_FILE" 2>/dev/null || echo "  (no active instances found)"
else
    echo -e "${RED}Configuration file not found${NC}"
fi
echo ""

# Check quotes folder
echo -e "${YELLOW}[Quotes Folder]${NC}"
QUOTES_DIR="$HOME/Documents/Quotes"
if [ -d "$QUOTES_DIR" ]; then
    echo -e "${GREEN}✓ Exists: $QUOTES_DIR${NC}"
    echo "  Quote files:"
    ls -lh "$QUOTES_DIR"/*.txt 2>/dev/null || echo "  (no .txt files found)"
else
    echo -e "${RED}✗ Not found: $QUOTES_DIR${NC}"
fi
echo ""

# Check running processes
echo -e "${YELLOW}[Running Processes]${NC}"
if pgrep -x "plasmashell" > /dev/null; then
    echo -e "${GREEN}✓ plasmashell is running${NC}"
    echo "  PID: $(pgrep -x plasmashell)"
else
    echo -e "${RED}✗ plasmashell is not running${NC}"
fi
echo ""

# QML errors check
echo -e "${YELLOW}[Recent QML Errors]${NC}"
if command -v journalctl &> /dev/null; then
    echo "Recent plasmashell errors:"
    journalctl --user -u plasma-plasmashell.service -n 20 --no-pager | grep -i "error\|warning" || echo "  (no recent errors)"
else
    echo "  journalctl not available"
fi
echo ""

# Suggestions
echo -e "${BLUE}[Debugging Suggestions]${NC}"
echo "1. View live logs:"
echo "   journalctl --user -u plasma-plasmashell.service -f"
echo ""
echo "2. Test widget in isolation:"
echo "   plasmawindowed $PLUGIN_ID"
echo ""
echo "3. Restart plasmashell with logging:"
echo "   killall plasmashell && plasmashell --replace 2>&1 | tee ~/plasma-debug.log"
echo ""
echo "4. Check QML syntax:"
echo "   qmlscene $INSTALL_DIR/contents/ui/main.qml"
echo ""
echo "5. Reinstall widget:"
echo "   ./install.sh"
echo ""
