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

PROJECT(glibc-cross-toolchain NONE)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

include(toolchain-utils)

##############################################################
set(TARGETS "x86_64-linux-gnu;arm-linux-gnueabihf;aarch64-linux-gnu"
  CACHE STRING "Targets to download compilers for, e.g. x86_64-linux-gnu;arm-linux-gnueabihf")

if (WIN32)
  message(FATAL_ERROR "\n\n===========================================================================\n"
    "glibc-cross-toolchains are currently not supported on Windows\n"
    "===========================================================================\n\n")
endif()
##############################################################

# use global cache dir
set(cache_dir "${CGET_PREFIX}/download-cache")

# download pre-built toolchains
set(bootlin_version "stable-2022.08-1")
macro(add_prebuilt_toolchain triple target hash)
  list(FIND TARGETS "${triple}" index)
  if (index GREATER_EQUAL 0)
    download_extra_source(${triple}
      "${target}--glibc--${bootlin_version}.tar.bz2"
      "https://toolchains.bootlin.com/downloads/releases/toolchains/${target}/tarballs/${target}--glibc--${bootlin_version}.tar.bz2"
      "${hash}")
  endif()
endmacro()

add_prebuilt_toolchain("x86_64-linux-gnu" "x86-64-core-i7"
  "7a31f72e6dc378eac8a97b0915b3619ba95c79f73046d052539c44f91bee9a02")
add_prebuilt_toolchain("arm-linux-gnueabihf" "armv7-eabihf"
  "64329b3e72350ceda65997368395a945ef83769013d82414dc5f2021c33f2d44")
add_prebuilt_toolchain("aarch64-linux-gnu" "aarch64"
  "844df3c99508030ee9cb1152cb182500bb9816ff01968f2e18591d51d766c9e7")

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
