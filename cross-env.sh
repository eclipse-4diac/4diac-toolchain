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
# NOTE: This can be sourced or executed. Execution leads to a more controlled
# environment, while sourcing preserves more of the user's environment
# (especially PATH). Also, sourcing provides convenience functions for cget.
#
# First part is shell, short CMake helper script follows at the end
#[[

if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo "Usage: $0 <arch> [<cmd> ...]"
    echo ""
    echo "Run <cmd> with environment variables set up so that the cross-compiler for"
    echo "<arch> is used. If no <cmd> is given, starts a shell with such an environment."
    echo "Environment variables are the usual autotool-compatible variables (CC, CFLAGS,"
    echo "etc.) plus CMAKE_TOOLCHAIN_FILE, CGET_PREFIX, TOOLCHAIN_ARCH,"
    echo "TOOLCHAIN_PREFIX, TOOLCHAIN_ROOT, and TOOLCHAINS_ROOT."
    echo ""
    echo "Alternate usage: source $0 [<arch>]"
    echo ""
    echo "This will setup the above mentioned environment variables in the current shell."
    echo "Additionally, it provides shell command 'cget_init' to initialize a cget prefix"
    echo "in the current directory. Command 'cross_env' can be used to switch to a"
    echo "different architecture."
    exit 1
fi

if [ -f "${0%/cross-env.sh}/native-toolchain.cmake" ]; then
    export TOOLCHAINS="$(cd "${0%/cross-env.sh}"; pwd)"
else
    for TOOLCHAINS in "$TOOLCHAINS" "${BASH_SOURCE%/cross-env.sh}" "${0%/bin/sh}" "${0%bin/sh.exe}"; do
        [ -f "$TOOLCHAINS/native-toolchain.cmake" ] && break
    done
    if [ ! -f "$TOOLCHAINS/native-toolchain.cmake" ]; then
        echo "Could not detect toolchains directory." >&2
        echo "Sourcing this file works best with the bash shell. For other shells" >&2
        echo "please set the TOOLCHAINS environment variable first." >&2
        return 1
    fi
    TOOLCHAINS="$(cd "$TOOLCHAINS"; pwd)"
    export TOOLCHAINS
    cross_env_sourced=1
fi

cross_env() {
    local IFS=" ()" _ cmd var val

    CMAKE_TOOLCHAIN_FILE="$1"
    
    if [ -f "$CMAKE_TOOLCHAIN_FILE" ]; then
        ARCH="${CMAKE_TOOLCHAIN_FILE##*/}"
        ARCH="${ARCH%.cmake}"
    else
        ARCH="$1"
        # various shorthands
        case "$ARCH" in
            mingw*|win*) ARCH="i686-w64-mingw32";;
            x86_64|i686|aarch64) ARCH="$ARCH-linux-musl";;
            x32) ARCH="x86_64-linux-muslx32";;
            arm|armhf) ARCH="arm-linux-musleabihf";;
            oldarm) ARCH="arm-linux-musleabi";;
            native) ARCH="native-toolchain";;
        esac
        if [ ! -f "$TOOLCHAINS/$ARCH.cmake" ]; then
            echo "Could not find toolchain for architecture '$ARCH'" >&2
            return 1;
        fi
        CMAKE_TOOLCHAIN_FILE="$TOOLCHAINS/$ARCH.cmake"
    fi

    if [ -n "$CROSS_ENV_PATH" ]; then
        # switching from an existing configuration - remove old path prefix
        PATH="${PATH#$CROSS_ENV_PATH:}"
    fi

    # parse CMake toolchain file
    local CMAKE_CURRENT_LIST_DIR="$TOOLCHAINS"
    CGET_PREFIX="$PWD/cget"
    eval "$("$TOOLCHAINS"/bin/cmake -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" -DCGET_PREFIX="$PWD" -P "$0" 2>&1)"
    CFLAGS="$CMAKE_C_FLAGS_INIT"
    CXXFLAGS="$CMAKE_CXX_FLAGS_INIT"
    LDFLAGS="$CMAKE_EXE_LINKER_FLAGS_INIT"
    CC="$CMAKE_C_COMPILER"
    CXX="$CMAKE_CXX_COMPILER"
    LD="$CMAKE_LINKER"
    AR="$CMAKE_AR"
    NM="$CMAKE_NM"
    STRIP="$CMAKE_STRIP"
    OBJCOPY="$CMAKE_OBJCOPY"
    OBJDUMP="$CMAKE_OBJDUMP"

    PATH="$CROSS_ENV_PATH:$PATH"
    export CFLAGS CXXFLAGS LDFLAGS CC CXX LD AR NM STRIP OBJCOPY OBJDUMP
    export CMAKE_TOOLCHAIN_FILE CGET_PREFIX
    export TOOLCHAIN_ARCH TOOLCHAIN_PREFIX TOOLCHAIN_ROOT TOOLCHAINS_ROOT
    echo "Configured compiler toolchain $CMAKE_TOOLCHAIN_FILE"
}
cget() {
    "$TOOLCHAINS/bin/cget" -p "$CGET_PREFIX" "$@"
}
cget_init() {
    if [ "$PWD" != "$CGET_PREFIX" ]; then
        echo "Changing CGet prefix to '$PWD'."
        CGET_PREFIX="$PWD/cget"
        cross_env "$ARCH"
    fi
    cget init -t "$CMAKE_TOOLCHAIN_FILE" --ccache
}

if [ "$cross_env_sourced" ]; then
    unset cross_env_sourced
    echo "Cross-compiler environment loaded. CGet prefix set to '$1'"
    if [ -f "$CGET_PREFIX/cget/cget.cmake" ]; then
        if [ -n "$1" ]; then
            echo "WARNING: this prefix has already been configured." >&2
            echo "         Loading existing configuration instead of '$1'." >&2
        fi
        cross_env "$(sed -e "/^include(\"/{ s/\",*//;s/.*\"//; p; q; }")"
    elif [ -n "$1" ]; then
        cross_env "$1"
        echo "Run 'cget_init' to initialize a new cget prefix."
    else
        echo "Run 'cross_env <arch>' to configure a compiler toolchain."
        echo "After that, optionally run 'cget_init' to initialize a new cget prefix."
    fi
    return 0
fi

echo "_________________________________________________________________________"
echo

cross_env "$1" || exit 1
export PATH="$CROSS_ENV_PATH"

shift

if [ -n "$*" ]; then
    "$@"
    echo "_________________________________________________________________________"
    exit
fi

echo
echo "PATH=$PATH"
echo

echo "Entering toolchains sub-shell"
echo "Enter 'exit' to leave"
echo "_________________________________________________________________________"

export PS1="[toolchains $1] \w> "
exec "$TOOLCHAINS/bin/sh"
exit 1
#]]
# This part is a CMake script that prints the settings of a toolchain file

include(${CMAKE_TOOLCHAIN_FILE})
get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
  message("${_variableName}='${${_variableName}}'")
endforeach()
message("CROSS_ENV_PATH='$ENV{PATH}'")
