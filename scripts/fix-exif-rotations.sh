#!/bin/bash

# fix-exif-rotations.sh: fixes exif rotations of posts. Use with -h for more
# info.
#
# WARNING: DO NOT RUN THIS FROM THE REPO, it must be ./install.sh'd to the
# target booru dir before executed.


# Check for exiftran dependency
command -v exiftran >/dev/null 2>&1 || { echo 'error: exiftran is required but not installed' >&2; exit 1; }
BOORU_DIR="$(dirname "$0")"

function fix_file() {
	local f="$1"
	
	if [ ! -f "$f" ]
	then
		echo "'$f' does not exist. Skipping" >&2
		return 1
	fi
	
	local cur="$(exiftran -d "$f" 2>/dev/null | grep 'Orientation' | head -n 1 | awk '{print $3;}')"
	
	#formatting
	cur="$(echo "$cur" | xargs | tr '[:upper:]' '[:lower:]')"
	
	# skip cases that don't need fixing
	[ -n "$cur" ] || return 1
	[ "$cur" != 'top-left' ] || return 1

	local id="$(echo "$(basename "$f")" | cut -d _ -f 1)"
	
	echo "Rotating file for post ID $id..."
	exiftran -a -i -p "$f"
	local rc=$?
	return $rc
}

if [ $# -lt 1 ]
then
	echo 'error: must give file(s) to fix' >&2
	echo '(you probably want to do ./data/posts/*.jpg and ./data/posts/*.jpeg)' >&2
	exit 1
fi


# scan for different input modes
input_mode_files=1
input_mode_id_range=2
input_mode_days_old=3

input_mode="$input_mode_files"

for f in "$@" ; do
	if [ "$f" = "--id-range" ]
	then
		input_mode="$input_mode_id_range"
	elif [ "$f" = "--age" ]
	then
		input_mode="$input_mode_days_old"
	elif [ "$f" = "-h" -o "$f" = "--help" ]
	then
		echo "fix-exif-rotations.sh: Scans files for rotation with exiftran and fixes them."
		echo ""
		echo "usage: $0 file1 [file2 [...fileN]]"
		echo "   OR  $0 --id-range OLDEST [NEWEST]"
		echo "   OR  $0 --age [DAYS-OLD]"
		echo ""
		echo "Each file matched is checked for rotation and if EXIF tags specify it has"
		echo "rotation, it is rotated to be correct and the EXIF tag updated. Then, the"
		echo "affected posts are resynced in Szurubooru."
		echo ""
		echo "By default, the provided args are a list of files to be checked. This can be"
		echo 'simplified by providing a glob such as ./data/posts/*.jpg.' 
		echo ""
		echo "If --id-range is provided as an option, the parameters are read as the numeric"
		echo "post ID(s) of the OLDEST post (and optionally the NEWEST as well). All posts"
		echo "between OLDEST and NEWEST (inclusive) are scanned for rotation and resynced if"
		echo "needed. If NEWEST is not given, it defaults to the highest possible post number"
		echo "which exists."
		echo ""
		echo "If --age is provided as an option, the parameter (if any) is read as a numeric"
		echo "number of days old for which posts should be checked for. It can be omitted,"
		echo "in which case posts with files that are 1 day old or less will be checked."
		exit 0
	fi
done


any_fixed=
id_arg_str=

function fix_and_append() {
	if fix_file "$1"
	then
		local id="$(basename "$1" | cut -d _ -f 1)"
		id_arg_str="$id_arg_str $id"
		any_fixed=1
	fi
}

if [ "$input_mode" -eq "$input_mode_id_range" ]
then
	if [ "$#" -ne 3 -a "$#" -ne 2 ]
	then
		echo 'error: --id-range input mode requires exactly one or two args' >&2
		echo "usage: $0 --id-range OLDEST [NEWEST]" >&2
		exit 1
	fi

	oldest=
	newest=

	set_oldest=
	digit_re='^[0-9]+$'
	for arg in "$@"; do
		[ "$arg" != "--id-range" ] || continue
		if [ -z "$set_oldest" ]
		then
			if ! [[ "$arg" =~ $digit_re ]]
			then
				echo "error: not a number: $arg" >&2
				exit 2
			fi
			oldest="$arg"
			set_oldest=1
		else
			if ! [[ "$arg" =~ $digit_re ]]
			then
				echo "error: not a number: $arg" >&2
				exit 2
			fi
			newest="$arg"
		fi
	done

	posts_path="$BOORU_DIR/data/posts"
	if [ -z "$newest" ]
	then
		# auto-detect highest post number
		echo "Checking for highest post number..."
		shopt -s nullglob
		max_id="$oldest"
		for file in "$posts_path"/*; do
			base="$(basename "$file")"
			id="${base%%_*}"
			if [[ "$id" =~ ^[0-9]+$ ]]; then
				if (( id > max_id )); then
					max_id="$id"
				fi
			fi
		done
		newest="$max_id"
		shopt -u nullglob
		echo "Got $newest"
	fi

	if [ "$newest" -lt "$oldest" ]
	then
		temp="$newest"
		newest="$oldest"
		oldest="$temp"
	fi

	echo "Checking posts with IDs between $oldest and $newest..."

	for ((pid=oldest; pid<=newest; pid++))
	do
		# Use nullglob and arrays for robust glob matching
		shopt -s nullglob
		matches=("$posts_path/${pid}_"*)
		shopt -u nullglob
		if [ ${#matches[@]} -eq 0 ]; then
			continue
		fi
		for f in "${matches[@]}"; do
			fix_and_append "$f"
		done
	done
elif [ "$input_mode" -eq "$input_mode_days_old" ]
then
	if [ "$#" -ne 2 -a "$#" -ne 1 ]
	then
		echo 'error: --age input mode takes one or zero args' >&2
		echo "usage: $0 --age [DAYS-OLD]" >&2
		exit 1
	fi

	days=

	digit_re='^[0-9]+$'
	for arg in "$@"; do
		[ "$arg" != "--age" ] || continue
		if ! [[ "$arg" =~ $digit_re ]]
		then
			echo "error: not a number: $arg" >&2
			exit 2
		fi
		days="$arg"
	done

	[ -n "$days" ] || days=1

	echo "Checking posts $days or more days old..."

	posts_path="$BOORU_DIR/data/posts"

	# TODO: files probably dont have spaces in them but if they do this will
	# need to be updated to account for that.
	for f in $(find "$posts_path/." -type f -mtime -$days)
	do
		fix_and_append "$f"
	done
else
	for f in "$@" ; do
		fix_and_append "$f"
	done
fi

if [ -z "$any_fixed" ]
then
	echo "No given files need fixing" >&2
	exit 0
fi

echo "Resynching affected posts..."

# deliberately not quoting the below id_arg_str so they are all sent separately
"$BOORU_DIR/szuru-admin.sh" resync $id_arg_str


