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
project(git C)

include(toolchain-utils)
patch(http.c "curl_easy_setopt\\(result, CURLOPT_CAPATH, ssl_capath\\);"
	"curl_easy_setopt(result, CURLOPT_CAPATH, ssl_capath);\ncurl_easy_setopt(result, CURLOPT_CAINFO, getenv(\"CURL_CA_BUNDLE\"));")

set(MAKEFILE_OPTIONS
	NO_PERL=YesPlease NO_EXPAT=YesPlease NO_GETTEXT=YesPlease NO_TCLTK=YesPlease NO_PYTHON=YesPlease NO_REGEX=NeedsStartEnd NO_SVN_TESTS=YesPlease NO_GITWEB=YesPlease
	V=1 "SANE_TOOL_PATH=${CGET_PREFIX}/bin" "prefix=${CMAKE_CURRENT_BINARY_DIR}/install" RUNTIME_PREFIX=YesPlease INSTALL_STRIP=-s "CC=${CMAKE_C_COMPILER}" "LDFLAGS=${CMAKE_EXE_LINKER_FLAGS}" "AR=${CMAKE_AR}")

# git doesn't detect cross-compilation properly
if (WIN32)
	list(APPEND MAKEFILE_OPTIONS uname_S=MINGW MSYSTEM=MINGW64 USE_LIBPCRE= NO_ICONV=1 "RC=${CMAKE_RC_COMPILER} -O coff")
	file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/compat/win32/pthread.c "")
	file(REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/compat/win32/pthread.h)
elseif (APPLE)
	list(APPEND MAKEFILE_OPTIONS uname_S=Darwin uname_R=20.2 "LDFLAGS=${CMAKE_EXE_LINKER_FLAGS} -framework SystemConfiguration" INSTALL_STRIP=)
else ()
	list(APPEND MAKEFILE_OPTIONS uname_S=Linux)
endif ()

set(MAKEFILE_TARGET install)

include(makefile-build)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/install/. DESTINATION ${CMAKE_INSTALL_PREFIX} USE_SOURCE_PERMISSIONS)
