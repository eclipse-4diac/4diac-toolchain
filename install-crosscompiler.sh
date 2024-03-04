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

# move pre-downloaded toolchains into cache directory
for i in *-cross-*.tar.lz; do
	[ -f "$i" ] || continue
	sha="$(sha256sum "$i")"
	sha="${sha%% *}"
	mkdir -p .cache/sha256-"$sha"
	mv "$i" .cache/sha256-"$sha"
done

[ -n "$1" ] || die "Usage: $0 <target-triplet>"

targetarch="$1"
[ ! -f "$targetarch.cmake" ] || exit 0

baseurl="https://sourceforge.net/projects/fordiac/files/4diac-fbe"

hostarch="$(uname -m)" # x86_64
hostplatform="$(uname -s)" # Linux
[ "$hostplatform" = "Windows_NT" ] && hostplatform=Windows
file="${hostplatform}-cross-${hostarch}_${targetarch}.tar.lz"

mkdir -p .cache

fetch_file_authenticated() {
        local download="$1" url="$2" hash="$3"

        if [ ! -f "$download" ]; then
                mkdir -p "${download%/*}"
                echo "Downloading $url to $download..."
                curl --location --disable --insecure -o "$download" "$url"
        fi

        if [ "$(sha256sum < "$download")" != "$hash  -" ]; then
                mv "$download" "$download.broken"
                die "SHA256 checksum for $url doesn't match expected value $hash!"
        fi
}

while read hash url; do
        [ "${url##*/}" = "$file" ] || continue
        download=".cache/sha256-$hash/$file"
        fetch_file_authenticated "$download" "$baseurl/$url" "$hash"
        echo "Installing toolchain..."
        lzip -d < "$download" | tar x
        echo "Toolchain for $targetarch installed."
        exit 0
done < etc/crosscompilers.sha256sum

echo "No pre-built cross-compiler found. Build one yourself by running ./etc/toolchain.sh $targetarch"
exit 1
