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

PROJECT(m4 C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

set(AUTOTOOLS_CONFIGURE_OPTIONS
  "--disable-threads"
  "--disable-assert"
  "--disable-nls"
  "--disable-shared")

install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/src/m4${CMAKE_EXECUTABLE_SUFFIX} DESTINATION bin)

include(autotools-build)
