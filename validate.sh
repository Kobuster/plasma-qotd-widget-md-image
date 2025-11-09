#!/bin/bash

# Validate the widget package structure
# Checks for common issues before installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 (missing)"
        ((ERRORS++))
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ (missing)"
        ((ERRORS++))
        return 1
    fi
}

echo "Validating Quote of the Day widget package..."
echo ""

# Check directory structure
echo "Directory structure:"
check_dir "$SCRIPT_DIR/package"
check_dir "$SCRIPT_DIR/package/contents"
check_dir "$SCRIPT_DIR/package/contents/ui"
check_dir "$SCRIPT_DIR/package/contents/config"
check_dir "$SCRIPT_DIR/plasma5"
check_dir "$SCRIPT_DIR/plasma6"
echo ""

# Check core files
echo "Core files:"
check_file "$SCRIPT_DIR/package/contents/ui/main.qml"
check_file "$SCRIPT_DIR/package/contents/ui/configGeneral.qml"
check_file "$SCRIPT_DIR/package/contents/config/main.xml"
check_file "$SCRIPT_DIR/package/contents/config/config.qml"
echo ""

# Check platform adapters
echo "Platform adapter files:"
check_file "$SCRIPT_DIR/plasma5/metadata.desktop"
check_file "$SCRIPT_DIR/plasma6/metadata.json"
echo ""

# Check scripts
echo "Installation scripts:"
check_file "$SCRIPT_DIR/install.sh"
check_file "$SCRIPT_DIR/debug.sh"
check_file "$SCRIPT_DIR/test-widget.sh"
check_file "$SCRIPT_DIR/uninstall.sh"
echo ""

# Validate QML syntax (if qmlscene available)
if command -v qmlscene &> /dev/null; then
    echo "QML syntax check:"
    if qmlscene --quit "$SCRIPT_DIR/package/contents/ui/main.qml" 2>&1 | grep -i "error" > /dev/null; then
        echo -e "${RED}✗ QML syntax errors found${NC}"
        qmlscene --quit "$SCRIPT_DIR/package/contents/ui/main.qml" 2>&1 | grep -i "error"
        ((ERRORS++))
    else
        echo -e "${GREEN}✓ QML syntax OK${NC}"
    fi
    echo ""
else
    echo -e "${YELLOW}⚠${NC} qmlscene not available, skipping QML syntax check"
    echo ""
fi

# Validate XML
if command -v xmllint &> /dev/null; then
    echo "XML validation:"
    if xmllint --noout "$SCRIPT_DIR/package/contents/config/main.xml" 2>&1; then
        echo -e "${GREEN}✓ main.xml is valid${NC}"
    else
        echo -e "${RED}✗ main.xml has errors${NC}"
        ((ERRORS++))
    fi
    echo ""
else
    echo -e "${YELLOW}⚠${NC} xmllint not available, skipping XML validation"
    echo ""
fi

# Validate JSON
if command -v jq &> /dev/null; then
    echo "JSON validation:"
    if jq empty "$SCRIPT_DIR/plasma6/metadata.json" 2>&1; then
        echo -e "${GREEN}✓ metadata.json is valid${NC}"
    else
        echo -e "${RED}✗ metadata.json has errors${NC}"
        ((ERRORS++))
    fi
    echo ""
else
    echo -e "${YELLOW}⚠${NC} jq not available, skipping JSON validation"
    echo ""
fi

# Summary
echo "================================================================"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Validation passed!${NC}"
    echo "Package is ready for installation."
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    echo "Please fix the issues before installing."
    exit 1
fi
