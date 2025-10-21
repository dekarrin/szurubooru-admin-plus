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
update_docker_compose=1
if grep ':/opt/app/szuru-admin' "$INSTALL_DIR/docker-compose.yml" > /dev/null 2>&1
then
    if grep ':/opt/app/szuru_admin_argparse.py' "$INSTALL_DIR/docker-compose.yml" > /dev/null 2>&1
    then
        echo "docker-compose.yml already has volume mounts for szuru-admin files; not modifying." >&2
        update_docker_compose=
    fi
fi
if [ -n "$update_docker_compose" ]
then
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

# Copy szuru_admin_argparse.py python script to the admin directory

function copy_new_or_updated() {
    source_dist_rel_path="$1"
    source_repo_rel_path="$2"
    dest_install_rel_path="$3"

    # Where from? If running directly from the git repo, the module is located in
    # server/szuru_admin_argparse.py. If running from a distribution package, it is
    # in admin-dist/szuru_admin_argparse.py. Detect which one is present.
    local source=
    if [ -f "$SCRIPT_DIR/$source_dist_rel_path" ]
    then
        source="$SCRIPT_DIR/$source_dist_rel_path"
    else
        source="$SCRIPT_DIR/$source_repo_rel_path"
    fi
    local dest="$INSTALL_DIR/$dest_install_rel_path"

    local source_file_name="$(basename "$source")"

    local file_copy_needed=
    if [ -f "$dest" ]
    then
        # first check if the file is even different at all
        existing_sum="$(checksum "$dest")"
        new_sum="$(checksum "$source")"
        if [ "$existing_sum" = "$new_sum" ]
        then
            echo "Existing $source_file_name script already has updated contents." >&2
        else    
            # use datetime checks to see if the file we have is newer
            local existing_mtime="$(date -r "$dest" '+%s')"
            local new_mtime="$(date -r "$source" '+%s')"
            if [ "$existing_mtime" -lt "$new_mtime" ]
            then
                echo "Replacing old $source_file_name script with newer version..." >&2
                file_copy_needed=1
            else
                echo "Existing $source_file_name script is newer; not copying." >&2
            fi
        fi
    else
        file_copy_needed=1
    fi

    if [ -n "$file_copy_needed" ]
    then
        cp "$source" "$dest"
        echo "Copied $source_file_name to $dest" >&2
    else
        echo "No need to copy $source_file_name; it is already up-to-date." >&2
    fi
}

# Copy root-level admin scripts to the install directory
copy_new_or_updated "admin-dist/szuru-admin.sh" "admin-dist/szuru-admin.sh" "szuru-admin.sh"
copy_new_or_updated "admin-dist/fix-exif-rotations.sh" "scripts/fix-exif-rotations.sh" "fix-exif-rotations.sh"
# Copy admin scripts to the admin directory
copy_new_or_updated "admin-dist/szuru-admin" "server/szuru-admin" "admin/szuru-admin"
copy_new_or_updated "admin-dist/szuru_admin_argparse.py" "server/szuru_admin_argparse.py" "admin/szuru_admin_argparse.py"

# For version file, if installing from repo, create a temporary version with commit hash
if [ -f "$SCRIPT_DIR/server/szuru_admin_version.py" ] && [ -d "$SCRIPT_DIR/.git" ]
then
    # Get the git commit hash
    git_commit="$(cd "$SCRIPT_DIR" && git rev-parse --short HEAD 2>/dev/null || echo '')"
    if [ -n "$git_commit" ]
    then
        # Create a temporary version file with the commit hash appended
        temp_version_file="$SCRIPT_DIR/.szuru_admin_version_temp_$$.py"
        cp "$SCRIPT_DIR/server/szuru_admin_version.py" "$temp_version_file"
        
        # Replace any existing commit hash or append if none exists
        sed -i.bak -E 's/^(VERSION = "[^"+]+)(\+[0-9a-zA-Z]+)?"$/\1+'"$git_commit"'"/' "$temp_version_file"
        rm -f "$temp_version_file.bak"
        
        # Use the temp file as the source for copying (pass same path twice since it's absolute)
        temp_rel_path=".szuru_admin_version_temp_$$.py"
        copy_new_or_updated "$temp_rel_path" "$temp_rel_path" "admin/szuru_admin_version.py"
        
        # Clean up the temporary file
        rm -f "$temp_version_file"
    else
        # No git commit available, copy normally
        copy_new_or_updated "admin-dist/szuru_admin_version.py" "server/szuru_admin_version.py" "admin/szuru_admin_version.py"
    fi
else
    # Not installing from repo, copy normally
    copy_new_or_updated "admin-dist/szuru_admin_version.py" "server/szuru_admin_version.py" "admin/szuru_admin_version.py"
fi
