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

PROJECT(gawk C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/gawk${CMAKE_EXECUTABLE_SUFFIX} DESTINATION bin)

include(autotools-build)
