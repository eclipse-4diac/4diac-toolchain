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

cd "$(dirname "$0")"
[ "${PWD##*/}" != "etc" ] || cd ..

if [ -x bin/sh ]; then
	echo "Toolchain already installed. To update, delete it and redownload."
	exit 0
fi

die() { echo "$*" >&2; exit 1; }

host="$(uname -s)"
arch="$(uname -m)"
[ "$arch" != "arm64" ] || arch="aarch64"

baseurl="https://sourceforge.net/projects/fordiac/files/4diac-fbe"
case "$host" in
Linux)
	triplet="$arch-linux-musl";;
Darwin)
	triplet="$arch-apple-darwin20.2";;
*)
	die "System $host is not supported.";;
esac

installer="4diac-fbe-installer-v3-$triplet.tar.gz"
case "$triplet" in
aarch64-apple-darwin20.2) installerhash='63208bcf50d4129e2ebf26231f150703b6f56cfd098bb1d5adfbbb425f94b064';;
x86_64-linux-musl) installerhash='b5f5a96ed6091f49c3ace0161e452eaf19aa95c8556ff3d9943f8452b133cc0d';;
*) die "System $triplet has no binary releases.";;
esac

release='2025-02'
case "$triplet" in
aarch64-apple-darwin20.2) releasehash='c9e71cedee55d9b6d3ce8214e01b8cc73a79936583e405f793fb2ba792394c5b';;
x86_64-linux-musl) releasehash='186339b0b885ebf3a728dfc912df1ff5df951848bff31c9b00e894b0242bf475';;
esac

fetch_file_authenticated() {
	download="$1"
	url="$2"
	hash="$3"

	[ -f "$download" ] || download="${CGET_CACHE_DIR:-$PWD/download-cache}/sha256-$hash/$(basename "$download")"

	if [ ! -f "$download" ]; then
		echo "Downloading $url..."
        mkdir -p "$(dirname "$download")"
		if type curl >/dev/null && COLUMNS=60 curl -f --progress-bar --location --disable --insecure -o "$download" "$url"; then
			: # obvious tool
		elif type wget >/dev/null && wget --no-check-certificate -O "$download" "$url"; then
			: # obvious tool
		elif type wget2 >/dev/null && wget2 --no-check-certificate -O "$download" "$url"; then
			: # obvious tool
		elif type python >/dev/null && python - "$url" "$download" << 'EOF'; then
import sys
try: from urllib.request import urlretrieve
except: from urllib import urlretrieve
urlretrieve(sys.argv[1], sys.argv[2])
EOF
			: # works for python2 and python3
		elif type GET >/dev/null && GET "$url" > "$download"; then
			: # libwww-perl
		elif type perl >/dev/null && perl 'use LWP::Simple; exit(getstore($ARGV[0], $ARGV[1])-200)' "$url" "$download"; then
			: # same, just in case the command line utilities are not installed
		elif type fetch >/dev/null && fetch --no-verify-peer -o "$download" "$url"; then
			: # FreeBSD
		else
			die "Need a download program with SSL/TLS support: curl, wget, python2, python3, or libwww-perl."
		fi
	fi

	if type sha256sum > /dev/null; then
		dlhash="$(sha256sum < "$download")"
	elif type shasum > /dev/null; then
		dlhash="$(shasum -a  < "$download")"
	else
		echo
		echo "ERROR: neither sha256sum nor shasum found, can't verify downloads." >&2
		echo
		exit 1
	fi

	if [ "$dlhash" != "$hash  -" ]; then
		mv "$download" "$download.broken"
		die "SHA256 checksum for $1 doesn't match expected value!"
	fi
}

downloaddir="${CGET_DOWNLOADS_DIR:-$PWD}"
fetch_file_authenticated "$downloaddir/$installer" "$baseurl/installer/$installer/download" "$installerhash"
[ -f "$download" ] || die "ERROR: Could not download $installer. Please download it manually and put it into $downloaddir"

mkdir -p installer
cd installer
gzip -d < "$download" | tar x

"$PWD"/bin/busybox --install $PWD/bin/
cd ..

export PATH="$PWD/installer/bin"
exec "$PWD/installer/bin/sh" installer/etc/bootstrap/install.sh "$triplet" "$release" "$releasehash"
