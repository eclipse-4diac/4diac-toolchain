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
# remove all build artifacts for rebuilding everything

PATH="$PATH:/usr/bin:/bin"
cd "$(dirname "$0")/../.."
rm -rf cget bootstrap bin lib libexec share doc etc/ssl include *.cmake *.log *-linux-*/ *-w64-*/ *-none-*/
echo cleaning done.
