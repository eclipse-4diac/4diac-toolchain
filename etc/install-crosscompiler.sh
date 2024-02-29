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
set -e

cd "$(dirname "$0")/.."

hostarch="$(uname -m)" # x86_64
hostplatform="$(uname -s)" # Linux
[ "$hostplatform" = "Windows_NT" ] && hostplatform=Windows
fileprefix="${hostplatform}-cross-${hostarch}_"

mkdir -p .cache
mv "$fileprefix"*.tar.lz .cache 2>/dev/null || true

if [ -z "$*" ]; then
        echo "No toolchain installed. Call $0 <target-arch> to install one. Local cache contains:"
        ls ".cache/$fileprefix"*.tar.lz | sed -e "s,^.cache/$fileprefix,,;s,\\.tar\\.lz\$,,"
        exit 0
fi

for targetarch in "$@"; do
        [ ! -f "$targetarch.cmake" ] || continue
        if [ ! -f ".cache/$fileprefix$targetarch.tar.lz" ]; then
                echo "No locally cached toolchain for $targetarch found. Please download"
                echo "$fileprefix$targetarch.tar.lz from wherever you downloaded this package"
                exit 1
        fi
        echo "Adding toolchain for target $targetarch"
        bin/lzip -d < ".cache/$fileprefix$targetarch.tar.lz" | bin/tar x
done
