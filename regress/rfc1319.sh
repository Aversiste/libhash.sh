#!/bin/sh
# Tristan Le Guern <tleguern@bouledef.eu>
# This file is placed in the public domain.

set -u

. ../md2.sh

FAILED=0

t() {
	# $1 -> shell function to call
	# $2 -> $test expression
	# $3 -> expected exit code
	# $4 -> expected result

	echo "Run $1 \"$2\", expect $4 and exit code $3"
	tmp="$(mktemp -t encode.sh.XXXXXXXX)"
	"$1" "$2" > "$tmp" 2> /dev/null
	ret="$?"
	if [ $ret -ne $3 ]; then
		echo "Wrong exit code for $1 \"$2\" ($ret)"
		FAILED=$((FAILED + 1))
		rm -f "$tmp"
		return
	fi
	if [ "$(cat $tmp)" != "$4" ]; then
		echo "Wrong result for $1 \"$2\" $(cat $tmp)"
		FAILED=$((FAILED + 1))
		rm -f "$tmp"
		return
	fi
	rm -f "$tmp"
	echo OK
}

#t md2 "" 0 "8350e5a3e24c153df2275c9f80692773"
t md2 "a" 0 "32ec01ec4a6dac72c0ab96fb34c0b5d1"
t md2 "abc" 0 "da853b0d3f88d99b30283a69e6ded6bb"
t md2 "message digest" 0 "ab4f496bfb2a530b219ff33031fe06b0"
t md2 "abcdefghijklmnopqrstuvwxyz" 0 "4e8ddff3650292ab5a4108c3aa47940b"
t md2 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" 0 "da33def2a42df13975352846c30338cd"
t md2 "12345678901234567890123456789012345678901234567890123456789012345678901234567890" 0 "d5976f79d83d3a0dc9806c3c66f3efd8"

if [ "$FAILED" -ne 0 ]; then
	echo "Error: $FAILED errors found."
	exit 1
fi

