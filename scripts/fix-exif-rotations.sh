#!/bin/bash

BOORU_DIR="$(dirname "$0")"

function fix_file() {
	f="$1"
	
	if [ ! -f "$f" ]
	then
		echo "'$f' does not exist. Skipping" >&2
		return 1
	fi
	
	cur="$(exiftran -d "$f" 2>/dev/null | grep 'Orientation' | head -n 1 | awk '{print $3;}')"
	
	#formatting
	cur="$(echo "$cur" | xargs | tr '[:upper:]' '[:lower:]')"
	
	# skip cases that don't need fixing
	[ -n "$cur" ] || return 1
	[ "$cur" != 'top-left' ] || return 1

	id="$(echo "$(basename "$f")" | cut -d _ -f 1)"
	
	echo "Rotating file for post ID $id..."
	exiftran -a -i -p "$f"
	return 0
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

input_mode="$input_mode_files"

for f in "$@" ; do
	if [ "$f" = "--id-range" ]
	then
		input_mode="$input_mode_id_range"
	fi
done


any_fixed=
id_arg_str=

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
		check=$(( $oldest + 1 ))
		while true
		do
			# TODO: update this to nullglob / compgen -G check in future;
			# this is fine for now since by the nature of szurubooru, this glob
			# wont produce additional files.
			f="$posts_path/$check"*
			if [ "$f" = "$posts_path/$check*" ]
			then
				newest=$(( $check - 1 ))
				break
			fi
			((check++))
		done
		echo "Got $newest"
	fi

	for pid in $(eval "echo {$oldest..$newest}")
	do
		# TODO: update this to nullglob / compgen -G check in future;
		# this is fine for now since by the nature of szurubooru, this glob
		# wont produce additional files.
		f="$posts_path/$pid"*
		if [ "$f" = "$posts_path/$pid*" ]
		then
			continue
		fi

		if fix_file "$f"
		then
			id_arg_str="$id_arg_str $pid"
			any_fixed=1
		fi
	done
else
	for f in "$@" ; do
		if fix_file "$f"
		then
			id="$(basename "$f" | cut -d _ -f 1)"
			id_arg_str="$id_arg_str $id"
			any_fixed=1
		fi
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


