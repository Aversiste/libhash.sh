#
# Copyright (c) 2018 Tristan Le Guern <tleguern@bouledef.eu>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

LIBNAME="libhash.sh"
LIBVERSION="1.0"

adler32() {
	local _value="$*"

	local _s1=1
	local _s2=0

	glarray M $(printf "$_value" | sed 's/./& /g')
	local _N="${#M[*]}"

	# Step 0. Preparation
	local _i=0
	for _i in $(enum 0 $_N); do
		local _m=0

		_m=$(ord ${M[_i]})
		_s1=$(( (_s1 + _m) % 65521 ))
		_s2=$(( (_s2 + _s1) % 65521 ))
	done

	# Step 2. Output
	printf "%08x\n" $(( (_s2 << 16) + _s1))

	# Step 3. Cleanup
	unset M
}