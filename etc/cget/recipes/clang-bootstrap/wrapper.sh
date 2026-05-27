#!/bin/sh
fulltool="$(basename "$0")"
root="$(cd "$(dirname "$0")"/../..; pwd)"
build="$(pwd)"
build="${build#"$root"}"
build="${build#/cget/build/}"
build="${build%%/*}"
target="$(uname -m)-unknown-linux-musl"

tool="${fulltool#*-unknown-linux-musl-}"
prefix="${fulltool%$tool}"
[ -n "$prefix" ] && target="${prefix%-}"
arch="${target%%-*}"

export PATH="$root/cget/build/$build/build/clang-toolchain/bin:$root/clang-toolchain/bin:$root/bin:$arch-linux-musl/bin"

# other llvm tools
[ -n "${tool##clang*}" ] && exec "$root/clang-toolchain/bootstrap/bin/$tool" "$@"

# clang
exec "$root/clang-toolchain/bootstrap/bin/$tool" \
	--start-no-unused-arguments \
	-target "$target" \
       	--gcc-toolchain="$root/$arch-linux-musl" \
       	--sysroot "$root/clang-toolchain/lib/clang"/*/"lib/$target" \
       	-L "$root/clang-toolchain/bootstrap/lib" \
	-fuse-ld=lld \
	-stdlib=libstdc++ \
	-rtlib=libgcc \
	-unwindlib=libgcc \
	--end-no-unused-arguments \
	"$@"

