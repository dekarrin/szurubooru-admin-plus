#!/bin/bash

# Runs the szuru-admin script with the provided arguments through
# docker-compose. Make sure to run this from the root of the szurubooru project
# with a valid docker-compose.yml file setup.

docker-compose run --rm server ./szuru-admin "$@"
