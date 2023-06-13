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

project(7zip C CXX)
cmake_minimum_required(VERSION 3.5)

if (WIN32)
  # use the official release for simplicity
  include(toolchain-utils)
  download_extra_source(7zip 7za920.zip https://www.7-zip.org/a/7za920.zip
	2a3afe19c180f8373fa02ff00254d5394fec0349f5804e0ad2f6067854ff28ac)
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xf "${SOURCE_7zip}")

  install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/7za.exe DESTINATION bin)
else ()

  set(HAVE_UNICODE_WCHAR 0)
  set(HAVE_PTHREADS 1)

  find_package(Threads)
  add_definitions(-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -DNDEBUG -D_REENTRANT -DENV_UNIX -DBREAK_HANDLER -DUNICODE -D_UNICODE)
  add_compile_options(-Wno-narrowing)

  add_subdirectory(CPP/7zip/CMAKE/7za)
  install(TARGETS 7za DESTINATION bin)
endif ()
