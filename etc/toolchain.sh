#!/bin/sh
#********************************************************************************
# Copyright (c) 2018, 2023 OFFIS e.V.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
# 
# Contributors:
#    Jörg Walter - initial implementation
# *******************************************************************************/
#
# build (add) a cross-compiler toolchain to the current toolchain directory
#
set -e
cd "$(dirname "$0")/.."

# detect cross-building
nativedir="$(readlink -f .cache)"
nativedir="${nativedir%/.cache}"

# use defaults if no target given on the command line
if [ "$#" = 0 ]; then
	if grep -E -- '-apple-darwin|-w64-mingw32' native-toolchain.cmake; then
		# add x86 linux toolchain, which is not part of the default set of cross-compilers
		"${nativedir}/bin/cget" -p . install -U cross-toolchain -DTARGETS=x86_64-linux-musl
		# omit glibc toolchain: non-linux toolchains do not support it
		# omit clang: windows doesn't support it, on darwin it is the native toolchain
		exec "${nativedir}/bin/cget" -p . install -U cross-toolchain
	else
		exec "${nativedir}/bin/cget" -p . install -U cross-toolchain glibc-cross-toolchain clang-macos
	fi
fi

force=
[ "$1" != "-f" ] || { shift; force=1; }

# build the provided target(s)
for i in "$@"; do
	case "$i" in
		*-apple-*) pkg="clang-macos";;
		*-unknown-linux-*) pkg="clang";;
		*-gnu*) pkg="glibc-cross-toolchain";;
		*-*-*) pkg="cross-toolchain";;
		*) echo "Unknown target: $i" >&2; exit 1;;
	esac
	[ -n "$force" -o ! -f "$i".cmake ] || { echo "Skipping $i, already installed."; continue; }
	"${nativedir}/bin/cget" -p . install -U "$pkg" -DTARGETS="$i" 2>&1 | tee "build-toolchain-$i.log" || exit 1
done
