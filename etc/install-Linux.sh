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

if [ -x bin/sh -a "$1" != "-u" ]; then
	echo "Toolchain already installed. Use '$0 -u' to update."
	exit 0
fi

die() { echo "$*" >&2; exit 1; }

host="$(uname -s)"
arch="$(uname -m)"

baseurl="https://sourceforge.net/projects/fordiac/files/4diac-fbe"
triplet="x86_64-linux-musl"
file="$host-toolchain-$triplet.tar.gz"

release='2024-02'
hash='e59af1df750bcd2e40a5578d9b7882747ae5412b69cd6dcb9f4eaaca5e3dc4f7'

fetch_file_authenticated() {
	download="$1"
	url="$2"
	hash="$3"

	if [ ! -f "$download" ]; then
		echo "Downloading $url..."
		if type curl >/dev/null && curl --location --disable --insecure -o "$download" "$url"; then
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

	if ! type sha256sum > /dev/null; then
		echo "WARNING: sha256sum not found, not verifying archives."
	elif [ "$(sha256sum < "$download")" != "$hash  -" ]; then
		mv "$download" "$download.broken"
		die "SHA256 checksum for $1 doesn't match expected value!"
	fi
}

fetch_file_authenticated "$file" "$baseurl/release-$release/$file/download" "$hash"
[ -f "$file" ] || die "ERROR: Could not download $file. Please download it manually and put it into $PWD"

gzip -d < "$file" | tar x --skip-old-files
mkdir -p ".cache/sha256-$hash"
mv "$file" ".cache/sha256-$hash/$file"
rm -f *-toolchain-*.zip *-toolchain-*.tar.gz

echo "Installation complete. Run ./install-crosscompiler.sh to download additional cross-compiling toolchains."
./install-crosscompiler.sh || true
