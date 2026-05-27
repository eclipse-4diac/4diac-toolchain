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
project(glibc-cross-toolchain NONE)

include(toolchain-utils)

##############################################################
set(TARGETS "x86_64-linux-gnu;arm-linux-gnueabihf;aarch64-linux-gnu"
  CACHE STRING "Targets to download compilers for, e.g. x86_64-linux-gnu;arm-linux-gnueabihf")

if (WIN32 OR APPLE)
  message(FATAL_ERROR "\n\n===========================================================================\n"
    "glibc-cross-toolchains are currently not supported on Windows or Apple\n"
    "===========================================================================\n\n")
endif()
##############################################################

# use global cache dir
set(cache_dir "${CGET_PREFIX}/download-cache")

# download pre-built toolchains
set(bootlin_version "bleeding-edge-2025.08-1")
macro(add_prebuilt_toolchain triple target hash)
  list(FIND TARGETS "${triple}" index)
  if (index GREATER_EQUAL 0)
    download_extra_source(${triple}
      "${target}--glibc--${bootlin_version}.tar.xz"
      "https://toolchains.bootlin.com/downloads/releases/toolchains/${target}/tarballs/${target}--glibc--${bootlin_version}.tar.xz"
      "${hash}")
  endif()
endmacro()

add_prebuilt_toolchain("x86_64-linux-gnu" "x86-64-core-i7"
  "3777ad89e6d60bc8fafb83b6b74284b6c56aee20ea00e51dfa466800e98dcdb9")
add_prebuilt_toolchain("arm-linux-gnueabihf" "armv7-eabihf"
  "eed0e672d305ac08d444685b48eafb291c63387ef7916c1615354ebfb3d1ebdc")
add_prebuilt_toolchain("aarch64-linux-gnu" "aarch64"
  "54875d12829a792b8d4d1c9fb1f736afc60f514b0d260616f188eafafaac7cb5")

# extract downloaded toolchains and generate toolchain file
foreach (ARCH IN LISTS TARGETS)
  set(file "${SOURCE_${ARCH}}")
  string(REGEX REPLACE "-.*" "" CPU ${ARCH})
  string(REGEX REPLACE "_" "-" PREFIX ${CPU})

  add_custom_command(
	  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}
	  DEPENDS ${file}
	  COMMAND ${CMAKE_COMMAND} -E tar xf "${file}"
	  COMMAND ${CMAKE_COMMAND} -E rename ${PREFIX}*--glibc--* ${ARCH}
	)
  add_custom_target(toolchain-${ARCH} ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${ARCH})
  install(
	  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}
	  DESTINATION .
	  USE_SOURCE_PERMISSIONS
	  MESSAGE_NEVER
	  PATTERN .install EXCLUDE
	  PATTERN ..install.cmd EXCLUDE
	  PATTERN bison EXCLUDE
    )

  install(FILES ${CGET_RECIPE_DIR}/../cross-toolchain/toolchain.cmake
    DESTINATION . RENAME ${ARCH}.cmake)
endforeach()
