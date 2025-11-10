#!/bin/bash

# Version Management Script
# Updates version consistently across Plasma 5 and Plasma 6 metadata files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/VERSION"
PLASMA5_METADATA="$SCRIPT_DIR/plasma5/metadata.desktop"
PLASMA6_METADATA="$SCRIPT_DIR/plasma6/metadata.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Show current version
show_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        local current=$(cat "$VERSION_FILE")
        echo "Current version: $current"
    else
        echo "No VERSION file found"
    fi
}

# Update VERSION file
update_version_file() {
    local new_version="$1"
    echo "$new_version" > "$VERSION_FILE"
    log_success "Updated VERSION file to $new_version"
}

# Update Plasma 5 metadata.desktop
update_plasma5_metadata() {
    local new_version="$1"
    
    if [ ! -f "$PLASMA5_METADATA" ]; then
        log_warning "Plasma 5 metadata file not found: $PLASMA5_METADATA"
        return
    fi
    
    # Update the version line in the desktop file
    sed -i "s/^X-KDE-PluginInfo-Version=.*/X-KDE-PluginInfo-Version=$new_version/" "$PLASMA5_METADATA"
    log_success "Updated Plasma 5 metadata to version $new_version"
}

# Update Plasma 6 metadata.json
update_plasma6_metadata() {
    local new_version="$1"
    
    if [ ! -f "$PLASMA6_METADATA" ]; then
        log_warning "Plasma 6 metadata file not found: $PLASMA6_METADATA"
        return
    fi
    
    # Update the version in the JSON file
    sed -i "s/\"Version\": \"[^\"]*\"/\"Version\": \"$new_version\"/" "$PLASMA6_METADATA"
    log_success "Updated Plasma 6 metadata to version $new_version"
}

# Validate version format (basic semantic versioning check)
validate_version() {
    local version="$1"
    
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
        echo "ERROR: Invalid version format '$version'"
        echo "Expected format: MAJOR.MINOR or MAJOR.MINOR.PATCH (e.g., 3.0, 3.1.2)"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    echo ""
    log_info "Version Management Tool"
    echo "========================"
    echo ""
    
    # Show current version
    show_current_version
    echo ""
    
    # Check if version argument provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <version>"
        echo ""
        echo "Examples:"
        echo "  $0 3.1        # Set version to 3.1"
        echo "  $0 3.1.2      # Set version to 3.1.2"
        echo ""
        exit 1
    fi
    
    local new_version="$1"
    
    # Validate version format
    if ! validate_version "$new_version"; then
        exit 1
    fi
    
    # Confirm action
    echo "This will update the version to: $new_version"
    echo "Files to be updated:"
    echo "  - $VERSION_FILE"
    echo "  - $PLASMA5_METADATA"
    echo "  - $PLASMA6_METADATA"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    
    echo ""
    log_info "Updating version to $new_version..."
    echo ""
    
    # Update all files
    update_version_file "$new_version"
    update_plasma5_metadata "$new_version"
    update_plasma6_metadata "$new_version"
    
    echo ""
    log_success "Version update complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Commit changes: git commit -am 'Bump version to $new_version'"
    echo "  3. Tag release: git tag v$new_version"
    echo "  4. Build packages: ./build-packages.sh"
    echo ""
}

main "$@"
