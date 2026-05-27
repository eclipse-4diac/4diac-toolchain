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
# Cross-Bootstrap a working stand-alone portable toolchain.
#
# TODO: support for OS X, BSD, other unices (as targets)
#
# This script needs a full native toolchain to operate. initial.sh provides a
# sufficient environment.

set -e
target="$1"
if [ -z "$target" -o -n "${target##*-*-*}" ]; then
	echo "Usage: $0 <host-triple> [<destdir>]" >&2
	exit 1
fi

destdir="${2:-toolchain-$target}"
mkdir -p "$destdir"
destdir="$(cd "$destdir"; pwd)"

cd "$(dirname "$0")/../.."

toolchain="$PWD"
cget() { "${toolchain}/bin/cget" "$@"; }

# build cross-toolchain if it doesn't exist yet
if [ ! -f "$target.cmake" ]; then
	./etc/toolchain.sh "$1"
fi

# prepare target directory
cd "$destdir"
[ ! -d .cache ] && ln -sf "${toolchain}/.cache" .
[ ! -d download-cache ] && ln -sf "${toolchain}/download-cache" .
cp -a "${toolchain}/etc" .

echo "include(\${CMAKE_CURRENT_LIST_DIR}/$target.cmake)" > "${destdir}/native-toolchain.cmake"
echo "set(CMAKE_CROSSCOMPILING OFF)" >> "${destdir}/native-toolchain.cmake"

# initialize cget
if [ "$toolchain" = "$destdir/bootstrap" ]; then
	cget init --ccache -t "${toolchain}/native-toolchain.cmake" -DCMAKE_BUILD_TYPE=MinSizeRel
else
	cget init --ccache -t "${toolchain}/$target.cmake" -DCMAKE_BUILD_TYPE=MinSizeRel
fi

# install native toolchain
if [ -z "${target%%*-apple-*}" ]; then
	cget install clang-macos $builddir
else
	cget install cross-toolchain $builddir -DTARGETS="$target"
fi

mkdir -p bin
if [ -n "${target%%*-apple-*}" ]; then
	# Do not install laziness wrappers on clang-based platforms. If you need them, fix your build recipes.
	for i in gcc g++; do
		echo '#!/bin/sh' > bin/"$i"
		echo "exec \"\$(dirname \"\$0\")/../$target/bin/$target-$i\" -static \"\$@\"" >> bin/"$i"
		chmod 755 bin/"$i"
	done
	for i in ld; do
		echo '#!/bin/sh' > bin/"$i"
		echo "exec \"\$(dirname \"\$0\")/../$target/$target/bin/$i\" -static \"\$@\"" >> bin/"$i"
		chmod 755 bin/"$i"
	done
	for i in gcc-ar; do
		echo '#!/bin/sh' > bin/"$i"
		echo "exec \"\$(dirname \"\$0\")/../$target/bin/$target-$i\" \"\$@\"" >> bin/"$i"
		chmod 755 bin/"$i"
	done
fi

# install cget wrapper
cp etc/cget/wrapper bin/cget
if [ -z "${target#*-w64-mingw32}" ]; then
	"${toolchain}/${target}/bin/${target}-gcc" -municode -o "bin/$1.exe" etc/bootstrap/windows-script-wrap.c -s -lshlwapi
fi

cp "${toolchain}/cross-env.sh" "${toolchain}"/install-crosscompiler.* "${toolchain}"/*.md .

# install remaining build tools
cget install busybox gnumake cmake ninja ccache flex byacc git putty python lzip 7zip remake meson jq $builddir -G Ninja
