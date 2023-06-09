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
destdir="${2:-toolchain-$target}"
destdir="$(cd "$(dirname "$destdir")"; pwd)/$(basename "$destdir")"

cd "$(dirname "$0")/../.."

toolchain="$PWD"
cget() { "${toolchain}/bin/cget" "$@"; }

if [ -z "$target" -o -n "${target##*-*-*}" ]; then
	echo "Usage: $0 <host-triple> [<destdir>]" >&2
	exit 1
fi

# build cross-toolchain if it doesn't exist yet
if [ ! -d "$target" -o ! -f "$target.cmake" ]; then
	./etc/toolchain.sh "$1"
fi

# prepare target directory
mkdir -p "$destdir"
cd "$destdir"
[ ! -d .cache ] && ln -sf "${toolchain}/.cache" .
[ ! -d download-cache ] && ln -sf "${toolchain}/download-cache" .
cp -a "${toolchain}/etc" .

# initialize cget
cget init --ccache -t "${toolchain}/$target.cmake" -DCMAKE_BUILD_TYPE=Release

# install native toolchain
cget install cross-toolchain $builddir -DTARGETS="$target"
echo "include(\${CMAKE_CURRENT_LIST_DIR}/$target.cmake)" > native-toolchain.cmake
echo "set(CMAKE_CROSSCOMPILING OFF)" >> native-toolchain.cmake
# The file native-toolchain.cmake is also expected in the bootstrap subdirectory for initial bootstrap scenarios 
[ ! -d bootstrap ] || cp native-toolchain.cmake bootstrap/
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

# install cget wrapper
cp etc/cget/wrapper bin/cget
if [ -z "${target#*-w64-mingw32}" ]; then
	"${toolchain}/${target}/bin/${target}-gcc" -municode -o "bin/$1.exe" etc/bootstrap/windows-script-wrap.c -s -lshlwapi
fi

cp "${toolchain}/cross-env.sh" "${toolchain}/install-toolchain".* "${toolchain}/README.rst" .

# install remaining build tools
cget install busybox gnumake cmake ninja ccache flex byacc git putty python lzip 7zip remake meson patchelf $builddir -G Ninja

# remove useless cmake doc directory
rm -rf doc
