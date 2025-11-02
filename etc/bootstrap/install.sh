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
set -e

die() { echo "$*" >&2; exit 1; }

triplet="$1"
release="$2"
releasehash="$3"

baseurl="https://sourceforge.net/projects/fordiac/files/4diac-fbe"
file="$triplet-toolchain.tar.lz"

echo "Downloading $baseurl/release-$release/$file/download..."

downloaddir="${CGET_DOWNLOADS_DIR:-$PWD}"
[ -f "$downloaddir/$file" ] || downloaddir="${CGET_CACHE_DIR:-$PWD/download-cache}/sha256-$releasehash"
mkdir -p "$downloaddir"

[ -f "$downloaddir/$file" ] || COLUMNS=60 curl -f --progress-bar --location --disable --insecure -o "$downloaddir/$file" "$baseurl/release-$release/$file/download"
echo "Checking $file..."
if [ "$(sha256sum < "$downloaddir/$file")" != "$releasehash  -" ]; then
	mv "$downloaddir/$file" "$downloaddir/$file.broken"
	die "SHA256 checksum for $downloaddir/$file doesn't match expected value!"
fi

echo "Unpacking $file..."
find * -type f > installer/filelist.txt
count=0
lzip -d < "$downloaddir/$file" | tar xv -X installer/filelist.txt | while read line; do
	count="$((count+1))"
	echo -ne "($count)\r"
done

echo "Finishing install..."
"$PWD/bin/busybox" --install "$PWD/bin/"

# allow fixups to be updated in toolchain releases while keeping the same core installer
export PATH="$PWD/bin"
exec bin/sh etc/bootstrap/install-finish.sh "$triplet" "$release" "$releasehash"
