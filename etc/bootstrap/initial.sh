# !/bin/sh
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
# Bootstrap a working stand-alone portable toolchain.
#
# Executes these stages:
#
# 1. fetch pre-compiled preliminary compiler toolchain
# 2. fetch & build tools needed for cget.sh (busybox, GNU make, CMake, gcc)
# 3. pass control to bootstrap.sh to build actual toolchain environment
#
# This is only supported on Linux.
#
# This script needs a basic POSIX shell and minimal POSIX tools (cp, rm, mv,
# and so on -- GNU coreutils or busybox, for example), and optionally a tool to
# download files from HTTPS servers (wget, curl, python, perl, or FreeBSD
# fetch).  Copy over subdirectory `download-cache' from an already-bootstrapped
# machine if you want to skip downloads.


################################################################################
### low-level helper variables/functions
################################################################################

set -e
cd "$(dirname "$0")/../.."

toolchain="$PWD"
arch="$(uname -m)-linux-musl"

export CMAKE_BUILD_PARALLEL_LEVEL="$(grep -c '^processor[^a-z]*:' /proc/cpuinfo)"
[ "$CMAKE_BUILD_PARALLEL_LEVEL" -gt 0 ] || CMAKE_BUILD_PARALLEL_LEVEL=1
export MAKEFLAGS="-j$CMAKE_BUILD_PARALLEL_LEVEL"

die() { echo "$exe: $*" >&2; exit 1; }
msg() { echo "| $*"; }
stage() { echo; echo "===> $*"; echo; }

rebuild=""
if [ "$1" = "-r" ]; then
	rebuild=1
elif [ $# != 0 ]; then
	die "Usage: $0 [-r]"
fi

################################################################################
### helper functions
################################################################################

# in order to improve isolation, make sure that using system tools is explicit
original_path="$PATH"
PATH=""
with_system_tools() {
	# explicitly try to pick up system tools
	if [ -n "$saved_path" ]; then
		"$@"
		return "$?"
	else
	   	saved_path="$PATH"
		PATH="$saved_path:$original_path:/usr/bin:/usr/local/bin:/bin"
		"$@"
		result="$?"
		PATH="$saved_path"
		unset saved_path
		return "$result"
	fi
}

fetch_file() { with_system_tools _fetch_file "$@"; }
cachedir="$toolchain/download-cache"
_fetch_file() {
	file="$1"; hash="$2"; url="$3"

	# if only one argument is passed, read data from cget recipe
	# note that this assumes a specific order of arguments
	if [ -z "$2$3" -a -f "etc/cget/recipes/$1/package.txt" ]; then
		read url _ hash _ < "etc/cget/recipes/$1/package.txt"
		if [ -z "${url##*/*@*}" ]; then
				url="https://github.com/${url%%@*}/archive/${url#*@}.tar.gz"
		fi
		file="${url##*/}"
		hash="${hash#sha256:}"
	fi

	download="$cachedir/sha256-$hash/$file"
	if [ ! -f "$download" ]; then
		mkdir -p "${download%/*}"
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
		msg "WARNING: sha256sum not found, not verifying archives."
	elif [ "$hash" != 0 ] && [ "$(sha256sum < "$download")" != "$hash  -" ]; then
		mv "$download" "$download.broken"
		die "SHA256 checksum for $1 doesn't match expected value $hash"
	fi
}

################################################################################
### stage2 helper functions
################################################################################

build_busybox() {
	! ( PATH="$PWD/bin"; type busybox 2>/dev/null; ) || return 0
	msg "Building busybox..."
	fetch_file busybox
	tar xzf "$download"
	cd busybox-w32-*
	sh ../../etc/cget/recipes/busybox/build.sh ../bin
	cd ..
	rm -r busybox-w32-*
}

build_make() {
	! ( PATH="$PWD/bin"; type make 2>/dev/null; ) || return 0
	msg "Building GNU make..."
	fetch_file gnumake
	tar xzf "$download"
	cd make-*
	sh ../../etc/cget/recipes/gnumake/build.sh ../bin
	cd ..
	rm -rf make-*
}


build_cmake() {
	! ( PATH="$PWD/bin:$PWD/cmake/Bootstrap.cmk"; type cmake 2>/dev/null; ) || return 0
	msg "Building CMake (minimal)..."

	# fetch the full version into the download cache, since bootstrap cmake can't download files
	read url _ sha256 _ < "$PWD/etc/cget/recipes/cmake/package.txt"
	fn="${url##*/}"
	sha256="${sha256#sha256:}"
	fetch_file "$fn" "$sha256" "$url"

	# we use an older cmake for bootstrap as it is known to work in this limited environment
	fetch_file cmake-3.13.2.tar.gz c925e7d2c5ba511a69f43543ed7b4182a7d446c274c7480d0e42cd933076ae25 https://github.com/Kitware/CMake/releases/download/v3.13.2/cmake-3.13.2.tar.gz

	tar xzf "$download"
	rm -rf cmake
	mv cmake-* cmake
	cd cmake
	ccache="--enable-ccache"
	type ccache 2>/dev/null || ccache=""
	export CCACHE_COMPILERCHECK="string:$("${CXX}" -v 2>&1)"
	sed -i -e 's/MINGW/Windows_NT/; s/pwd -W/pwd/' bootstrap
    sh ./bootstrap --parallel="$CMAKE_BUILD_PARALLEL_LEVEL" LDFLAGS="-static" $ccache CC="$CC" CXX="$CXX" CFLAGS="-static" CXXFLAGS="-static"
	unset CCACHE_COMPILERCHECK
	cd ..
	# bootstrap cmake needs the source dir, so keep it
}

################################################################################
### bootstrap stages
################################################################################

prepare_bootstrap() {
	stage "Preparing bootstrap..."
	with_system_tools mkdir -p bootstrap
	with_system_tools rm -rf bootstrap/etc
	with_system_tools cp -r etc *.md install-crosscompiler.* cross-env.sh bootstrap
	with_system_tools ln -sf ../download-cache bootstrap/
	bootstrap="$PWD/bootstrap"
}

# Download a suitable initial compiler that should work without installation
stage1() {
	stage "Stage 1: bootstrap compiler"

	export CXX="$bootstrap/compiler/g++"
	export CC="$bootstrap/compiler/gcc"
	export AR="$bootstrap/compiler/ar"
	[ ! -x "$CXX" -a ! -x "$bootstrap/bin/g++" ] || return 0

	msg "Downloading pre-built bootstrap compiler"
	bootlin_version=bleeding-edge-2021.11-5
	urlarch="${arch%-linux-musl}"
	[ "$urlarch" = "x86_64" ] && urlarch="x86-64"
	fetch_file gcc-"$arch".tgz 468e6b73146595923fe87980a30adb54cd78f4c1e2f228e1a2c9bb705ea4243d \
		"https://toolchains.bootlin.com/downloads/releases/toolchains/$urlarch/tarballs/$urlarch--musl--$bootlin_version.tar.bz2"
	with_system_tools tar xf "$download" 2>/dev/null
	with_system_tools mv "$urlarch--musl--$bootlin_version" compiler
	( cd compiler; with_system_tools ./relocate-sdk.sh; )

	for i in gcc g++; do
		echo '#!/bin/sh' > compiler/"$i"
		echo 'exec "$(dirname "$0")/bin/'"${arch%-musl}"'-$(basename "$0")" -static --static "$@"' >> compiler/"$i"
		with_system_tools chmod 755 compiler/"$i"
	done

	for i in ar; do
		echo '#!/bin/sh' > compiler/"$i"
		echo 'exec "$(dirname "$0")/bin/'"${arch%-musl}"'-$(basename "$0")" "$@"' >> compiler/"$i"
		with_system_tools chmod 755 compiler/"$i"
	done

	with_system_tools mkdir bin
	with_system_tools cp etc/cget/wrapper bin/cget
}

# build tools that are needed to build the actual toolchain environment
stage2() {
	stage "Stage 2: bootstrap tools"

	export PATH="$bootstrap/compiler:$bootstrap/compiler/usr/bin:$bootstrap/compiler/bin:$bootstrap/bin:$bootstrap/etc/bootstrap"
	export LD_LIBRARY_PATH="$bootstrap/lib:$bootstrap/compiler/lib"

	with_system_tools build_busybox
	build_make

	# Build and register the boostraped phase 1. CMake
	build_cmake
	export BOOTSTRAP_CMAKE="$bootstrap/cmake/Bootstrap.cmk/cmake"	


	sh etc/cget/cget.sh init --ccache --ldflags "-static" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" \
		-DCMAKE_LINK_SEARCH_START_STATIC=ON -DCMAKE_LINK_SEARCH_END_STATIC=ON \
		-DCMAKE_MAKE_PROGRAM="$bootstrap/bin/make" -DTOOLCHAINS_ROOT="$PWD"

	msg "building libreSSL..."
	# cget.sh needs a full cmake for downloads, so use our bootstrap downloader to populate the cache
	fetch_file libressl
	sh etc/cget/cget.sh install libressl $builddir -DNO_APPS=ON -DTOOLCHAINS_ROOT="$PWD" -G "Unix Makefiles"

	# A fully functional CMake, override the path at the end so the wrapper is disabled
	msg "building CMake (full)..."
	sh etc/cget/cget.sh install cmake $builddir -DBUILD_SHARED_LIBS=OFF -DTOOLCHAINS_ROOT="$PWD" -DBUILD_TESTING=OFF -G "Unix Makefiles"
	rm -rf cmake
	export PATH="$PATH:$PWD/bin"

	#msg "building CCache..."
	#sh etc/cget/cget.sh install ccache -DTOOLCHAINS_ROOT="$PWD" -G "Unix Makefiles"

	msg "building Ninja..."
	sh etc/cget/cget.sh install ninja $builddir -DTOOLCHAINS_ROOT="$PWD" -G "Unix Makefiles"

	# cross-toolchain needs curl, but a simple fake is sufficient for bootstrap
	cp etc/bootstrap/curl.sh bin/curl
	chmod 755 bin/curl

	msg "building native compiler stage 1..."
	sh etc/cget/cget.sh install --no-depends cross-toolchain $builddir -G "Unix Makefiles" \
	   -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX" -DTARGETS="$arch"

	# switch to stage1 compiler, make sure bootstrap compiler cannot be used by accident
	rm -rf compiler	
	for i in gcc g++ ld; do
		echo '#!/bin/sh' > bin/"$i"
		echo "exec \"\$(dirname \"\$0\")/../$arch/bin/$arch-$i\" -static \"\$@\"" >> bin/"$i"
		chmod 755 bin/"$i"
	done

	# provide symlinks for installation of python-related packages
	ln -sf ../../bin/python bin/
	ln -sf ../../lib/python3.9 lib/

	unset CC CXX AR LD CMAKE_BOOTSTRAP_EXEC
	bin/cget init -t "$arch.cmake" --ccache -DCMAKE_BUILD_TYPE=Release
}

# build final toolchain environment using the common build script
stage3() {
	stage "Stage 3: final toolchain environment"
	bootstrap/etc/bootstrap/bootstrap.sh "$arch" .
	bin/cget init -t native-toolchain.cmake --ccache -DCMAKE_BUILD_TYPE=Release
} 


################################################################################
### main script
################################################################################

# make environment more predictable
unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LDLIBS LIBS CPATH C_INCLUDE_PATH \
	  CPLUS_INCLUDE_PATH GCC_EXEC_PREFIX COMPILER_PATH LIBRARY_PATH \
	  DEPENDENCIES_OUTPUT SUNPRO_DEPENDENCIES LC_CTYPE LC_MESSAGES LC_ALL

export LANG=C
export LC_ALL=C
export CGET_CACHE_DIR="$PWD/download-cache"
export CCACHE_CONFIGPATH="$PWD/etc/ccache.conf"
export CCACHE_DIR="$PWD/.cache/ccache"

if [ "$rebuild" = 1 ]; then
	rm -rf bootstrap final
fi
prepare_bootstrap
cd bootstrap
stage1
stage2
cd ..
stage3
if [ -L .cache ]; then
	rm .cache
	mv bootstrap/.cache .
fi
exec bin/rm -rf bootstrap
