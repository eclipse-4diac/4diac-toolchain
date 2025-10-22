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
project(python C)

include(toolchain-utils)
set(pymainver "3.12")
set(pyver "3.12.12")
set(PYTHON_VERSION ${pyver} CACHE STRING "" FORCE)

# use our cached download system
add_source(../Python-${pyver} Python-${pyver}.tgz
  https://www.python.org/ftp/python/${pyver}/Python-${pyver}.tgz
  487c908ddf4097a1b9ba859f25fe46d22ccaabfb335880faac305ac62bffb79b)

if (CMAKE_CROSSCOMPILING)
  patch(cmake/python/CMakeLists.txt "\nif\\(UNIX\\)" "\nif(FALSE)")
  patch(cmake/libpython/CMakeLists.txt "add_executable\\(_freeze_importlib" "#[[")
  patch(cmake/libpython/CMakeLists.txt "add_executable\\(_bootstrap_python" "#[[")
  patch(cmake/libpython/CMakeLists.txt "_freeze_importlib" "\${TOOLCHAINS_ROOT}/lib/python${pymainver}/buildtools/_freeze_importlib")
  patch(cmake/libpython/CMakeLists.txt "_bootstrap_python" "\${TOOLCHAINS_ROOT}/lib/python${pymainver}/buildtools/_bootstrap_python")
  patch(cmake/libpython/CMakeLists.txt "Py_NO_ENABLE_SHARED\n\\)" "Py_NO_ENABLE_SHARED\n)\n#]]")
endif ()

if (WIN32)
  add_compile_options(-D_WIN32_WINNT=0x0601 -DNTDDI_VERSION=0x06010000)
  add_compile_options(-D_PYTHONFRAMEWORK="" -DPLATLIBDIR="lib")
  # not supported by mingw
  file(REMOVE ../Python-${pyver}/PC/_findvs.cpp)
  # not supported by libressl
  patch(cmake/extensions/CMakeLists.txt "list.APPEND _ssl_SOURCES .*/openssl/applink.c." "")
  patch(cmake/extensions/CMakeLists.txt "msvcrt REQUIRES MSVC" "msvcrt REQUIRES WIN32" "")
  # case-sensitivty
  patch(cmake/extensions/CMakeLists.txt "Crypt32" "crypt32")
  patch(../Python-${pyver}/Modules/socketmodule.h "MSTcpIP.h" "mstcpip.h")
  patch(../Python-${pyver}/Modules/socketmodule.c "VersionHelpers.h" "versionhelpers.h")
  patch(../Python-${pyver}/Modules/socketmodule.c "IPPROTO enum,[^#]*#ifdef MS_WINDOWS" "*/
    #if 0")
  patch(../Python-${pyver}/PC/getpathp.c "Shlwapi.h" "shlwapi.h")
  patch(../Python-${pyver}/PC/_testconsole.c "\\\\modules\\\\_io\\\\" "/Modules/_io/")
  patch(../Python-${pyver}/PC/_testconsole.c "clinic\\\\" "clinic/")
  # symbol clash
  patch(../Python-${pyver}/Modules/expat/xmlparse.c "([^_])PREFIX" "\\1xPREFIX")
  # python is confused which threading api to use
  patch(../Python-${pyver}/Python/thread.c "_POSIX_THREADS" "NOT_POSIX_THREADS")
  # unimplemented in wine, but required during build -- force the fallback implementation
  patch(../Python-${pyver}/PC/getpathp.c "api-ms-win-core-path-l1-1-0.dll" "nonexisting.dll")
  # fix posix module not being aware of mingw (yes, it is supposed to be available on Win32)
  # TODO: check if there is anything in here that below minimal fix misses
  #execute_process(COMMAND patch -p0 -i ${CMAKE_CURRENT_SOURCE_DIR}/cmake/patches-win32/03-mingw32.patch
  #  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../Python-${pyver})
  patch(../Python-${pyver}/Modules/posixmodule.c "#include \"Python.h\"" "
#define _MSC_VER 1
#include \"Python.h\"
#include \"osdefs.h\"
#")
  # Python executes itself during the build...
  set(CMAKE_CROSSCOMPILING_EMULATOR env WINEPREFIX=${CMAKE_CURRENT_BINARY_DIR}/.wine /usr/bin/wine)
endif()

set(DOWNLOAD_SOURCES OFF CACHE BOOL "" FORCE)

# static linking
set(BUILD_LIBPYTHON_SHARED OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(BUILD_EXTENSIONS_AS_BUILTIN ON CACHE BOOL "" FORCE)
set(WITH_STATIC_DEPENDENCIES ON CACHE BOOL "" FORCE)

if (APPLE)
	set(CMAKE_OSX_SDK "macosx11.1" CACHE STRING "" FORCE)
	set(CMAKE_OSX_SYSROOT "${TOOLCHAIN_ROOT}/SDK/MacOSX11.1.sdk" CACHE STRING "" FORCE)
	set(CMAKE_OSX_DEPLOYMENT_TARGET "11.1" CACHE STRING "" FORCE)
	set(WITH_STATIC_DEPENDENCIES OFF CACHE BOOL "" FORCE)

	link_libraries("-framework CoreFoundation")
	patch(cmake/python/CMakeLists.txt "if.UNIX AND PY_VERSION VERSION_GREATER \"2.7.4\"." "if(FALSE)")
	patch(cmake/libpython/CMakeLists.txt "\nif.IS_PY3." "\nif(FALSE)")
endif()

# feature minimizing
set(INSTALL_DEVELOPMENT OFF CACHE BOOL "" FORCE)
set(INSTALL_MANUAL OFF CACHE BOOL "" FORCE)
set(INSTALL_TEST OFF CACHE BOOL "" FORCE)
set(USE_SYSTEM_LIBRARIES ON CACHE BOOL "" FORCE)
set(WITH_DOC_STRINGS OFF CACHE BOOL "" FORCE)

# disable extensions with compile errors; _ctypes is quite a loss, but it would
# result in loading glibc-based libs, and that would not work anyway
set(ENABLE_CTYPES OFF CACHE BOOL "" FORCE)
set(ENABLE_DECIMAL OFF CACHE BOOL "" FORCE)
set(ENABLE_OVERLAPPED OFF CACHE BOOL "" FORCE)
set(ENABLE_FINDVS OFF CACHE BOOL "" FORCE)
set(ENABLE_TESTINTERNALCAPI OFF CACHE BOOL "" FORCE)
# disable loading of _ctypes, but keep the ctypes module for compatibility
# (e.g. setuptools imports it without using it)
file(WRITE ../Python-${pyver}/Lib/ctypes/__init__.py "\n")

# external dependencies
set(OPENSSL_INCLUDE_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE STRING "" FORCE)
set(OPENSSL_LIBRARIES "${CMAKE_INSTALL_PREFIX}/lib" CACHE STRING "" FORCE)
add_compile_options(-DHAVE_X509_VERIFY_PARAM_SET1_HOST)
set(ZLIB_LIBRARY "${CMAKE_INSTALL_PREFIX}/lib/libz.a" CACHE STRING "" FORCE)
set(ZLIB_INCLUDE_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE STRING "" FORCE)

# cross-compiling config
include(TestBigEndian)
test_big_endian(DOUBLE_IS_BIG_ENDIAN_IEEE754)
set(DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754 OFF CACHE BOOL "")
set(DOUBLE_IS_LITTLE_ENDIAN_IEEE754 OFF CACHE BOOL "")
if (NOT DOUBLE_IS_BIG_ENDIAN_IEEE754)
  set(DOUBLE_IS_LITTLE_ENDIAN_IEEE754 ON CACHE BOOL "")
endif()
set(HAVE_BROKEN_POLL_EXITCODE 0 CACHE STRING "")
set(HAVE_BROKEN_POLL_EXITCODE__TRYRUN_OUTPUT "" CACHE STRING "")
set(HAVE_BROKEN_MBSTOWCS OFF CACHE BOOL "")
set(HAVE_GLIBC_MEMMOVE_BUG OFF CACHE BOOL "")
set(HAVE_LONG_LONG_FORMAT ON CACHE BOOL "")
set(HAVE_SIZE_T_FORMAT ON CACHE BOOL "")
# - safe settings with no functional difference
set(X87_DOUBLE_ROUNDING ON CACHE BOOL "")
set(HAVE_BROKEN_NICE_EXITCODE 1 CACHE STRING "")
set(HAVE_BROKEN_NICE_EXITCODE__TRYRUN_OUTPUT "" CACHE STRING "")
set(HAVE_ALIGNED_REQUIRED ON CACHE BOOL "")
set(HAVE_COMPUTED_GOTOS OFF CACHE BOOL "")
# - portable setting that disable features
set(POSIX_SEMAPHORES_NOT_ENABLED ON CACHE BOOL "")
set(HAVE_WORKING_TZSET OFF CACHE BOOL "")
# - unused but tested
set(PLATFORM_RUN 0 CACHE STRING "")
set(PLATFORM_RUN__TRYRUN_OUTPUT "" CACHE STRING "")
set(HAVE_MMAP_DEV_ZERO_EXITCODE 1 CACHE STRING "")
set(HAVE_MMAP_DEV_ZERO_EXITCODE__TRYRUN_OUTPUT "error" CACHE STRING "")
set(TANH_PRESERVES_ZERO_SIGN OFF CACHE BOOL "")
set(LOG1P_DROPS_ZERO_SIGN OFF CACHE BOOL "")
set(HAVE_BROKEN_SEM_GETVALUE ON CACHE BOOL "")
set(HAVE_IPA_PURE_CONST_BUG OFF CACHE BOOL "")

# libressl compatibility
patch(../Python-${pyver}/Modules/_hashopenssl.c "#define PY_OPENSSL_HAS_SCRYPT 1" "")
patch(../Python-${pyver}/Modules/_hashopenssl.c "if[^\n]*EVP_MD_FLAG_XOF[^\n]*{" "if(0){")
patch(../Python-${pyver}/Modules/_hashopenssl.c "EVPXOFtype" "EVPtype")
patch(../Python-${pyver}/Modules/_ssl.c "OPENSSL_VERSION_NUMBER < 0x30300000L" "0")

if (WIN32)
  add_compile_options(-DSIZEOF_WCHAR_T=2 -DHAVE_UNISTD_H -w -fno-lto)
  # Lowercase the Lib folder so that /etc/package.sh can find all python modules
  patch(__cget_sh_CMakeLists.txt "LIBDIR \"Lib\"" "LIBDIR \"lib/python${pymainver}\"")
else()
  add_compile_options(-DSIZEOF_WCHAR_T=4 -DHAVE_UNISTD_H -w)
endif()

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

if (WIN32)
  cmake_policy(SET CMP0079 NEW)
  target_link_libraries(python -municode)
endif()

if (NOT CMAKE_CROSSCOMPILING)
  target_compile_options(_freeze_importlib PRIVATE -fno-lto)
  target_compile_options(_bootstrap_python PRIVATE -fno-lto)
  install(TARGETS _freeze_importlib DESTINATION lib/python${pymainver}/buildtools)
  install(TARGETS _bootstrap_python DESTINATION lib/python${pymainver}/buildtools)
endif ()
