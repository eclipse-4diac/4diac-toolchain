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
project(7zip C CXX)

if (WIN32)
  # use the official release for simplicity
  include(toolchain-utils)
  download_extra_source(7zip 7zr.exe https://github.com/ip7z/7zip/releases/download/25.01/7zr.exe
	27cbe3d5804ad09e90bbcaa916da0d5c3b0be9462d0e0fb6cb54be5ed9030875)

  install(PROGRAMS "${SOURCE_7zip}" DESTINATION bin RENAME 7za.exe)
else ()

  set(MAKEFILE_OPTIONS -C CPP/7zip/Bundles/Alone -f ../../cmpl_gcc.mak CFLAGS_WARN_WALL=)
  include(makefile-build)
  install(PROGRAMS CPP/7zip/Bundles/Alone/b/g/7za DESTINATION bin)
endif ()
