#!/bin/bash

# Runs the szuru-admin script with the provided arguments through
# docker-compose. Make sure to run this from the root of the szurubooru project
# with a valid docker-compose.yml file setup.

# ...but first, see if we can find a python to run
if command -v python3
then
    echo "running"
    if ! python3 "$(dirname "$0")"/admin/szuru_admin_argparse.py "$@"
    then
        # if it's the special exit code for printing help, actually dont
        [ "$?" -ne 3434 ] || exit 0

        exit "$?"
    fi
    echo "$?"
fi

docker-compose run --rm server ./szuru-admin "$@"
