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
# Package all currently present build artefacts into the 'dist' directory

cd "$(dirname "$0")"/..
base="$PWD"
PATH="$PWD/bin"
for toolchain in "$base" "$base"/toolchain-*/; do
	[ -f "$toolchain/native-toolchain.cmake" ] || continue
	cd "$toolchain"

	# remove build data
	rm -rf cget/build

	# build archive name from host and target platforms
	host="$(sh "$base/cross-env.sh" native-toolchain.cmake set | grep "^CC=.*-gcc'\?\$")"
	host="${host##*/}"
	host="${host%"'"}"
	host="${host%-gcc}"

	case "$host" in
		*-mingw32) hostos=Windows;;
		*) hostos=Linux;;
	esac

	mkdir -p "$base/dist/$hostos"

	case "$hostos" in
		Windows)
			cp "$base/README.rst" "$base/install-toolchain.cmd" "$base/dist/$hostos"
			# remove all symlinks from the windows toolchains
			find *-*-*/ -type l -exec rm {} +
			out="$base/dist/$hostos/$hostos-toolchain-"$host".zip"
			nativearch() { 7za a -Tzip "$out" "$@"; }
			excl="-xr!";;
		*)
			cp "$base/README.rst" "$base/install-toolchain.sh" "$base/dist/$hostos"
			out="$base/dist/$hostos/$hostos-toolchain-"$host".tar.gz"
			nativearch() { tar c "$@" | 7za a -Tgzip -si "$out"; }
			excl="--exclude=";;
	esac

	if [ ! -f "$out" -o "$1" = "-a" ]; then
		echo "Packaging native $host toolchain and tools..."
		rm -f "$out"
		nativearch ${excl}mingw-cross-toolchain ${excl}musl-cross-toolchain ${excl}glibc-cross-toolchain ${excl}.breakpoints bin lib libexec include cget/cget.cmake cget/pkg etc *.cmd *.sh *.rst $host.cmake native-toolchain.cmake $host/ share
	else
		echo "Skipping native $host toolchain and tools. Use $0 -a to rebuild."
	fi

	for i in *-*-*; do
		[ -f "$i.cmake" ] || continue
		[ "$i" = "$host" ] && continue
		target="${i%/}"
		target="${target##*/}"
		out="$base/dist/$hostos/$hostos-cross-${host%%-*}_$target.tar.lz"
		if [ ! -f "$out" -o "$1" = "-a" ]; then
			echo "Packaging $target..."
			tar c "$target.cmake" "$target" | lzip > "$out"
		else
			echo "Skipping existing package for $target, use $0 -a to rebuild."
		fi
	done
done
