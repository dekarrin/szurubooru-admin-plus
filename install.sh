#!/bin/bash

##############################################################################
# install.sh
##############################################################################
# This script installs the szuru-admin script and updates the docker-compose.yml
# file to include the necessary volume mount for the szuru-admin script.
##############################################################################

set -euo pipefail

function checksum() {
    # Calculate the checksum of a file using md5sum or md5
    local file="$1"
    if command -v md5sum &> /dev/null; then
        md5sum "$file" | awk '{ print $1 }'
    elif command -v md5 &> /dev/null; then
        md5 "$file" -q
    else
        echo "Error: no md5sum or md5 command present on system" >&2
        exit 1
    fi
}

# Check for md5sum utility
if ! command -v md5sum &> /dev/null; then
    # okay we might be able to get by with just md5 if on darwin
    if ! command -v md5 &> /dev/null; then
        echo "Error: no md5sum or md5 command present on system" >&2
        echo "Please install one and try again." >&2
    fi
fi

# Install dir is first argument, else current directory is assumed:
INSTALL_DIR="${1:-.}"

# Get location where script is run from because unless moved, all its files are
# also present there.
SCRIPT_DIR="$(dirname "$0")"

# Check that we have been given a valid directory by searching for a
# docker-compose.yml file in the specified directory.
if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
    echo "Error: No docker-compose.yml found in $INSTALL_DIR." >&2
    echo "Execute this script from the szurubooru directory with docker-compose.yml in it" >&2
    echo "or give directory containing yml file as the first argument." >&2
    exit 1
fi

# Update docker-compose if needed.
if grep ':/opt/app/szuru-admin' "$INSTALL_DIR/docker-compose.yml" > /dev/null 2>&1
then
    echo "docker-compose.yml already has a volume mount for szuru-admin; not modifying." >&2
else
    old_compose="docker-compose.yml.bak-$(date +%Y%m%d%H%M%S)"
    cp "$INSTALL_DIR/docker-compose.yml" "$INSTALL_DIR/$old_compose"
    echo "Backed up existing docker-compose.yml to $old_compose" >&2

    cp "$SCRIPT_DIR/admin-dist/docker-compose.admin-plus.yml" "$INSTALL_DIR/docker-compose.yml"
    echo "Installed new docker-compose.yml to substitute custom szuru-admin script" >&2
fi

# Create dirs if needed
if [ -d "$INSTALL_DIR/admin" ]
then
    echo "Directory $INSTALL_DIR/admin already exists; not creating." >&2
else
    mkdir -p "$INSTALL_DIR/admin"
    echo "Created directory $INSTALL_DIR/admin" >&2
fi

# Copy convenience script to the szurubooru directory if needed
if [ -f "$INSTALL_DIR/szuru-admin.sh" ]
then
    echo "./szuru-admin.sh already present; not replacing" >&2
else
    cp "$SCRIPT_DIR/admin-dist/szuru-admin.sh" "$INSTALL_DIR/szuru-admin.sh"
    echo "Copied szuru-admin.sh to $INSTALL_DIR" >&2
fi

# Copy szuru-admin script to the admin directory

# Where from? If running directly from the git repo, the script is located in
# server/szuru-admin. If running from a distribution package, it is in
# admin-dist/szuru-admin. Detect which one is present.
NEW_SZURU_ADMIN_FILE=
if [ -f "$SCRIPT_DIR/admin-dist/szuru-admin" ]
then
    NEW_SZURU_ADMIN_FILE="$SCRIPT_DIR/admin-dist/szuru-admin"
else
    NEW_SZURU_ADMIN_FILE="$SCRIPT_DIR/server/szuru-admin"
fi

script_copy_needed=
if [ -f "$INSTALL_DIR/admin/szuru-admin" ]
then
    # first check if the file is even different at all
    existing_sum="$(checksum "$INSTALL_DIR/admin/szuru-admin")"
    new_sum="$(checksum "$NEW_SZURU_ADMIN_FILE")"
    if [ "$existing_sum" = "$new_sum" ]
    then
        echo "Existing server/szuru-admin script already has updated contents." >&2
    else    
        # use datetime checks to see if the file we have is newer
        existing_mtime="$(date -r "$INSTALL_DIR/admin/szuru-admin" '+%s')"
        new_mtime="$(date -r "$NEW_SZURU_ADMIN_FILE" '+%s')"
        if [ "$existing_mtime" -lt "$new_mtime" ]
        then
            echo "Replacing old server/szuru-admin script with newer version..." >&2
            script_copy_needed=1
        else
            echo "Existing server/szuru-admin script is newer; not copying." >&2
        fi
    fi
else
    script_copy_needed=1
fi

if [ -n "$script_copy_needed" ]
then
    cp "$NEW_SZURU_ADMIN_FILE" "$INSTALL_DIR/admin/szuru-admin"
    echo "Copied server/szuru-admin script to $INSTALL_DIR/admin/szuru-admin" >&2
else
    echo "No need to copy server/szuru-admin script; it is already up-to-date." >&2
fi
