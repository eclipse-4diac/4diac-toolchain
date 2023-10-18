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

PROJECT(CURL C)
cmake_minimum_required(VERSION 2.8)

set(CURL_STATICLIB ON CACHE BOOL "")
set(CURL_DISABLE_LDAP ON CACHE BOOL "")
set(CMAKE_USE_LIBSSH2 OFF CACHE BOOL "")
set(CMAKE_USE_GSSAPI OFF CACHE BOOL "")
set(ENABLE_UNIX_SOCKETS OFF CACHE BOOL "")
set(ENABLE_MANUAL OFF CACHE BOOL "")

# required for cross-compilation (including pseudo-native x32 builds)
set(HAVE_POLL_FINE OFF CACHE BOOL "")
set(HAVE_POSIX_STRERROR_R ON CACHE BOOL "")
set(HAVE_POSIX_STRERROR_R__TRYRUN_OUTPUT "" CACHE STRING "")
set(HAVE_GLIBC_STRERROR_R OFF CACHE BOOL "")
set(HAVE_GLIBC_STRERROR_R__TRYRUN_OUTPUT "" CACHE STRING "")

add_definitions(-DCURL_CA_FALLBACK=1)

if (WIN32)
       add_compile_definitions(_WIN32_WINNT=0x0501)
endif()

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
