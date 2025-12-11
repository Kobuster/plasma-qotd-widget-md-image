#!/bin/bash

# Build marketplace packages for Plasma 5 and Plasma 6
# Creates distributable .plasmoid files

set -e

PLUGIN_ID="org.kde.prajjwal.quotewidget"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Clean build directory
clean_build() {
    log_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
}

# Build Plasma 5 package
build_plasma5() {
    log_info "Building Plasma 5 package..."
    
    local pkg_dir="$BUILD_DIR/plasma5/$PLUGIN_ID"
    mkdir -p "$pkg_dir/contents"
    
    # Copy shared core files
    cp -r "$SCRIPT_DIR/package/contents/"* "$pkg_dir/contents/"
    
    # Copy Plasma 5 metadata
    cp "$SCRIPT_DIR/plasma5/metadata.desktop" "$pkg_dir/"
    
    # Override with Plasma 5 specific config (main.xml with correct path)
    if [ -f "$SCRIPT_DIR/plasma5/main.xml" ]; then
        cp "$SCRIPT_DIR/plasma5/main.xml" "$pkg_dir/contents/config/"
    fi
    
    # Copy quotes (optional - include sample quotes)
    if [ -d "$SCRIPT_DIR/quotes" ]; then
        cp -r "$SCRIPT_DIR/quotes" "$pkg_dir/"
    fi
    
    # Create .plasmoid archive
    cd "$BUILD_DIR/plasma5"
    zip -r "$BUILD_DIR/${PLUGIN_ID}-plasma5.plasmoid" "$PLUGIN_ID"
    cd "$SCRIPT_DIR"
    
    log_success "Plasma 5 package created: ${PLUGIN_ID}-plasma5.plasmoid"
}

# Build Plasma 6 package
build_plasma6() {
    log_info "Building Plasma 6 package..."
    
    local pkg_dir="$BUILD_DIR/plasma6/$PLUGIN_ID"
    mkdir -p "$pkg_dir/contents"
    
    # Copy shared core files
    cp -r "$SCRIPT_DIR/package/contents/"* "$pkg_dir/contents/"
    
    # Copy Plasma 6 metadata
    cp "$SCRIPT_DIR/plasma6/metadata.json" "$pkg_dir/"
    
    # Override with Plasma 6 specific files
    cp "$SCRIPT_DIR/plasma6/main.qml" "$pkg_dir/contents/ui/"
    cp "$SCRIPT_DIR/plasma6/FullRepresentation.qml" "$pkg_dir/contents/ui/"
    cp "$SCRIPT_DIR/plasma6/config.qml" "$pkg_dir/contents/config/"
    cp "$SCRIPT_DIR/plasma6/configGeneral.qml" "$pkg_dir/contents/ui/"
    
    # Override with Plasma 6 specific config (main.xml with correct path)
    if [ -f "$SCRIPT_DIR/plasma6/main.xml" ]; then
        cp "$SCRIPT_DIR/plasma6/main.xml" "$pkg_dir/contents/config/"
    fi
    
    # Copy quotes (optional - include sample quotes)
    if [ -d "$SCRIPT_DIR/quotes" ]; then
        cp -r "$SCRIPT_DIR/quotes" "$pkg_dir/"
    fi
    
    # Create .plasmoid archive - zip from inside the directory so metadata.json is at root
    cd "$pkg_dir"
    zip -r "$BUILD_DIR/${PLUGIN_ID}-plasma6.plasmoid" .
    cd "$SCRIPT_DIR"
    
    log_success "Plasma 6 package created: ${PLUGIN_ID}-plasma6.plasmoid"
}

# Main
main() {
    echo ""
    log_info "Building Plasma Marketplace Packages"
    echo "========================================"
    echo ""
    
    # Display current version
    if [ -f "$VERSION_FILE" ]; then
        local version=$(cat "$VERSION_FILE")
        log_info "Current version: $version"
        echo ""
    fi
    
    # Check if zip is available
    if ! command -v zip &> /dev/null; then
        echo "ERROR: 'zip' command not found. Please install zip."
        exit 1
    fi
    
    clean_build
    echo ""
    
    build_plasma5
    echo ""
    
    build_plasma6
    echo ""
    
    log_success "Build complete!"
    echo ""
    echo "Output files:"
    echo "  - $BUILD_DIR/${PLUGIN_ID}-plasma5.plasmoid"
    echo "  - $BUILD_DIR/${PLUGIN_ID}-plasma6.plasmoid"
    echo ""
    echo "To install manually:"
    echo "  Plasma 5: kpackagetool5 -i ${PLUGIN_ID}-plasma5.plasmoid"
    echo "  Plasma 6: kpackagetool6 -t Plasma/Applet -i ${PLUGIN_ID}-plasma6.plasmoid"
    echo ""
    echo "To upload to KDE Store (store.kde.org):"
    echo "  1. Create an account at https://store.kde.org"
    echo "  2. Go to 'Add Content' → 'Plasma Widgets'"
    echo "  3. Upload the .plasmoid files for respective versions"
    echo ""
}

main "$@"
