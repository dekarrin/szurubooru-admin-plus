#!/bin/bash

BOORU_DIR="$(dirname "$0")"

files="$1"

if [ $# -lt 1 ]
then
	echo 'error: must give file(s) to fix' >&2
	echo '(you probably want to do ./data/posts/*.jpg and ./data/posts/*.jpeg)' >&2
	exit 1
fi


any_fixed=
id_arg_str=
for f in "$@" ; do
	if [ ! -f "$f" ]
	then
		echo "'$f' does not exist. Skipping" >&2
		continue
	fi
	
	cur="$(exiftran -d "$f" 2>/dev/null | grep 'Orientation' | head -n 1 | awk '{print $3;}')"
	
	#formatting
	cur="$(echo "$cur" | xargs | tr '[:upper:]' '[:lower:]')"
	
	# skip cases that dont need fixing
	[ -n "$cur" ] || continue
	[ "$cur" != 'top-left' ] || continue
	
	f_name="$(basename "$f")"
	id="$(echo "$f_name" | cut -d _ -f 1)"
	id_arg_str="$id_arg_str $id"
	
	echo "Rotating file for post ID $id..."
	exiftran -a -i -p "$f"
	any_fixed=1
done

if [ -z "$any_fixed" ]
then
	echo "No given files need fixing" >&2
	exit 0
fi

echo "Resynching affected posts..."

# deliberately not quoting the below id_arg_str so they are all sent separately
"$BOORU_DIR/szuru-admin.sh" resync $id_arg_str


