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

cd "$(dirname "$0")"

if [ ! -f bin/sh ]; then
    if [ ! -f Linux-toolchain-x86_64-linux-musl.tar.gz ]; then
		echo ""
		echo "======================================================================"
		echo ""
		echo "ERROR: You need a base toolchain archive to install. You should get it"
		echo "wherever you got this file."
		echo "The file you need is called Linux-toolchain-i686-linux-musl.tar.gz"
		echo ""
		echo "======================================================================"
		echo ""
		exit 1
    elif [ -f Windows-toolchain-x64_64-w64-mingw32.zip ]; then
		echo ""
		echo "======================================================================"
		echo ""
		echo "ERROR: Copy the required files (all Linux-* files for example) to an"
		echo "empty folder and run this script again."
		echo ""
		echo "======================================================================"
		echo ""
		exit 1
    fi
    tar xf Linux-toolchain-x86_64-linux-musl.tar.gz --skip-old-files
    mkdir -p .cache
    mv Linux-toolchain-x86_64-linux-musl.tar.gz .cache
fi

./bin/sh ./etc/install-crosscompiler.sh
