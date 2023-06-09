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
# bootstrap everything from scratch, building a Linux and Windows toolchain
# with a wide range of cross-compilers.

set -e
cd "$(dirname "$0")/../.."
./etc/bootstrap/clean.sh
{
	./etc/bootstrap/initial.sh
	./etc/toolchain.sh
	./etc/bootstrap/bootstrap.sh x86_64-w64-mingw32
	./toolchain-x86_64-w64-mingw32/etc/toolchain.sh
} 2>&1 | tee bootstrap-everything.log
