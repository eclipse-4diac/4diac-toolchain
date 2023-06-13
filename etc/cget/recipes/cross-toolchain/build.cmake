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

PROJECT(cross-toolchain C CXX)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

include(toolchain-utils)

##############################################################
set(TARGETS
  "arm-linux-musleabihf,--with-cpu=arm1176jzf-s --with-fpu=vfp --with-float=hard"
  "arm-linux-musleabi"
  "arm-none-eabi,--enable-multilib --with-multilib-list=aprofile,rmprofile"
  "aarch64-linux-musl"
  "i686-linux-musl"
  "x86_64-linux-muslx32"
  "x86_64-linux-musl"
  "microblaze-linux-musl"
  "riscv64-linux-musl"
  "i686-w64-mingw32"
  "x86_64-w64-mingw32"
	CACHE STRINGS "List of Targets (optionally with comma-separated default CPU) to build cross-compilers for, e.g. i686-w64-mingw32;aarch64-linux-musl;arm-linux-musleabihf,--with-cpu=arm1176jzf-s")
##############################################################

# use global cache dir
file(MAKE_DIRECTORY ${CGET_PREFIX}/download-cache)

if (CMAKE_HOST_WIN32)
  message(FATAL_ERROR "\n\n===========================================================================\n"
    "This package does not support Windows hosts. Use a Linux system to cross-compile instead\n"
    "===========================================================================\n\n")
endif()

##############################################################
# build configuration
#

message(WARNING "Assuming this is running on a x86_64-linux-musl machine. Builds on other machines are unsupported.")
set(BUILD_ARCH "x86_64-linux-musl")

# use global cache dir
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${CGET_PREFIX}/download-cache ${CMAKE_CURRENT_SOURCE_DIR}/sources)

# determine build settings for manual build commands
get_property(ccache GLOBAL PROPERTY RULE_LAUNCH_COMPILE)
if (ccache)
  set(ccache "${ccache} ")
endif()

if (CMAKE_BUILD_TYPE)
  string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
  foreach(prog IN ITEMS C CXX EXE_LINKER)
    set(CMAKE_${prog}_FLAGS "${CMAKE_${prog}_FLAGS} ${CMAKE_${prog}_FLAGS_${CMAKE_BUILD_TYPE}} ")
  endforeach()
endif()

if (CMAKE_CROSSCOMPILING)
  set(HOST ${TOOLCHAIN_ARCH})
else()
  set(HOST "")
endif()

set(BUILDPREFIX "${TOOLCHAINS_ROOT}/${BUILD_ARCH}/bin/${BUILD_ARCH}-")
set(BUILDPREFIX2 "${TOOLCHAINS_ROOT}/${BUILD_ARCH}/${BUILD_ARCH}/bin/")

# create config file
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/config.mak
  "COMPILER = CC='${ccache}${CMAKE_C_COMPILER} -static --static' CXX='${ccache}${CMAKE_CXX_COMPILER} -static --static'\n"
  "BINUTILS_VER = 2.40\n"
  "GCC_VER = 11.3.0\n"
  "MUSL_VER = 1.2.4\n"
  "GMP_VER = 6.2.1\n"
  "MPC_VER = 1.3.1\n"
  "MPFR_VER = 4.2.0\n"
  "MINGW_VER = v10.0.0\n"
  "LINUX_VER = 6.1.31\n"
  "NEWLIB_VER = 4.1.0\n"
  "COMMON_CONFIG += CC_FOR_BUILD=\"${BUILDPREFIX}gcc -static\"\n"
  "COMMON_CONFIG += CXX_FOR_BUILD=\"${BUILDPREFIX}g++ -static\"\n"
  "COMMON_CONFIG += CFLAGS_FOR_BUILD=-static\n"
  "COMMON_CONFIG += CXXFLAGS_FOR_BUILD=-static\n"
  "COMMON_CONFIG += LDFLAGS_FOR_BUILD=-static\n"
  "COMMON_CONFIG += LD_FOR_BUILD=${BUILDPREFIX2}ld\n"
  "COMMON_CONFIG += AR_FOR_BUILD=${BUILDPREFIX2}ar\n"
  "COMMON_CONFIG += RANLIB_FOR_BUILD=${BUILDPREFIX2}ranlib\n"
  # LTO doesn't work for cross-building
  "COMMON_CONFIG += CFLAGS='${CMAKE_C_FLAGS} -fno-lto' CXXFLAGS='${CMAKE_CXX_FLAGS} -fno-lto' LDFLAGS='${CMAKE_EXE_LINKER_FLAGS} -fno-lto' $(COMPILER)\n"
  "COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)= --disable-nls --disable-shared --enable-deterministic-archives\n"
  # the gprofng tool would add another dependency (bison), but gprofng isn't needed anyway
  "COMMON_CONFIG += --disable-gprofng\n"
  "GCC_CONFIG += --enable-languages=c,lto,c++ --disable-multilib $(MCPU)\n"
  "GCC_CONFIG += --enable-libatomic --enable-threads=posix --enable-graphite --enable-libstdcxx-filesystem-ts=yes --disable-libstdcxx-pch --disable-lto --disable-win32-registry --disable-symvers --disable-plugin --disable-werror --disable-rpath --with-gnu-as --with-gnu-ld --disable-sjlj-exceptions --with-dwarf2 --enable-large-address-aware\n"
  "DL_CMD = curl -Lk -o\n"
  "PATH:=$ENV{PATH}:${CMAKE_CURRENT_SOURCE_DIR}:${TOOLCHAINS_ROOT}/\$(TARGET)/bin\n"
)

include(ProcessorCount)
ProcessorCount(CPUS)
# allow limiting the CPU count; notably, cross-building for windows has some unknown race condition
if(NOT "$ENV{CROSS_TOOLCHAIN_CPUS}" STREQUAL "")
	set(CPUS "$ENV{CROSS_TOOLCHAIN_CPUS}")
endif()

##############################################################
# prepare source (only once)

# recent kernels use rsync to install headers; we provide a poor man's workaround
file(COPY "${CGET_RECIPE_DIR}/rsync" DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}
  USE_SOURCE_PERMISSIONS)
patch("${CMAKE_CURRENT_SOURCE_DIR}/rsync" "#!/bin/sh" "#!${TOOLCHAINS_ROOT}/bin/sh")
patch("${CMAKE_CURRENT_SOURCE_DIR}/Makefile" "http://isl.gforge.inria.fr/" "https://libisl.sourceforge.io/")


# add mingw downloads
file(WRITE "hashes/mingw-w64-v5.0.3.tar.bz2.sha1"
  "96278378b829695007ce6a527278cba19cb829f2  mingw-w64-v5.0.3.tar.bz2\n")
file(WRITE "hashes/mingw-w64-v5.0.4.tar.bz2.sha1"
  "aa854d36acf575307b6b839f7ee12aa97f66af29  mingw-w64-v5.0.4.tar.bz2\n")
file(WRITE "hashes/mingw-w64-v6.0.0.tar.bz2.sha1"
  "4cffb043060d88d6bf0f382e4d92019263670ca6  mingw-w64-v6.0.0.tar.bz2\n")
file(WRITE "hashes/mingw-w64-v7.0.0.tar.bz2.sha1"
  "25940043c4541e3e59608dead9b6f75b5596d606  mingw-w64-v7.0.0.tar.bz2\n")
file(WRITE "hashes/mingw-w64-v8.0.0.tar.bz2.sha1"
  "c733a60e1e651ccd5d1ef1296cdc6f44f41a2cb0  mingw-w64-v8.0.0.tar.bz2\n")
file(WRITE "hashes/mingw-w64-v9.0.0.tar.bz2.sha1"
  "9c496ed063e085888d250cc461ec4d31d97b72f1  mingw-w64-v9.0.0.tar.bz2\n")
file(WRITE "hashes/mingw-w64-v10.0.0.tar.bz2.sha1"
  "56143558d81dae7628a232ca7582b947e65392b1  mingw-w64-v10.0.0.tar.bz2\n")
file(WRITE "hashes/newlib-4.1.0.tar.gz.sha1"
  "3f2536b591598e8e5c36f20f4d969266f81ab1ed  newlib-4.1.0.tar.gz\n")
file(WRITE "hashes/binutils-2.40.tar.gz.sha1"
  "51cf8aac159473418688c62ec52f3653d1b8e0a7  binutils-2.40.tar.gz\n")

# add newlib and mingw patches, then extract sources
# mingw patch is based on https://github.com/jprjr/mingw-cross-make
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/.extracted
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND patch -p 1 -i ${CGET_RECIPE_DIR}/mingw.diff
  # NOTE: the newlib patch has only been tested with ARM targets right now
  COMMAND patch -p 1 -i ${CGET_RECIPE_DIR}/newlib.diff
  # prevent redownloading of files due to too new timestamps
  COMMAND touch -t 200001011200 hashes/*.sha1
  COMMAND make -w -j${CPUS} TARGET=${ARCH} HOST=${HOST}
               OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/${ARCH} extract_all
  # libgomp forces -Werror, but has warnings
  COMMAND sed -i -e 's/-Werror//' gcc-11.3.0/libgomp/configure
  # musl+gcc-11 bug that will be fixed in gcc-12
  COMMAND sed -i -e 's/-std=gnu++17/-std=gnu++17 -nostdinc++/' gcc-11.3.0/libstdc++-v3/src/c++17/Makefile.in
  COMMAND touch .extracted
  )
add_custom_target(patched-sources DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.extracted)


##############################################################
# build multiple targets
foreach (ARCH IN LISTS TARGETS)
  string(REGEX REPLACE "-.*" "" CPU "${ARCH}")
  string(REGEX REPLACE "^[^,]*[^,]" "" MCPU "${ARCH}")
  string(REGEX REPLACE "^," "" MCPU "${MCPU}")
  string(REGEX REPLACE ",.*" "" ARCH "${ARCH}")

  if (ARCH MATCHES "mingw32")
    # recent mingw toolchain versions have a race condition in parallel builds
    set(makecpus 1)
  else()
    set(makecpus ${CPUS})
  endif()
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/.${ARCH}-installed
    DEPENDS patched-sources
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND make -w -j${makecpus} TARGET=${ARCH} HOST=${HOST}
            OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/${ARCH} MCPU=${MCPU} install
    COMMAND touch .${ARCH}-installed
  )
  add_custom_target(toolchain-${ARCH} ALL DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.${ARCH}-installed)

  if (ARCH MATCHES "mingw32")
    # add regex library that is needed for c++11 support, use a temporary cget config
    file(COPY ${CGET_PREFIX}/etc/. DESTINATION ${ARCH}/${ARCH}/etc)
    if (CMAKE_CROSSCOMPILING)
      set(toolchain "${TOOLCHAINS_ROOT}/${ARCH}.cmake")
    else()
      file(COPY ${CGET_RECIPE_DIR}/toolchain.cmake DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
      file(RENAME ${CMAKE_CURRENT_BINARY_DIR}/toolchain.cmake ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}.cmake)
      set(toolchain "${CMAKE_CURRENT_BINARY_DIR}/${ARCH}.cmake")
    endif()
    add_custom_target(regex-${ARCH} ALL
      DEPENDS toolchain-${ARCH}
      COMMAND ${TOOLCHAINS_ROOT}/bin/cget -p ${ARCH}/${ARCH} init -t ${toolchain} -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      # create a dummy libregex which will be overwritten by the real libregex
      COMMAND ${CMAKE_COMMAND} -E copy ${ARCH}/${ARCH}/lib/libm.a ${ARCH}/${ARCH}/lib/libregex.a
      COMMAND ${TOOLCHAINS_ROOT}/bin/cget -p ${ARCH}/${ARCH} install regex -G "Unix Makefiles"
      COMMAND ${CMAKE_COMMAND} -E remove_directory "${ARCH}/${ARCH}/etc"
      COMMAND ${CMAKE_COMMAND} -E remove_directory "${ARCH}/${ARCH}/cget"
    )
  endif()


  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}
    DESTINATION .
    USE_SOURCE_PERMISSIONS
    MESSAGE_NEVER)

  install(FILES ${CGET_RECIPE_DIR}/toolchain.cmake
    DESTINATION . RENAME ${ARCH}.cmake)
endforeach()
