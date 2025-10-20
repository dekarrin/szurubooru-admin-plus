#!/bin/bash

################################################################################
# make-dist.sh
################################################################################
# Creates a distribution tarball.
################################################################################

set -euo pipefail

# if version was given, use that; otherwise, use the current git commit hash
git_commit="$(git rev-parse --short HEAD)"
VERSION="${1:-.}"
if [[ "$VERSION" == "." ]]; then
    VERSION="$git_commit"
elif [[ "${VERSION:0:1}" != "v" ]]; then
    VERSION="v$VERSION"
fi


DIST_DIR="szuru-admin-plus-$VERSION"

mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/admin-dist"

cp server/szuru-admin "$DIST_DIR/admin-dist/szuru-admin"
cp server/szuru_admin_argparse.py "$DIST_DIR/admin-dist/szuru_admin_argparse.py"
cp scripts/fix-exif-rotations.sh "$DIST_DIR/admin-dist/fix-exif-rotations.sh"
cp admin-dist/* "$DIST_DIR/admin-dist/"
cp install.sh README.md LICENSE.md "$DIST_DIR/"

# Create VERSION file with the version number
echo "$VERSION" > "$DIST_DIR/admin-dist/VERSION"

# tar it all up
tar -czf "szuru-admin-plus-$VERSION.tar.gz" "$DIST_DIR"

# clean up
rm -rf "$DIST_DIR"
echo "szuru-admin-plus-$VERSION.tar.gz"
