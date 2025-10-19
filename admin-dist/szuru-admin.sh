#!/bin/bash

# Runs the szuru-admin script with the provided arguments through
# docker-compose. Make sure to run this from the root of the szurubooru project
# with a valid docker-compose.yml file setup.

# ...but first, see if we can find a python to run
if command -v python3 >/dev/null 2>&1
then
    help_exit_code=134

    SZURU_PREPARSE_HELP_STATUS="help_exit_code" python3 "$(dirname "$0")"/admin/szuru_admin_argparse.py "$@"
    pre_run_status="$?"

    if [ "$pre_run_status" -ne 0 ]
    then
        # if it's the special exit code for printing help, exit with 0 as this
        # is success.
        [ "$pre_run_status" -ne "$help_exit_code" ] || exit 0

        exit "$pre_run_status"
    fi
fi

docker-compose run --rm server ./szuru-admin "$@"
