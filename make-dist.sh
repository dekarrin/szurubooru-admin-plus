#!/bin/bash

################################################################################
# make-dist.sh
################################################################################
# Creates a distribution tarball.
################################################################################

set -euo pipefail

# make sure we are in the correct working dir
cd "$(dirname "$0")"

# Read current VERSION from the version file
file_version=$(grep -E '^VERSION = ' server/szuru_admin_version.py | sed 's/VERSION = "\(.*\)"/\1/')
tarball_version="$file_version"  # used for filename in tarball and dir
version="$file_version"          # what calling 'version' in distributed script should return.

# Determine if we're in a git repo
in_git_repo=1
git rev-parse --git-dir > /dev/null 2>&1 || in_git_repo=

# Process version argument
if [[ $# -gt 0 ]]
then
    # Version was provided via $1
    version="$1"
    # Strip leading 'v' if present
    if [[ "${version:0:1}" == "v" ]]; then
        version="${version:1}"
    fi
    
    # Check if provided version matches the VERSION in the file
    if [[ "$version" != "$file_version" ]]
    then
        echo "Error: Provided version ($version) does not match VERSION in szuru_admin_version.py ($file_version)" >&2
        echo "" >&2
        echo "Refusing to create version distribution for mismatched version;" >&2
        echo "Update version in szuru_admin_version.py to match $version and try again" >&2
        exit 1
    fi
else
    # No version provided; if in a git repo, append commit hash
    if [[ -n "$in_git_repo" ]]
    then
        # In a git repo - append commit SHA
        commit_hash="$(git rev-parse --short HEAD)"
        version="$file_version+$commit_hash"
        tarball_version="$file_version-$commit_hash"
    fi
fi

DIST_DIR="szuru-admin-plus-v$tarball_version"

mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/admin-dist"

cp server/szuru-admin "$DIST_DIR/admin-dist/szuru-admin"
cp server/szuru_admin_argparse.py "$DIST_DIR/admin-dist/szuru_admin_argparse.py"
cp server/szuru_admin_version.py "$DIST_DIR/admin-dist/szuru_admin_version.py"
cp scripts/fix-exif-rotations.sh "$DIST_DIR/admin-dist/fix-exif-rotations.sh"
cp admin-dist/* "$DIST_DIR/admin-dist/"
cp install.sh README.md LICENSE.md "$DIST_DIR/"

# Set version in the distributed program, if it doesnt match current
if [ "$version" -ne "$file_version" ]
then
    sed -i "s/^VERSION = .*/VERSION = \"$version\"/" "$DIST_DIR/admin-dist/szuru_admin_version.py"
fi

# tar it all up
tar -czf "szuru-admin-plus-$tarball_version.tar.gz" "$DIST_DIR"

# clean up
rm -rf "$DIST_DIR"
echo "szuru-admin-plus-$tarball_version.tar.gz"
