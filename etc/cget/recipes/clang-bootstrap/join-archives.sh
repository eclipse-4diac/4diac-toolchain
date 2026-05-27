#!/bin/sh
outlib="$1"
shift

rm -rf join
mkdir join

for lib in "$@"; do
	lib="$(cd "$(dirname "$lib")"; pwd)/$(basename "$lib")"
	find "$lib" -name \*.a | while read file; do
		name="$(basename "$file")"
		mkdir "join/$name"
		( cd "join/$name"; llvm-ar x "$file"; )
	done
done

rm -f "$outlib"
llvm-ar rcs "$outlib" join/*/*.o

rm -rf join
