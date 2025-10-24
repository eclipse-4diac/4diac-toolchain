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

cmake_minimum_required(VERSION 3.10)
project(m4 C)

include(toolchain-utils)
if (APPLE)
  patch(lib/obstack.c "_Noreturn" "__attribute_noreturn__")
  patch(lib/stdio.in.h "@GNULIB_(FPUTS|PUTS|FPUTC|PUTC|FWRITE|FPRINTF|VFPRINTF|PRINTF)@" "0")
endif()

set(AUTOTOOLS_CONFIGURE_OPTIONS
  "--disable-threads"
  "--disable-assert"
  "--disable-nls"
  "--disable-shared")

install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/src/m4${CMAKE_EXECUTABLE_SUFFIX} DESTINATION bin)

include(autotools-build)
