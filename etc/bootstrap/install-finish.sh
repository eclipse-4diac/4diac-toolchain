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

die() { echo "$*" >&2; exit 1; }

triplet="$1"
release="$2"
releasehash="$3"

rm -rf installer 2>/dev/null || true # sometimes fails on win32, ignore it here, will be handled in install.cmd

# Install SDK or message user about SDK installation
[ ! -x "clang-toolchain/bin/$triplet-clang" ] || "clang-toolchain/bin/$triplet-clang" --version

echo "Installation complete. Run ./install-crosscompiler.sh to download additional cross-compiling toolchains."
