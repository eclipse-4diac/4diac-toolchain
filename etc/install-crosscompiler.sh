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

mkdir -p .cache
for i in *.tar.lz; do
        [ -f "$i" -a ! -d "${i%.tar.lz}" ] || continue
        echo "Adding toolchain package $i"
        bin/lzip -d < "$i" | bin/tar x
        mv "$i" .cache/
done
