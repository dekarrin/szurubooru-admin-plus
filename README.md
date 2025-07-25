szurubooru-admin-plus
=====================

Enhances the szurubooru admin tool with additional functionality.

* Rename tags by regular expression patterns
* Move tags matching regex to new category

## Requirements

This script is intended exclusively for use with Szurubooru v2.5. It has not
been tested with any version outside of that. Additionally, szurubooru must be
set up and running using docker-compose.

Note: The installer script will assume you are running version 2.5 with no
further checks and using the default directory set up implied by the volume
mounts in the docker-compose.yml included with Szurubooru v2.5. If the install
script is run against a different version or a deploy with a different volume
setup, **it will force that version to 2.5, possibly causing data loss.**

## Installation

To install, run the included `install.sh` script from within the directory
containing the docker-compose.yml file for Szurubooru. Alternatively, you can
run the script from any location and pass in the path to that directory.

## Updating

Updating follows the same process; run `install.sh`. The script is smart enough
to only make changes necessary to update.

## Attribution and Licensing

This project is derived from the source code of szurubooru v2.5, which is
licensed under the terms of the GNU GPL v3.0. As such, this project is itself
released under the terms of the GNU GPL v3.0. Please see LICENSE.md for the full
text of this license.