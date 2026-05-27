#!/bin/sh
#********************************************************************************
# Copyright (c) 2018, 2025 OFFIS e.V.
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

cd "$(dirname "$0")/../.."

log() {
	echo "$@"
	"$@"
}

for tc in . toolchain-*/; do
	log cp -a etc/cget/recipes/python-modules/pip "$tc"/bin/pip
	grep -l SDK/MacOSX "$tc"/clang-toolchain/bin/* | while read file; do
		log cp -a etc/cget/recipes/clang-macos/wrapper.sh "$file"
	done
	for file in "$tc"/*-*-*.cmake; do
		log cp -a etc/cget/recipes/cross-toolchain/toolchain.cmake "$file"
	done
done

for tc in toolchain-*/; do
	log rsync -av --delete etc/cget etc/bootstrap etc/*.* "$tc"/etc/
done
