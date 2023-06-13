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
cd "$(dirname "$0")/.."

# detect cross-building
nativedir="$(readlink -f .cache)"
nativedir="${nativedir%/.cache}"

# use defaults if no target given on the command line
if [ "$#" = 0 ]; then
	if [ -f bin/cmake.exe ]; then
		# The windows toolchain does not support glibc variants
		exec "${nativedir}/bin/cget" -p . install -U cross-toolchain
	else
		exec "${nativedir}/bin/cget" -p . install -U cross-toolchain glibc-cross-toolchain
	fi
fi

# build the provided target(s)
for i in "$@"; do
	case "$i" in
		*-gnu*) pkg="glibc-cross-toolchain";;
		*-*-*) pkg="cross-toolchain";;
		*) echo "Unknown target: $i" >&2; exit 1;;
	esac
	[ -f "$i".cmake ] && echo "Skipping $i, already installed." && continue
	"${nativedir}/bin/cget" -p . install -U "$pkg" -DTARGETS="$i" || exit 1
done
