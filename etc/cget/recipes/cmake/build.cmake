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

PROJECT(CMake C)
cmake_minimum_required(VERSION 3.5)

set(HAVE_POLL_FINE OFF CACHE BOOL "")
set(KWSYS_LFS_WORKS OFF CACHE BOOL "")
set(BUILD_TESTING OFF CACHE BOOL "")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

# evil hack, some compilers need this to link the curltest binary
cmake_policy(SET CMP0079 NEW)
target_link_libraries(cmzlib PUBLIC pthread)

if (WIN32)
	target_link_libraries(CMakeLib PUBLIC ole32 oleaut32)
endif()
