#!/bin/bash

################################################################################
# make-dist.sh
################################################################################
# Creates a distribution tarball.
################################################################################

set -euo pipefail

# Read current VERSION from the version file
CURRENT_VERSION=$(grep -E '^VERSION = ' server/szuru_admin_version.py | sed 's/VERSION = "\(.*\)"/\1/')

# Determine if we're in a git repo
IN_GIT_REPO=0
if git rev-parse --git-dir > /dev/null 2>&1; then
    IN_GIT_REPO=1
fi

# Process version argument
if [[ -n "${1:-}" ]]; then
    # Version was provided via $1
    PROVIDED_VERSION="$1"
    # Strip leading 'v' if present
    if [[ "${PROVIDED_VERSION:0:1}" == "v" ]]; then
        PROVIDED_VERSION="${PROVIDED_VERSION:1}"
    fi
    
    # Check if provided version matches the VERSION in the file
    if [[ "$PROVIDED_VERSION" != "$CURRENT_VERSION" ]]; then
        echo "Error: Provided version ($PROVIDED_VERSION) does not match VERSION in szuru_admin_version.py ($CURRENT_VERSION)" >&2
        exit 1
    fi
    
    # Use the provided version (add v prefix for consistency)
    VERSION="v$PROVIDED_VERSION"
    VERSION_FOR_FILE="$CURRENT_VERSION"
else
    # No version provided
    if [[ $IN_GIT_REPO -eq 1 ]]; then
        # In a git repo - append commit SHA
        GIT_COMMIT="$(git rev-parse --short HEAD)"
        VERSION="$CURRENT_VERSION+$GIT_COMMIT"
        VERSION_FOR_FILE="$CURRENT_VERSION+$GIT_COMMIT"
    else
        # Not in a git repo - use current version as-is
        VERSION="$CURRENT_VERSION"
        VERSION_FOR_FILE="$CURRENT_VERSION"
    fi
fi

DIST_DIR="szuru-admin-plus-$VERSION"

mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/admin-dist"

cp server/szuru-admin "$DIST_DIR/admin-dist/szuru-admin"
cp server/szuru_admin_argparse.py "$DIST_DIR/admin-dist/szuru_admin_argparse.py"

# Create modified version file with VERSION_FOR_FILE
cat > "$DIST_DIR/admin-dist/szuru_admin_version.py" << EOF
"""
Version information for szuru-admin.
"""

VERSION = "$VERSION_FOR_FILE"
EOF

cp scripts/fix-exif-rotations.sh "$DIST_DIR/admin-dist/fix-exif-rotations.sh"
cp admin-dist/* "$DIST_DIR/admin-dist/"
cp install.sh README.md LICENSE.md "$DIST_DIR/"

# tar it all up
tar -czf "szuru-admin-plus-$VERSION.tar.gz" "$DIST_DIR"

# clean up
rm -rf "$DIST_DIR"
echo "szuru-admin-plus-$VERSION.tar.gz"
