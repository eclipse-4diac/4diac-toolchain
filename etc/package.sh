#!/bin/sh
#********************************************************************************
# Copyright (c) 2018, 2024 OFFIS e.V.
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
set -e

cd "$(dirname "$0")"/..
base="$PWD"
PATH="$PWD/bin"

if [ -z "$1" -o "$1" = "-f" ]; then
	echo "Usage: $0 <release-tag> [-f]" >&2
	exit 1
fi

release="$1"
dist="$base/release-$release"
shift

if [ -e "$dist" -a -z "$1" ]; then
	echo "Release $release already exists. Use '$0 $release -a' to add new toolchains." >&2
	exit 1
fi

mkdir -p "$dist"

detect_host() {
	# build archive name from host and target platforms
	host="$(sh "$base/cross-env.sh" native-toolchain.cmake set | grep "^CC=.*-gcc'\?\$")"
	host="${host##*/}"
	host="${host%"'"}"
	host="${host%-gcc}"

	case "$host" in
		*-mingw32) hostos=Windows;;
		*) hostos=Linux;;
	esac

	case "$hostos" in
		Windows)
			# remove all symlinks from the windows toolchains
			find *-*-*/ -type l -exec rm {} +
			out="$dist/$hostos-toolchain-"$host".zip"
			nativearch() { rm -f "$out"; 7za a -Tzip "$out" "$@"; }
			excl="-xr!";;
		*)
			out="$dist/$hostos-toolchain-"$host".tar.gz"
			nativearch() { rm -f "$out"; tar c "$@" | 7za a -Tgzip -si "$out"; }
			excl="--exclude=";;
	esac

}

# package cross-compilers first, so that we can build the SHA256 checksum file
for toolchain in "$base" "$base"/toolchain-*/; do
	[ -f "$toolchain/native-toolchain.cmake" ] || continue
	cd "$toolchain"
	detect_host

	# remove build data
	rm -rf cget/build

	for i in *-*-*; do
		[ -f "$i.cmake" ] || continue
		[ "$i" = "$host" ] && continue
		target="${i%/}"
		target="${target##*/}"
		out="$dist/$hostos-cross-${host%%-*}_$target.tar.lz"
		if [ ! -f "$out" -o "$1" = "-f" ]; then
			echo "Packaging $target..."
			tar c "$target.cmake" "$target" | lzip > "$out"
		else
			echo "Skipping existing package for $target, use $0 $release -f to rebuild."
		fi
	done
done

# generate checksums to include them in base toolchain archive
cd "$base"
sha256sum "release-$release"/*.tar.lz > etc/crosscompilers.sha256sum

# reset checksums to dummy value in install scripts so that release tarballs have predictable content
cd "$base/etc"
sed -i -e "s/release='.*'/release='unknown'/;s/hash='[0-9a-f]\{64\}'/hash='ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'/" install-*.*
for i in install-*.*; do
	cp "$i" "$dist/4diac-toolchain-$release-$i"
done

# package base toolchains
for toolchain in "$base" "$base"/toolchain-*/; do
	[ -f "$toolchain/native-toolchain.cmake" ] || continue
	cd "$toolchain"
	detect_host
	echo "Packaging native $host toolchain and tools..."

	cp "$base"/etc/install-*.* "$base/etc/crosscompilers.sha256sum" "etc" || true
	nativearch ${excl}mingw-cross-toolchain ${excl}musl-cross-toolchain ${excl}glibc-cross-toolchain ${excl}.breakpoints bin lib libexec include cget/cget.cmake cget/pkg etc install-crosscompiler.* cross-env.sh *.md $host.cmake native-toolchain.cmake $host/ share


	hash="$(sha256sum "$out")"
	hash="${hash%% *}"

	sed -i -e "s/release='.*'/release='$release'/;s/hash='[0-9a-f]\{64\}'/hash='$hash'/" "$dist/4diac-toolchain-$release-install-$hostos".*
done

# update installer scripts in base repo so that final checksums can be committed to git
cd "$base/etc"
for i in install-*.*; do
	cp "$dist/4diac-toolchain-$release-$i" "$i"
done

