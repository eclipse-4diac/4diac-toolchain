#!/bin/bash
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

cd "$(dirname "$0")"/../..
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

detect_triplet() {
	# build archive name from triplet and target platforms
	triplet="$(sh "$base/cross-env.sh" native-toolchain.cmake set | grep -E "^CC=.*-(gcc|clang)'?\$")"
	triplet="${triplet##*/}"
	triplet="${triplet%"'"}"
	triplet="${triplet%-gcc}"
	triplet="${triplet%-clang}"

	case "$triplet" in
	*-w64-*)
		# remove all symlinks from the windows toolchains
		find *-*-*/ -type l -exec rm {} +
		script=".cmd"
		hosttoolchain="$triplet"
		hostcmake="$triplet.cmake";;

	*-darwin*)
		script=".sh"
		hosttoolchain="clang-toolchain"
		hostcmake="$(echo *-apple*.cmake *-unknown-*-*.cmake)";;

	*)
		script=".sh"
		hosttoolchain="$triplet"
		hostcmake="$triplet.cmake";;
	esac
}

# reproducible archives
rtar() {
	local out="$1"
	shift
	env TZ=UTC LC_ALL=C /usr/bin/tar c \
		--sort=name --format=posix \
		--pax-option=exthdr.name=%d/PaxHeaders/%f \
		--pax-option=delete=atime,delete=ctime \
		--mtime=2024-01-01\ 00:00:00 \
		--numeric-owner --owner=0 --group=0 \
		--mode=go+u,go-w "$@" \
		| lzip --best > "$out"
}

pids=""

# package cross-compilers first, so that we can build the SHA256 checksum file
for toolchain in "$base" "$base"/toolchain-*/; do
	[ -f "$toolchain/native-toolchain.cmake" ] || continue
	cd "$toolchain"
	detect_triplet

	# remove build data
	rm -rf cget/build

	for i in *-*-*; do
		[ -f "$i.cmake" ] || continue
		[ "$i" = "$triplet" ] && continue
		target="${i%/}"
		target="${target##*/}"
		out="$dist/${triplet}_cross_$target.tar.lz"
		if [ ! -f "$out" -o "$1" = "-f" ]; then
			(
			echo "Packaging $target..."
			rtar "$out" "$target.cmake" "$target"
			) &
			pids="$pids $!"
		else
			echo "Skipping existing package for $target, use $0 $release -f to rebuild."
		fi
	done

	rm -rf clang-toolchain/bootstrap clang-toolchain/lib/*.a
	if [ -d clang-toolchain -a "$hosttoolchain" != "clang-toolchain" ]; then
		target=clang-toolchain
		out="$dist/${triplet}_cross_clang.tar.lz"
		if [ ! -f "$out" -o "$1" = "-f" ]; then
			(
			echo "Packaging $target..."
			rtar "$out" --exclude "MacOSX*.sdk" *-unknown-linux-*.cmake *-apple-*.cmake "$target"
			) &
			pids="$pids $!"
		else
			echo "Skipping existing package for $target, use $0 $release -f to rebuild."
		fi
	fi
done

for id in $pids; do
	wait -n $pids
done

# generate checksums to include them in base toolchain archive
cd "$base"
sha256sum "release-$release"/*_cross_*.tar.lz > etc/crosscompilers.sha256sum.new
if diff -q etc/crosscompilers.sha256sum etc/crosscompilers.sha256sum.new >/dev/null; then
	rm etc/crosscompilers.sha256sum.new
else
	mv etc/crosscompilers.sha256sum.new etc/crosscompilers.sha256sum
fi

pids=""
# package base toolchains
for toolchain in "$base" "$base"/toolchain-*/; do
	[ -f "$toolchain/native-toolchain.cmake" ] || continue
	(
	cd "$toolchain"
	detect_triplet
	echo "Packaging native $triplet toolchain and tools..."

	if [ "$toolchain" != "$base" ]; then
		cp -a "$base"/etc "$base"/doc "$base"/*.md "$base"/*.sh "$base"/*.cmd .
	fi
	out="$dist/$triplet-toolchain.tar.lz"
	rtar "$out" --exclude="MacOSX*.sdk" --exclude=.breakpoints --exclude=install.sh --exclude=install.cmd doc bin lib libexec include cget/cget.cmake cget/pkg etc install-crosscompiler.* cross-env.sh *.md $hostcmake native-toolchain.cmake "$hosttoolchain/" share


	hash="$(sha256sum "$out")"
	hash="${hash%% *}"

	sed -i -e "s/release='.*'/release='$release'/;s/\\(\\($triplet) \\|\\$\\)releasehash\\)='[0-9a-f]\\{64\\}'/\\1='${hash%% *}'/" "$base/etc/install$script"
	) &
	pids="$pids $!"
done

for id in $pids; do
	wait -n $pids
done

cd "$base/etc"
for i in install.*; do
	cp "$i" "$dist/4diac-toolchain-$release-$i"
done

