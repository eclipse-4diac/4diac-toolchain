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
#
# Find dynamic libraries for an executable and copy them into the executable's
# directory. Unfortunately, this does not work for the dynamic linker itself.
#
#
# There are three solutions, each with different drawbacks:
#
# * A wrapper executable calls the correct dynamic linker explicitly to load
#   the executable.  Drawback: the process looks a bit weird in 'ps', but
#   otherwise all is well; setuid needs some extra steps.
#
# * You can use the original binary as-is, in the hope that the target system's
#   dynamic linker is compatible. This fails for example on old target OSes.
#
# * You can patch the dynamic linker path in the original binary into a relative
#   path. The drawback is that the binary must be started with its own directory
#   as the working directory, it cannot sensibly be put into $PATH.
#
# This script used to implement the third solution, but recent improvements in the
# dynamic linker now make the first solution work well.
#

[ "$1" = "native-toolchain" ] && exit 0

# initialisation
set -e
toolchains="$(cd "$(dirname "$0")/.."; pwd)"
arch="$1"
toolchain="$toolchains/$arch"
bin="$2"

[ ! -f "$bin.exe" ] || exit 0 # not supported for windows executables
[ -f "$bin" -a -f "$toolchain.cmake" ] || { echo "Usage: $0 <target> <binary>" >&2; exit 1; }
[ -d "$toolchain" ] || toolchain="$toolchains/clang-toolchain"

# find correct tools
bindir="$(cd "$(dirname "$bin")"; pwd)/bundle"
PATH="$toolchains/bin"
objdump="$toolchain/bin/$(ls "$toolchain/bin/" | grep -E 'objdump(\.exe)?$' | head -n 1)"
gcc="$toolchain/bin/$(ls "$toolchain/bin/" | grep 'gcc$' | head -n 1)"

# check applicability
if ! "$objdump" -p "$bin" | grep DYNAMIC >/dev/null; then
	exit 0
fi

# prepare bundling
mkdir -p "$bindir"
mv "$bin" "$bindir"
bin="$bindir/$(basename "$bin")"

# copy all dependencies of a lib/binary
copy_libs() {
	# copy libs
	echo "Checking $1..."
	"$objdump" -p "$1" | while read type lib; do
		[ "$type" = "NEEDED" ] || continue
		[ ! -f "$bindir/$lib" ] || continue
		find "$bindir/../../../lib" -name "$lib" -exec cp {} "$bindir/" ';'
		find "$toolchain/${arch%%-*}-buildroot-${arch#*-}/sysroot" -name "$lib" -exec cp {} "$bindir/" ';'
		copy_libs "$bindir/$lib"
	done
}

# copy binary, required support libraries, and dependencies of manually-installed extra libraries
copy_libs "$bin"
find "$toolchain" -name "libnss_files.so.2" -exec cp {} "$bindir/" ';'
for i in "$bindir"/*.so*; do
	copy_libs "$i"
done

# find dynamic linker and copy it as well
interp="$(strings "$bin" | grep '^/.*/ld' | head -n 1)"
interp="${interp##*/}"
find "$toolchain" -name "$interp" -exec cp {} "$bindir/" ';'


cat << EOF > "$bindir/../forte"
#!/bin/sh
bundle="\$(cd "\$(dirname "\$0")"; pwd)/bundle"
unset LD_PRELOAD
unset LD_LIBRARY_PATH
exec "\$bundle/$interp" --library-path "\$bundle" --inhibit-cache --argv0 "\$0" "\$bundle/forte" "\$@"
EOF
chmod 755 "$bindir/../forte"

echo "-------------------------------------------------------------------------"
echo ""
echo "Bundling of dynamic libraries done. Deploy the 'bundle' subfolder together with 'forte'."
