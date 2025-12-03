#!/bin/bash

# Quote of the Day Plasmoid Installation Script
# Supports both Plasma 5 and Plasma 6

set -e

PLUGIN_ID="org.kde.prajjwal.quotewidget"
INSTALL_DIR="$HOME/.local/share/plasma/plasmoids/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Detect Plasma version
detect_plasma_version() {
    if ! command -v plasmashell &> /dev/null; then
        log_error "plasmashell not found. Please ensure KDE Plasma is installed."
        exit 1
    fi
    
    local version=$(plasmashell --version | grep -oP 'plasmashell \K[0-9]+' | head -n1)
    
    if [[ "$version" == "5" ]]; then
        echo "5"
    elif [[ "$version" == "6" ]]; then
        echo "6"
    else
        log_error "Unsupported Plasma version: $version"
        exit 1
    fi
}

# Clean existing installation
clean_installation() {
    log_info "Cleaning existing installation..."
    
    # Remove from plasmoid directory
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log_success "Removed existing installation directory"
    fi
    
    # Try to uninstall via kpackagetool (Plasma 5)
    if command -v kpackagetool5 &> /dev/null; then
        kpackagetool5 -t Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null || true
    fi
    
    # Try to uninstall via kpackagetool6 (Plasma 6)
    if command -v kpackagetool6 &> /dev/null; then
        kpackagetool6 -t Plasma/Applet -r "$PLUGIN_ID" 2>/dev/null || true
    fi
}

# Install the plasmoid
install_plasmoid() {
    local plasma_version=$1
    
    log_info "Installing for Plasma $plasma_version..."
    
    # Create install directory structure
    mkdir -p "$INSTALL_DIR/contents"
    
    # Copy shared core files
    log_info "Copying shared core files..."
    cp -r "$SCRIPT_DIR/package/contents/"* "$INSTALL_DIR/contents/"
    
    # Copy quotes files if they exist
    if [ -d "$SCRIPT_DIR/quotes" ]; then
        log_info "Copying quotes files..."
        cp -r "$SCRIPT_DIR/quotes" "$INSTALL_DIR/"
    fi
    
    # Copy platform-specific files
    log_info "Copying Plasma $plasma_version adapter files..."
    if [ "$plasma_version" == "5" ]; then
        cp "$SCRIPT_DIR/plasma5/metadata.desktop" "$INSTALL_DIR/"
        # Override with Plasma 5 specific config (main.xml with correct path)
        if [ -f "$SCRIPT_DIR/plasma5/main.xml" ]; then
            cp "$SCRIPT_DIR/plasma5/main.xml" "$INSTALL_DIR/contents/config/"
        fi
    else
        cp "$SCRIPT_DIR/plasma6/metadata.json" "$INSTALL_DIR/"
        cp "$SCRIPT_DIR/plasma6/main.qml" "$INSTALL_DIR/contents/ui/"
        cp "$SCRIPT_DIR/plasma6/FullRepresentation.qml" "$INSTALL_DIR/contents/ui/"
        cp "$SCRIPT_DIR/plasma6/config.qml" "$INSTALL_DIR/contents/config/"
        cp "$SCRIPT_DIR/plasma6/configGeneral.qml" "$INSTALL_DIR/contents/ui/"
        # Override with Plasma 6 specific config (main.xml with correct path)
        if [ -f "$SCRIPT_DIR/plasma6/main.xml" ]; then
            cp "$SCRIPT_DIR/plasma6/main.xml" "$INSTALL_DIR/contents/config/"
        fi
    fi
    
    log_success "Files copied to $INSTALL_DIR"
}

# Restart plasmashell
restart_plasmashell() {
    log_info "Restarting plasmashell to apply changes..."
    
    if pgrep -x "plasmashell" > /dev/null; then
        killall plasmashell 2>/dev/null || true
        sleep 2
        kstart5 plasmashell 2>/dev/null || kstart plasmashell 2>/dev/null || plasmashell &
        log_success "Plasmashell restarted"
    else
        log_warning "Plasmashell not running. Start it manually or log out and log back in."
    fi
}

# Create sample quotes directory
create_sample_quotes() {
    local quotes_dir="$HOME/Documents/Quotes"
    
    if [ ! -d "$quotes_dir" ]; then
        log_info "Creating sample quotes directory..."
        mkdir -p "$quotes_dir"
        cp -r "$SCRIPT_DIR/quotes/"*.txt "$quotes_dir"

        log_success "Created sample quotes in $quotes_dir"
    fi
}

# Main installation flow
main() {
    echo ""
    log_info "Quote of the Day Plasmoid Installer"
    echo "========================================"
    echo ""
    
    # Detect Plasma version
    PLASMA_VERSION=$(detect_plasma_version)
    log_success "Detected Plasma $PLASMA_VERSION"
    echo ""
    
    # Clean existing installation
    clean_installation
    echo ""
    
    # Install
    install_plasmoid "$PLASMA_VERSION"
    echo ""
    
    # Create sample quotes
    create_sample_quotes
    echo ""
    
    # Restart plasmashell
    read -p "Do you want to restart plasmashell now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_plasmashell
    else
        log_warning "Please restart plasmashell manually or log out/in for changes to take effect."
    fi
    
    echo ""
    log_success "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Right-click on your desktop or panel"
    echo "  2. Select 'Add Widgets...'"
    echo "  3. Search for 'Quote of the Day'"
    echo "  4. Drag it to your desktop or panel"
    echo ""
    echo "To configure:"
    echo "  - Right-click the widget → Configure..."
    echo "  - Set your quotes folder (default: ~/Documents/Quotes)"
    echo "  - Adjust rotation interval, colors, and font"
    echo ""
}

main "$@"
