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

PROJECT(flex C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

if(MINGW)
	file(MAKE_DIRECTORY sys)
  file(WRITE sys/wait.h [=[
#define wait(x) -1
#define WIFEXITED(x) 1
#define WEXITSTATUS(x) 1
#define pipe(x) -1
#define fork() -1
#define fopen(x, y) fopen(x, y "b")
#include <stdint.h>
#define htonl(_val) (((uint16_t)(_val) & 0xff00) >> 8 | ((uint16_t)(_val) & 0xff) << 8)
#define htons(_val) (((uint32_t)(_val) & 0xff000000) >> 24 | \
                      ((uint32_t)(_val) & 0x00ff0000) >>  8 | \
                      ((uint32_t)(_val) & 0x0000ff00) <<  8 | \
                      ((uint32_t)(_val) & 0x000000ff) << 24 )

]=])
endif()

# needed when cross-compiling
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib)

set(AUTOTOOLS_CONFIGURE_OPTIONS
  "--disable-libfl"
  "--disable-bootstrap"
  "--disable-nls"
  "--disable-shared")
set(AUTOTOOLS_C_FLAGS "-I${CMAKE_CURRENT_SOURCE_DIR}")
set(AUTOTOOLS_TARGET "-C" "src")

install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/src/flex${CMAKE_EXECUTABLE_SUFFIX} DESTINATION bin)

include(autotools-build)
