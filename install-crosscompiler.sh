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
set -e

die() { echo "$*" >&2; exit 1; }

cd "$(dirname "$0")"
PATH="$PWD/bin"

cachedir="${CGET_CACHE_DIR:-$PWD/download-cache}"
downloaddir="${CGET_DOWNLOADS_DIR:-$PWD}"

[ -n "$1" ] || die "Usage: $0 <target-triplet>"

targetarch="$1"
[ ! -f "$targetarch.cmake" ] || exit 0
case "$targetarch" in
	*-unknown-* | *-apple-*) targetarch=clang;;
esac

baseurl="https://sourceforge.net/projects/fordiac/files/4diac-fbe"

if [ -x bin/gcc ]; then
	triplet="$(bin/gcc --version)"
	triplet="${triplet%%-gcc*}"
else
	triplet="$(uname -m)-apple-darwin20.2"
fi

file="${triplet}_cross_${targetarch}.tar.lz"

fetch_file_authenticated() {
        download="$1"
        url="$2"
        hash="$3"

        [ -f "$download" ] || download="${CGET_CACHE_DIR:-$PWD/download-cache}/sha256-$hash/$(basename "$download")"

        if [ ! -f "$download" ]; then
                mkdir -p "$(dirname "$download")"
                echo "### Downloading cross-compiler toolchain $url..."
                COLUMNS=60 curl --retry 5 --retry-all-errors -f --progress-bar --location --disable --insecure -o "$download" "$url"
        fi

        if [ "$(sha256sum < "$download")" != "$hash  -" ]; then
                mv "$download" "$download.broken"
                die "SHA256 checksum for $url doesn't match expected value $hash!"
        fi
}

while read hash url; do
        [ "${url##*/}" = "$file" ] || continue
        download="$downloaddir/$file"
        fetch_file_authenticated "$download" "$baseurl/$url" "$hash"
        echo "### Installing cross-compiler toolchain for $targetarch..."
        lzip -d < "$download" | tar x
        echo "### Cross-compiler toolchain for $targetarch installed."
        [ "$targetarch" != clang ] || ./clang-toolchain/bin/x86_64-apple-darwin*-clang --version
        exit 0
done < etc/crosscompilers.sha256sum

echo "No pre-built cross-compiler found. Build one yourself by running ./etc/toolchain.sh $targetarch"
exit 1
