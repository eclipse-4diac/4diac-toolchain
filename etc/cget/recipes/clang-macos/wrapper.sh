#!/bin/sh
set -e

root="$(cd $(dirname "$0")/..; pwd)"
base="$(basename "$0")"
bin="$root/bin"

darwin="${base#*-darwin}"; darwin="${darwin%%-*}"

tool="${base#*-darwin$darwin-}"
[ -x "$bin/$tool" ] || tool="llvm-$tool"

arch="${base%%-*}"
[ "$arch" != "aarch64" ] || arch="arm64"
triple="${base%%-darwin$darwin-*}-darwin$darwin"

sdk="$(cd "$root/SDK"; echo *)"
sdkver="${sdk#MacOSX}"; sdkver="${sdkver%.sdk}"

if [ ! -d "$root/SDK/MacOSX$sdkver.sdk" ]; then (
	cd "$root/.."
	sdk_src="$(cat etc/cget/recipes/clang-macos/package.txt)"
	sdk_hash="${sdk_src##*sha256:}"; sdk_hash="${sdk_hash%% *}"
	sdk_file="${sdk_src%% *}"; sdk_file="${sdk_file##*/}"

	cachedir="${CGET_CACHE_DIR:-$PWD/download-cache}"
	downloaddir="${CGET_DOWNLOADS_DIR:-$PWD}"
	mkdir -p "$cachedir"
	sdk_cache="$cachedir/sha256-$sdk_hash"

	[ ! -f "$downloaddir/$sdk_file" ] || { ln "$downloaddir/$sdk_file" "$cachedir/" 2>/dev/null || cp -n "$downloaddir/$sdk_file" "$cachedir/"; }
	[ ! -f "$cachedir/$sdk_file" ] || { mkdir -p "$sdk_cache"; mv "$cachedir/$sdk_file" "$sdk_cache/"; }

	if [ ! -f "$sdk_cache/$sdk_file" ]; then
		echo "ERROR: This toolchain needs $sdk_file, which you must download manually for legal reasons."
		echo "Go to https://github.com/joseluisq/macosx-sdks/ and download the appropriate version"
		echo "and save it to $downloaddir/"
		echo "MAKE SURE THAT YOU AGREE TO THE LICENSE TERMS!"
		sleep 10
		exit 1
	fi >&2

	if [ "$("$root/../bin/sha256sum" < "$sdk_cache/$sdk_file")" != "$sdk_hash  -" ]; then
		mv "$sdk_cache/$sdk_file" "$sdk_cache/$sdk_file.broken"
		echo "SHA256 checksum for $sdk_cache/$sdk_file doesn't match expected value!"
		sleep 10
		exit 1
	fi >&2
	tar xf "$sdk_cache/$sdk_file" -C clang-toolchain/SDK
); fi

clangver="$(cd "$root/lib/clang"; echo *)"

[ -n "$OCDEBUG" ] && set -x

libroot="$root/lib/clang/$clangver"
stdinc="$libroot/include"                    
stdincpp="$libroot/lib/$triple/usr/include/c++/v1"                    

# remove "-static" and "-flto" flags, not supported on macos
set -- "$@" --end-of-argument-list--
while true; do
	arg="$1"
	shift
	case "$arg" in
		--end-of-argument-list--) break;;
		-static | --static | -static-libgcc) continue;;
		-flto | -ffat-lto-objects) continue;;
		--sysroot=*) continue;;
		-nostdinc) stdinc="";;
		-nostdinc++) stdincpp="";;
		-Wl,--start-group | -Wl,--end-group) continue;;
		-Wl,-Map,* | -Wl,--warn-common) continue;;
		-finline-limit=* | -falign-jumps=* | -falign-labels=*) continue;;
	esac
	set -- "$@" "$arg"
done

exec "$bin/$tool" \
	--start-no-unused-arguments \
	-target "$triple" \
	-mlinker-version=134.9 \
	--sysroot="$root/SDK/$sdk" \
	-L "$libroot/lib/$triple/usr/lib" \
	${stdincpp:+-isystem} "$stdincpp" \
	${stdinc:+-isystem} "$stdinc" \
	-mmacosx-version-min="$sdkver.0" \
	-arch "$arch" \
	-fuse-ld=lld \
	-fuse-lipo=llvm-lipo \
	-stdlib=libc++ \
	-nostdinc++ \
	-Wno-implicit-function-declaration \
	--end-no-unused-arguments \
	"$@"
