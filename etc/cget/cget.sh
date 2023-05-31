#!/bin/sh
#
# This is a shell-only re-implementation of https://github.com/pfultz2/cget .
# Its main difference are improved self-contained portability of cget prefixes
# and better compatibility with unusual systems.
#
# Apart from CMake (obviously), it only needs a basic POSIX shell environment
# (sh, cp, rm, mv, ... -- GNU coreutils or busybox, for example).  Use CMake
# 3.10 or later for best results.  Additionally, it supports ccache through the
# "--ccache" flag during init.
#
# The main difference to cget is that cget.sh does not keep packages in a
# separate cget/pkg/... directory tree, but installs them directly into the
# prefix, which reduces symlink spam and thus improves portability.  Some
# additional changes exist to make statically linked cget prefixes fully
# portable across machines running different OS versions.  For example, when
# using a musl-libc-based toolchain, a Linux cget prefix should work on any
# Linux distribution whatsoever, even on android.

################################################################################
### low-level helper variables/functions
################################################################################

#[[ This is a CMake bracket comment that hides the main shell script from a tiny
#   bit of CMake script at the end.  Do not remove!

set -e

# the default limit can actually be too low in rare cases, so try to increase it
# but continue and hope for the best if that didn't work
ulimit -n 4096 2>/dev/null || true

cgetdir="$(cd "$(dirname "$0")"; pwd)"
exe="$cgetdir/${0##*/}"

die() { set +e; cleanup; trap "" EXIT; echo "
$exe: $*" >&2; exit 1; }
trap 'exit="$?"; set +e; cleanup; [ "$exit" = 0 ] || die "Exiting due to error${pgkname:+ while processing $pkgname}"' EXIT
trap 'set +e; cleanup; exit 1' INT TERM
trap 'set +e; cleanup; exit 1' HUP PIPE IO USR1 USR2 2>/dev/null || true
cleanup() { :; }
msg() { echo "### $*"; }

usage() {
	echo "Usage: $0 [-p <prefix>] {install|remove|list|init|help} [package ...]"
	echo "See https://cget.readthedocs.io for original manual"
	exit 0;
}

[ "$#" = "0" ] && usage

################################################################################
### helper functions
################################################################################

is_windows() { [ "$(uname -s)" = "Windows_NT" ]; }
sha256sum() { cmake -E sha256sum "$@"; }
md5sum() { cmake -E md5sum "$@"; }
extract() { cmake -E tar xf "$@"; }
download() { cmake -Dfile="$1" -DURL="$2" -P "$exe"; }

if is_windows; then
	# on windows, sometimes some filesystem operations keep files locked after the corresponding program exited, so retry a few times.
	workaround_fslock() {
		local count=0
		while [ "$count" -lt 10 ] && ! "$@"; do 
			sleep 1;
			count="$((count+1))"
		done
	}
else
	workaround_fslock() { "$@"; }
fi

compiler_ver() {
	cmake -DCOMPILERVER="$(echo ./CMakeFiles/*.*.*/CMakeCCompiler.cmake)" -P "$exe" 2>&1 | while read line; do
		echo -n "$line";
	done
}

cmake_build() {
	compiler_ver="$(compiler_ver || true)"
	[ -z "$compiler_ver" ] || export CCACHE_COMPILERCHECK="string:$compiler_ver"
	cmake --build . "$@";
}

forbid_separator() {
	[ "${1#*}" = "$1" ] || die "$2 containing '^A' not supported"
}

ensure() {
	for i in "$@"; do
		[ "$mode" != "$i" ] || return 0
	done
	die "Option '$option' only supported on: $@"
}

replace() { # replace varname "foo" "bar"
	eval "while [ -z \"\${$1##*\$2*}\" ]; do $1=\"\${$1%%\$2*}\"\$3\"\${$1#*\$2}\"; done";
}

ensure_toplevel() {
	[ -n "$toplevel" ] || die "Option '$option' only supported on command line"
}

abs() {
	echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

cmake() {
	[ "$VERBOSE" != 1 ] || echo "cmake $*" >&2
	command cmake "$@"
}

init_cmdline() {
	prefix="$PWD/cget"

	package_vars="download mode packages defs generator builddir rebuild
	              nodepend ccache buildscript hash build_clean build_configure
	              build_target recipedir cachedir pkgdir pkgbuilddir prefix
	              VERBOSE hash init_toolchain init_shared init_cxx init_cxxflags
	              init_cflags init_ldflags toplevel pkgname pkg_depends pkg_url"

	for i in $package_vars; do
		unset "$i"
	done

	init_shared="OFF"
	toplevel="1"
}

parse_cmdline() {
	while [ $# != 0 ]; do
		option="$1"
		case "$option" in
			-p|--prefix) ensure_toplevel; prefix="$2"; shift 2;;
			-h|--help) usage;;
			-v|--verbose) export VERBOSE=1; defs="$defs-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON"; shift;; # works best for makefile builds
			-y|--yes) shift;; # we never ask

			-t|--toolchain) ensure init; init_toolchain="$(abs $2)"; shift 2;;
			# -t is also used as install --test, which we don't support
			--shared) ensure init; init_shared="ON"; shift;;
			--static) ensure init; init_shared="OFF"; shift;;
			--cxx) ensure init; init_cxx="$2"; shift 2;;
			--cxxflags) ensure init; init_cxxflags="$2"; shift 2;;
			--cflags) ensure init; init_cflags="$2"; shift 2;;
			--ldflags) ensure init; init_ldflags="$2"; shift 2;;
			--ccache) ensure init; ccache="1"; shift;;

			-f|--file) ensure install; packages="$packages $(while read pkg _; do echo "$pkg"; done < "$2")"; shift 2;;
			-U|--update) ensure install; rebuild=1; shift;;
			--no-depend*) ensure install; nodepend=1; shift;;

			-G|--generator) ensure install build remove; generator="$2"; shift 2;;
			-B|--build-path)
				ensure_toplevel; ensure install build remove;
				mkdir -p "$2";
				builddir="$(abs "$2")";
				shift 2;;
			-X|--cmake)
				ensure install build remove; buildscript="$(abs "$2")"
				[ "$toplevel" ] || buildscript="$(abs "${2##*/*}")";
				shift 2;; # disallow subdirs for security reasons
			-H|--hash) ensure install build remove; hash="$2"; shift 2;;
			--release) ensure install build remove; defs="$defs-DCMAKE_BUILD_TYPE=Release"; shift;;
			--debug) ensure install build remove; defs="$defs-DCMAKE_BUILD_TYPE=Debug"; shift;;

			-c|--configure) ensure build; build_configure=1; shift;;
			-C|--clean) ensure build; build_clean=1; shift;;
			-T|--target) ensure build; build_target="$2"; shift 2;;

			-D*) forbid_separator "$2" Defines; defs="$defs$1"; shift;;
			--define) forbid_separator "$2" Defines; defs="$defs-D$2"; shift 2;;

			-*) die "Unsupported option: $1";;

			install|remove|build|list|init|help)
				ensure_toplevel
				if [ -z "$mode" ]; then
					[ "$1" = "help" ] && usage
					mode="$1"
				else
					packages="$packages $1"
				fi
				shift;;
			*)
				ensure_toplevel
				if [ -z "$mode" ]; then
					die "Unknown command: $1"
				else
					packages="$packages $1"
				fi
				shift;;
		esac
	done

	toplevel=""

	prefix="$(abs "$prefix")"
	prefix="${prefix%/.}"
	prefix="${prefix%/}"
	[ -z "$builddir" ] && builddir="$prefix/cget/build"
	recipedir="$prefix/etc/cget/recipes"
	cachedir="${CGET_CACHE_DIR:-$prefix/download-cache}"
	pkgdir="$prefix/cget/pkg"
}

parse_package() {
	pkgname="${pkgname:-$1}"
	pkg_depends=""
	pkg_url="$1"

	if [ -f "$recipedir/$pkg_url/package.txt" ]; then
		pkgname="$pkg_url"
		cd "$recipedir/$pkg_url"
		read url args < package.txt || true
		parse_package "$url"
		parse_cmdline $args
		unset args url
		[ ! -f requirements.txt ] || pkg_depends="$PWD/requirements.txt"
	elif [ -e "$pkg_url" ]; then
		pkg_url="$(abs "$pkg_url")"
	else
		case "$pkg_url" in
			http://*|https://*|ftp://*) ;;

			*/*/*) die "Unknown package URL: $pkg_url";;

			*/*)
				repo="${pkg_url%%@*}"
				version="${pkg_url#"$repo"}"
				version="${version#@}"
				pkg_url="https://github.com/$repo/archive/${version:-master}.tar.gz"
				unset repo version;;

			*@*)
				repo="${pkg_url%%@*}"
				version="${pkg_url#"$repo"}"
				version="${version#@}"
				repo="$repo/$repo"
				pkg_url="https://github.com/$repo/archive/${version:-master}.tar.gz"
				unset repo version;;

			*) die "Unknown package: $pkg_url";;
		esac
	fi

	replace pkgname "[ /:]" __
	pkgbuilddir="$builddir/$pkgname"
}

process_package() {
	for i in $package_vars; do
		eval "local $i=\"\$$i\""
	done

	parse_package "$1"
	"$2"
}

install_depends() {
	[ -z "$nodepend" ] || return 0
	[ -n "$pkg_depends" ] || return 0

	mydefs="$defs"
	set --
	while [ -n "$mydefs" ]; do
		mydefs="${mydefs#}"
		mydef="${mydefs%%*}"
		[ -z "$mydef" ] || set -- "$@" "$mydef"
		mydefs="${mydefs#"$mydef"}"
	done

	while read pkg _; do
		msg "Checking dependency $pkg..."
		sh "$exe" ${VERBOSE:+-v} -p "$prefix" install "$pkg" -B "$builddir" -G "$generator" "$@"
	done < "$pkg_depends"
}

fetch_file() {
	checksum="${2%%:*}"
	download="$cachedir/$checksum-${2#"$checksum":}/$1"

	if [ -z "${2#$checksum:}" -o ! -f "$download" ]; then
		mkdir -p "${download%/*}"
		msg "Downloading $3..."
		rm -f "$download"
		download "$download" "$3"
	fi

	if [ ! -s "$download" ]; then
		rm "$download"
		die "Download of $1 failed.  Please try again later."
	fi

	if [ -n "$2" -a "$(${checksum}sum "$download")" != "${2#$checksum:}  $download" ]; then
		sum="$(${checksum}sum "$download")"
		mv "$download" "$download.broken"
		die "$checksum checksum for $1 doesn't match.
    Expected: ${2#*:}
    Got: ${sum%% *}"
	fi
}

locks=""
lock() {
	forbid_separator "$1" "Package names"
	[ "${locks##*}" != "$1.cget_lock" ] || return 0

	retries=0
	oldlocks="$locks"
	locks="$locks$1.cget_lock"
	while ! mkdir "$1.cget_lock"; do
		locks="$oldlocks"
		sleep 1
		retries=$((retries+1))
		[ "$retries" != 10 ] || die "Could not lock $1"
		locks="$locks$1.cget_lock"
	done
}

unlock() {
	[ "${locks##*}" = "$1.cget_lock" ] || die "Invalid unlock for $1: $locks"
	rmdir "$1.cget_lock" || die "Lock $1 vanished!?"
	locks="${locks%"$1.cget_lock"}"
}

need_cleanup=""
prepare_source() {
	mkdir -p "$pkgbuilddir/tmp"

	if [ ! -d "$pkg_url" ]; then
		fetch_file "${pkg_url##*/}" "$hash" "$pkg_url"

		msg "Extracting ${pkg_url##*/}..."
		cd "$pkgbuilddir/tmp"
		extract "$download"
		cd ..

		if [ -d "$(echo tmp/*)" ]; then
			workaround_fslock mv tmp/* src
			rmdir tmp
		else
			workaround_fslock mv tmp src
		fi
		pkg_url="$PWD/src"
	fi
	prepare_build_script
}

prepare_build_script() {
	# When building directly from an existing source directory (instead of a
	# source code archive just extracted), we may need to modify the source
	# directory.  This creates problems with concurrent builds from that source
	# directory (into different cget prefixes -- same prefix is useless and
	# unsupported).
	need_cleanup=""
	if [ -n "$buildscript" ]; then
		[ -f "$buildscript" ] || die "Build script does not exist: $buildscript"

		lock "${pkg_url%/}"
		if [ -f "$pkg_url/CMakeLists.txt" ]; then
			need_cleanup=2
			[ ! -e "$pkg_url/__cget_sh_CMakeLists.txt" ] || mv "$pkg_url/__cget_sh_CMakeLists.txt" "$pkg_url/CMakeLists.txt"
			mv -n "$pkg_url/CMakeLists.txt" "$pkg_url/__cget_sh_CMakeLists.txt"
			cp "$buildscript" "$pkg_url/CMakeLists.txt"
			defs="$defs-DCGET_CMAKE_ORIGINAL_SOURCE_FILE=$pkg_url/__cget_sh_CMakeLists.txt"
		else
			need_cleanup=1
			cp "$buildscript" "$pkg_url/CMakeLists.txt"
		fi
	fi
}

cleanup_build_script() {
	if [ -n "$need_cleanup" -a -n "$pkg_url" ]; then
		if [ "$need_cleanup" = 1 ]; then
			rm -f "$pkg_url/CMakeLists.txt"
		else
			mv "$pkg_url/__cget_sh_CMakeLists.txt" "$pkg_url/CMakeLists.txt"
		fi
		need_cleanup=""
		unlock "${pkg_url%/}"
	fi
}

cleanup_build() {
	if is_windows; then
		[ ! -d "$1" ] || ( # busybox cannot delete some files it creates on Windows (symlinks)
			cd "$(dirname "$1")"
			cmd /c "rd /s /q $(basename "$1")"
		)
	else
		[ -n "$CGET_KEEP_BUILD" ] || rm -rf "$1"
	fi
}

cleanup() {
	cleanup_build_script
	while [ -n "$locks" ]; do
		locks="${locks#}"
		lock="${locks%%*}"
		rmdir "$lock"
		locks="${locks#"$lock"}"
	done
}

################################################################################
### top-level operating modes
################################################################################

install() {
	[ -f "$pkgdir/$pkgname/install_manifest.txt" -a -z "$rebuild" ] && return

	msg "Adding $pkgname..."
	install_depends

	build_clean=1
	build

	msg "Installing $pkgname..."
	cd "$pkgbuilddir/build"
	prepare_build_script
	cmake -P cmake_install.cmake || return 1
	cleanup_build_script

	echo >> install_manifest.txt # file is missing trailing newline

	mkdir -p "$pkgdir/$pkgname"
	while read file; do
		echo "${file#"$prefix/"}"
	done < install_manifest.txt > "$pkgdir/$pkgname/install_manifest.txt"

	cd "$prefix"
	cleanup_build "$pkgbuilddir"
}

build() {
	msg "Building $pkgname..."

	cd "$prefix"
	[ -z "$build_clean" ] || cleanup_build "$pkgbuilddir"

	prepare_source

	mkdir -p "$pkgbuilddir/build"
	cd "$pkgbuilddir/build"
	msg "Entering '$PWD', source dir '$pkg_url'"

	if [ ! -f CMakeCache.txt -o -n "$build_configure" ]; then
		set --
		while [ -n "$defs" ]; do
			  defs="${defs#}"
			  def="${defs%%*}"
			  [ -z "$def" ] || set -- "$@" "$def"
			  defs="${defs#"$def"}"
		done
		if ! cmake "$pkg_url" -DCMAKE_INSTALL_PREFIX="$prefix" "$@" \
			-DCMAKE_TOOLCHAIN_FILE="$prefix/cget/cget.cmake" \
			-G "${generator:-Unix Makefiles}" \
			-DCGET_PREFIX:STRING="$prefix"; then
			rm CMakeCache.txt
			return 1
		fi
	fi
	cmake_build ${build_target:+--target "$build_target"}

	cleanup_build_script
}

remove() {
	cd "$prefix"

	while read file; do
		rm -f "$prefix/$file"
	done < "$pkgdir/$pkgname/install_manifest.txt"
	rm "$pkgdir/$pkgname/install_manifest.txt"
	rmdir "$pkgdir/$pkgname"
}

init() {
	mkdir -p "$pkgdir"

	toolchain=''
	if [ -n "$init_toolchain" ]; then
		[ -z "${init_toolchain##"$prefix"/*}" ] && init_toolchain="\${CGET_PREFIX}${init_toolchain#"$prefix"}"
		toolchain="include(\"$init_toolchain\")"
	fi

	{
		cat << EOF
set(CGET_PREFIX "\${CMAKE_CURRENT_LIST_DIR}")
string(REGEX REPLACE "/cget\\\$" "" CGET_PREFIX "\${CGET_PREFIX}")
set(CMAKE_SYSTEM_PREFIX_PATH "\${CGET_PREFIX}")
$toolchain
list(APPEND CMAKE_FIND_ROOT_PATH "\${CGET_PREFIX}")
set(CMAKE_MODULE_PATH "\${TOOLCHAINS_ROOT}/etc/cget/cmake")
set(CMAKE_INSTALL_PREFIX "\${CGET_PREFIX}" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-L\${CGET_PREFIX}/lib \${CMAKE_EXE_LINKER_FLAGS_INIT}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-L\${CGET_PREFIX}/lib \${CMAKE_SHARED_LINKER_FLAGS_INIT}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "-L\${CGET_PREFIX}/lib \${CMAKE_MODULE_LINKER_FLAGS_INIT}")
set(CMAKE_C_FLAGS_INIT "-I\${CGET_PREFIX}/include \${CMAKE_C_FLAGS_INIT}")
set(CMAKE_CXX_FLAGS_INIT "-I\${CGET_PREFIX}/include \${CMAKE_CXX_FLAGS_INIT}")
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(CMAKE_CXX_ENABLE_PARALLEL_BUILD_FLAG "/MP")
endif()
set(BUILD_SHARED_LIBS $init_shared CACHE BOOL "")
if (BUILD_SHARED_LIBS)
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS "ON" CACHE BOOL "")
endif()
EOF
		set --
		while [ -n "$defs" ]; do
			  defs="${defs#}"
			  def="${defs%%*}"
			  [ -z "$def" ] || set -- "$@" "$def"
			  defs="${defs#"$def"}"
		done
		for def in "$@"; do
			name="${def%%=*}"
			name="${name%:*}"
			type="${def#"$name"}"
			type="${type#:}"
			type="${type%%=*}"
			name="${name#-D}"
			value="${def#*=}"
			[ "${type:-STRING}" = "STRING" ] && value="\"$value\""
			echo "set($name $value CACHE ${type:-STRING} \"predefined by cget\")"
		done
		[ -n "$init_cxx" ] && echo "set(CMAKE_CXX_COMPILER \"$init_cxx\")"
		[ -n "$init_cxxflags" ] && echo "set(CMAKE_CXX_FLAGS_INIT \"\${CMAKE_CXX_FLAGS_INIT} $init_cxxflags\")"
		[ -n "$init_cflags" ] && echo "set(CMAKE_C_FLAGS_INIT \"\${CMAKE_C_FLAGS_INIT} $init_cflags\")"
		if [ -n "$init_ldflags" ]; then
			echo "set(CMAKE_SHARED_LINKER_FLAGS_INIT \"\${CMAKE_SHARED_LINKER_FLAGS_INIT} $init_ldflags\")"
			echo "set(CMAKE_MODULE_LINKER_FLAGS_INIT \"\${CMAKE_MODULE_LINKER_FLAGS_INIT} $init_ldflags\")"
			echo "set(CMAKE_EXE_LINKER_FLAGS_INIT \"\${CMAKE_EXE_LINKER_FLAGS_INIT} $init_ldflags\")"
		fi
		if [ -n "$ccache" ]; then
			echo 'find_program(CCACHE ccache)'
			echo 'if (CCACHE)'
			echo '  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE}")'
			echo 'endif()'
		fi
	} > "$prefix/cget/cget.cmake"

}

################################################################################
### main script
################################################################################

unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS LDLIBS LIBS CPATH C_INCLUDE_PATH \
	  CPLUS_INCLUDE_PATH GCC_EXEC_PREFIX COMPILER_PATH LIBRARY_PATH \
	  DEPENDENCIES_OUTPUT SUNPRO_DEPENDENCIES LC_CTYPE LC_MESSAGES LC_ALL

export SOURCE_DATE_EPOCH=0
export LANG=C
export LC_ALL=C

if [ -z "$CMAKE_BUILD_PARALLEL_LEVEL" ]; then
	if is_windows; then
		export CMAKE_BUILD_PARALLEL_LEVEL="$NUMBER_OF_PROCESSORS"
	else
		export CMAKE_BUILD_PARALLEL_LEVEL="$(grep -c '^processor[^a-z]*:' /proc/cpuinfo)"
	fi
fi
[ "${CMAKE_BUILD_PARALLEL_LEVEL:-0}" -gt 0 ] || CMAKE_BUILD_PARALLEL_LEVEL=1

init_cmdline
parse_cmdline "$@"
case "$mode" in
	install|remove|build)
		startdir="$PWD"
		mkdir -p "$builddir"
		for toplevel_pkg in $packages; do
			lock "$builddir/$toplevel_pkg"
			cd "$startdir"
			process_package "$toplevel_pkg" $mode
			unlock "$builddir/$toplevel_pkg"
		done;;
	list) cd "$pkgdir"; ls -1;;
	init) init;;
esac

# exit shell part, because CMake code follows
exit "$?"
# end of CMake bracket comment started at the top ]]

################################################################################
### CMake helper functions
################################################################################
if (URL)
   # we can afford to skip TLS verification, since we have strong checksums for
   # everything
  file(DOWNLOAD "${URL}" "${file}" TLS_VERIFY OFF)
else()
  include(${COMPILERVER})
  execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -v)
  execute_process(COMMAND "${CMAKE_C_COMPILER}" -v)
endif()
