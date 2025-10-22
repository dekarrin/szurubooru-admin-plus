#!/bin/bash

################################################################################
# make-dist.sh
################################################################################
# Creates a distribution tarball.
################################################################################

set -euo pipefail

# Read current VERSION from the version file
file_version=$(grep -E '^VERSION = ' server/szuru_admin_version.py | sed 's/VERSION = "\(.*\)"/\1/')

# Determine if we're in a git repo
in_git_repo=0
if git rev-parse --git-dir > /dev/null 2>&1; then
    in_git_repo=1
fi

# Process version argument
if [[ $# -gt 0 ]]; then
    # Version was provided via $1
    version="$1"
    # Strip leading 'v' if present
    if [[ "${version:0:1}" == "v" ]]; then
        version="${version:1}"
    fi
    
    # Check if provided version matches the VERSION in the file
    if [[ "$version" != "$file_version" ]]; then
        echo "Error: Provided version ($version) does not match VERSION in szuru_admin_version.py ($file_version)" >&2
        exit 1
    fi
    
    # Use the provided version (add v prefix for consistency)
    VERSION="v$version"
    VERSION_FOR_FILE="$file_version"
else
    # No version provided
    if [[ $in_git_repo -eq 1 ]]; then
        # In a git repo - append commit SHA
        git_commit="$(git rev-parse --short HEAD)"
        VERSION="$file_version+$git_commit"
        VERSION_FOR_FILE="$file_version+$git_commit"
    else
        # Not in a git repo - use current version as-is
        VERSION="$file_version"
        VERSION_FOR_FILE="$file_version"
    fi
fi

DIST_DIR="szuru-admin-plus-$VERSION"

mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/admin-dist"

cp server/szuru-admin "$DIST_DIR/admin-dist/szuru-admin"
cp server/szuru_admin_argparse.py "$DIST_DIR/admin-dist/szuru_admin_argparse.py"
cp server/szuru_admin_version.py "$DIST_DIR/admin-dist/szuru_admin_version.py"

# Edit the version in the dest file
sed -i "s/^VERSION = .*/VERSION = \"$VERSION_FOR_FILE\"/" "$DIST_DIR/admin-dist/szuru_admin_version.py"

cp scripts/fix-exif-rotations.sh "$DIST_DIR/admin-dist/fix-exif-rotations.sh"
cp admin-dist/* "$DIST_DIR/admin-dist/"
cp install.sh README.md LICENSE.md "$DIST_DIR/"

# tar it all up
tar -czf "szuru-admin-plus-$VERSION.tar.gz" "$DIST_DIR"

# clean up
rm -rf "$DIST_DIR"
echo "szuru-admin-plus-$VERSION.tar.gz"
