#!/bin/bash

################################################################################
# make-dist.sh
################################################################################
# Creates a distribution tarball.
################################################################################

set -euo pipefail

# if version was given, use that; otherwise, use the current git commit hash
if [ -n "$1" ]; then
    VERSION="$1"
else
    echo "Version not specified; using current git commit hash" >&2
    VERSION="$(git rev-parse --short HEAD)"
fi

DIST_DIR="szuru-admin-plus-v$VERSION"

mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/admin-dist"

cp server/szuru-admin "$DIST_DIR/admin-dist/szuru-admin"
cp admin-dist/* "$DIST_DIR/admin-dist/"
cp install.sh README.md LICENSE.md "$DIST_DIR/"

# tar it all up
tar -czf "szuru-admin-plus-$VERSION.tar.gz" "$DIST_DIR"

# clean up
rm -rf "$DIST_DIR"
echo "szuru-admin-plus-$VERSION.tar.gz"
