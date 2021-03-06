#
# Copyright (c) 2015 Tristan Le Guern <tleguern@bouledef.eu>
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

#
# ord() converts the given ASCII char to a decimal value
#
ord() {
	printf "%d" "'$1"
}

#
# enum is a portable glue for enumerating between two numbers $_first and $_last
#
if command -v jot > /dev/null 2>&1; then
	enum() { jot $2 $1 $2 1; }
elif command -v seq > /dev/null 2>&1; then
	enum() { seq $1 1 $(( $2 - 1 )); }
fi

#
# glarray() creates an array in the global scope, in a "portable" maner
#
glarray() {
	_glarrayksh() {
		set -A $_glarray_name -- $@
	}

	_glarraybash() {
		declare -ga $_glarray_name
		_glarray_i=0
		_glarray_j=0
		for _glarray_i; do
			declare -ga "$_glarray_name[$_glarray_j]=$_glarray_i"
			_glarray_j=$(( $_glarray_j + 1 ))
		done
		unset _glarray_i _glarray_j
	}

	_glarrayzsh() {
		typeset -ga $_glarray_name
		_glarray_i=0
		_glarray_j=0
		for _glarray_i; do
			typeset -g "$_glarray_name[$_glarray_j]"="$_glarray_i"
			_glarray_j=$(( $_glarray_j + 1 ))
		done
		unset _glarray_i _glarray_j
	}

	_glarray_init() {
		if [ -n "${BASH_VERSION:-}" ]; then
			_glarray=_glarraybash
		elif [ -n "${KSH_VERSION:-}" ]; then
			_glarray=_glarrayksh
		elif [ -n "${ZSH_VERSION:-}" ]; then
			setopt ksharrays
			_glarray=_glarrayzsh
		else
			echo "Error: unsuported shell :(" >&2
			exit 1
		fi
	}

	if [ -z ${_glarray:-} ]; then
		_glarray_init
	fi
	_glarray_name="$1"
	shift
	$_glarray $@
	unset _glarray_name
}

md2() {
	_value="$*"

	# S-box
	glarray S  41  46   67 201 162 216 124   1  61  54  84 \
		   161 236 240   6  19  98 167   5 243 192 199 \
		   115 140 152 147  43 217 188  76 130 202  30 \
		   155  87  60 253 212 224  22 103  66 111  24 \
		   138  23 229  18 190  78 196 214 218 158 222 \
		    73 160 251 245 142 187  47 238 122 169 104 \
		   121 145  21 178   7  63 148 194  16 137  11 \
		    34  95  33 128 127  93 154  90 144  50  39 \
		    53  62 204 231 191 247 151   3 255  25  48 \
		   179  72 165 181 209 215  94 146  42 172  86 \
		   170 198  79 184  56 210 150 164 125 182 118 \
		   252 107 226 156 116   4 241  69 157 112  89 \
		   100 113 135  32 134  91 207 101 230  45 168 \
		     2  27  96  37 173 174 176 185 246  28  70 \
		    97 105  52  64 126  15  85  71 163  35 221 \
		    81 175  58 195  92 249 206 186 197 234  38 \
		    44  83  13 110 133  40 132   9 211 223 205 \
		   244  65 129  77  82 106 220  55 200 108 193 \
		   171 250  36 225 123   8  12 189 177  74 120 \
		   136 149 139 227  99 232 109 233 203 213 254 \
		    59   0  29  57 242 239 183  14 102  88 208 \
		   228 166 119 114 248 235 117  75  10  49  68 \
		    80 180 143 237  31  26 219 153 141  51 159 \
		    17 131  20

	_i=0
	glarray M
	_us="$(printf "\037")"
	OLDIFS="$IFS"
	IFS="$_us"
	_value=$(printf "$_value" | sed "s/./&$_us/g")
	# Step 0. Preparation
	for _char in $_value; do
		IFS="$OLDIFS"
		M[_i]="$(ord "$_char")"
		IFS="$_us"
		_i=$(( _i + 1 ))
	done
	IFS="$OLDIFS"
	_N="${#M[*]}"
	unset _char OLDIFS _us _value _i

	# Step 1. Append Padding Bytes
	_pad=$(( 16 - ($_N % 16) ))
	if [ $_pad -eq 0 ]; then
		_pad=16
	fi
	for _i in $(enum 0 $_pad); do
		M[$(( _N + _i ))]=$_pad
	done
	_N=$(( _N + _pad ))
	unset _pad _i

	# Step 2. Append Checksum
	glarray C 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
	_L=0
	for _i in $(enum 0 $(( _N / 16 )) ); do
		for _j in $(enum 0 16); do
			_c=${M[_i * 16 + _j]}
			C[_j]=$(( ${S[_c ^ _L]} ^ ${C[_j]} ))
			_L=${C[_j]}
		done
	done
	glarray M ${M[*]} ${C[*]}
	_N=$(( _N + 16 ))
	unset _L _i _j _c

	# Step 3. Initialize MD Buffer
	glarray X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 \
		0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 


	# Step 4. Process Message in 16-Byte Blocks
	for _i in $(enum 0 $(( _N / 16 )) ); do
		for _j in $(enum 0 16); do
			X[16 + _j]=${M[_i * 16 + _j]}
			X[32 + _j]=$(( ${X[16 + _j]} ^ ${X[_j]} ))
		done
		_t=0
		for _j in $(enum 0 18); do
			for _k in $(enum 0 48); do
				_tmp=$(( ${X[_k]} ^ ${S[_t]} ))
				_t=$_tmp
				X[_k]=$_tmp
			done
			_t=$(( (_t + _j) % 256 ))
		done
	done
	unset _i _j _k _t _tmp

	# Step 5. Output
	printf "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x\n" ${X[0]} ${X[1]} ${X[2]} ${X[3]} ${X[4]} ${X[5]} ${X[6]} ${X[7]} ${X[8]} ${X[9]} ${X[10]} ${X[11]} ${X[12]} ${X[13]} ${X[14]} ${X[15]}

	# Step 6. Final cleanup
	unset C M S X _N _glarray
}
