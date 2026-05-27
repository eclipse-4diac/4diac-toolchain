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
project(cross-toolchain C CXX)

include(toolchain-utils)

##############################################################
set(TARGETS
  "arm-linux-musleabihf,--with-cpu=arm1176jzf-s --with-fpu=vfp --with-float=hard"
  "arm-linux-musleabi"
  "arm-none-eabi,--enable-multilib --with-multilib-list=aprofile,rmprofile"
  "aarch64-linux-musl"
  "i686-linux-musl"
  "x86_64-linux-musl"
  "riscv64-linux-musl"
  "riscv32-unknown-elf,--with-arch=rv32i --with-abi=ilp32" # FIXME: this may need to be rv32i_zicsr_zifencei, see https://github.com/riscv-collab/riscv-gnu-toolchain/issues/1315
  "i686-w64-mingw32"
  "x86_64-w64-mingw32"
	CACHE STRING "List of Targets (optionally with comma-separated default CPU) to build cross-compilers for, e.g. i686-w64-mingw32;aarch64-linux-musl;arm-linux-musleabihf,--with-cpu=arm1176jzf-s")
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

set(EXTRA_CFLAGS "")
if (APPLE)
	set(EXTRA_CFLAGS "-Dfdopen=fdopen")
endif()

# create config file
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/config.mak
  "BINUTILS_VER = 2.44\n"
  "GCC_VER = 15.1.0\n"
  "MUSL_VER = 1.2.5\n"
  "GMP_VER = 6.3.0\n"
  "MPC_VER = 1.3.1\n"
  "MPFR_VER = 4.2.2\n"
  "MINGW_VER = v13.0.0\n"
  "LINUX_VER = 6.1.55\n"
  "NEWLIB_VER = 4.5.0.20241231\n"
  "COMMON_CONFIG += CC_FOR_BUILD=\"${BUILDPREFIX}gcc -static\"\n"
  "COMMON_CONFIG += CXX_FOR_BUILD=\"${BUILDPREFIX}g++ -static\"\n"
  "COMMON_CONFIG += CFLAGS_FOR_BUILD=-static\n"
  "COMMON_CONFIG += CXXFLAGS_FOR_BUILD=-static\n"
  "COMMON_CONFIG += AR=\"${CMAKE_AR}\"\n"
  "COMMON_CONFIG += RANLIB=\"${CMAKE_RANLIB}\"\n"
  "COMMON_CONFIG += LDFLAGS_FOR_BUILD=-static\n"
  "COMMON_CONFIG += LD_FOR_BUILD=${BUILDPREFIX2}ld\n"
  "COMMON_CONFIG += AR_FOR_BUILD=${BUILDPREFIX2}ar\n"
  "COMMON_CONFIG += RANLIB_FOR_BUILD=${BUILDPREFIX2}ranlib\n"
  "COMMON_CONFIG += CC='${ccache}${CMAKE_C_COMPILER} -static --static' CXX='${ccache}${CMAKE_CXX_COMPILER} -static --static'\n"
  # LTO doesn't work for cross-building
  "COMMON_CONFIG += CFLAGS='${CMAKE_C_FLAGS} ${EXTRA_CFLAGS} -fno-lto' CXXFLAGS='${CMAKE_CXX_FLAGS} ${EXTRA_CFLAGS} -fno-lto' LDFLAGS='${CMAKE_EXE_LINKER_FLAGS} -fno-lto'\n"
  "COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)= --disable-nls --disable-shared --enable-deterministic-archives\n"
  "COMMON_CONFIG += --disable-gprofng --disable-gcov\n"
  "BINUTILS_CONFIG += --enable-compressed-debug-sections=all --with-zstd host_configargs='ZSTD_CFLAGS=-DHAVE_ZSTD=1 ZSTD_LIBS=-lzstd'\n"
  "GCC_CONFIG += --enable-languages=c,lto,c++ --disable-multilib $(MCPU)\n"
  "GCC_CONFIG += --enable-libatomic --enable-threads=posix --enable-graphite --enable-libstdcxx-filesystem-ts=yes --enable-libstdcxx-backtrace=yes --with-zstd --disable-libstdcxx-pch --disable-lto --disable-win32-registry --disable-symvers --disable-plugin --disable-werror --disable-rpath --with-gnu-as --with-gnu-ld --disable-sjlj-exceptions --with-dwarf2 --enable-large-address-aware\n"
  "DL_CMD = curl -Lk -f --progress-bar -o\n"
  "PATH:=$ENV{PATH}:${CMAKE_CURRENT_SOURCE_DIR}:${TOOLCHAINS_ROOT}/\$(TARGET)/bin:${CMAKE_CURRENT_BINARY_DIR}/\$(TARGET)/bin\n"
)

include(ProcessorCount)
ProcessorCount(CPUS)
# allow limiting the CPU count for debugging
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
file(WRITE "hashes/mingw-w64-v13.0.0.tar.bz2.sha256"
  "5afe822af5c4edbf67daaf45eec61d538f49eef6b19524de64897c6b95828caf  mingw-w64-v13.0.0.tar.bz2\n")
file(WRITE "hashes/newlib-4.5.0.20241231.tar.gz.sha256"
  "33f12605e0054965996c25c1382b3e463b0af91799001f5bb8c0630f2ec8c852  newlib-4.5.0.20241231.tar.gz\n")

# add newlib and mingw patches, then extract sources
# mingw patch is based on https://github.com/jprjr/mingw-cross-make
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/.extracted
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND patch -p 1 -i ${CGET_RECIPE_DIR}/mingw.diff
  # NOTE: the newlib patch has only been tested with ARM targets right now
  COMMAND patch -p 1 -i ${CGET_RECIPE_DIR}/newlib.diff
  COMMAND mkdir patches/musl-1.2.5
  COMMAND cp ${CGET_RECIPE_DIR}/musl-1.2.5-security.patch patches/musl-1.2.5/
  COMMAND mkdir patches/gcc-15.1.0
  COMMAND cp ${CGET_RECIPE_DIR}/gcc-5.4.0-locale.patch patches/gcc-15.1.0/
  # prevent redownloading of files due to too new timestamps
  COMMAND touch -t 200001011200 hashes/*.sha256
  COMMAND make -w -j${CPUS} TARGET=${ARCH} HOST=${HOST}
               OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/${ARCH} extract_all
  # libgomp forces -Werror, but has warnings
  COMMAND sed -i -e 's/-Werror//' gcc-*/libgomp/configure
  # the configure fragment in there messes with library support detection
  COMMAND sed -i -e s/target-libbacktrace// gcc-*.orig/gcc/d/config-lang.in
  COMMAND sed -i -e s/target-libbacktrace// gcc-*.orig/gcc/fortran/config-lang.in
  COMMAND sed -i -e s/target-libbacktrace// gcc-*.orig/gcc/go/config-lang.in
  # gcc misdetects the libgloss subdirectory (riscv64 instead of riscv)
  COMMAND sed -i -e 's/libgloss_dir=arm/libgloss_dir=arm\;\;riscv*-*-*\)libgloss_dir=riscv/' gcc-*/configure
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

  if (CMAKE_CROSSCOMPILING AND NOT EXISTS "${TOOLCHAINS_ROOT}/${ARCH}/bin")
    message(FATAL_ERROR "\n\nMissing ${ARCH} toolchain for cross-compilation.")
  endif()

  if (NOT ARCH MATCHES "darwin")
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/.${ARCH}-installed
    DEPENDS patched-sources
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND make -w -j${CPUS} TARGET=${ARCH} HOST=${HOST}
            OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/${ARCH} MCPU=${MCPU} install
    COMMAND touch .${ARCH}-installed
  )

  # sometimes the executables don't get their platform prefix. fix that.
  add_custom_command(
    OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/.${ARCH}-fixed
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.${ARCH}-installed
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${ARCH}/bin/"
    COMMAND sh -c "for i in *; do case \"\$i\" in *-*-*-*) ;; *) mv \"\$i\" \"${ARCH}-\$i\";; esac; done"
    COMMAND touch .${ARCH}-fixed
    VERBATIM
  )
  add_custom_target(toolchain-${ARCH} ALL DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/.${ARCH}-fixed)

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
  endif()

  install(FILES ${CGET_RECIPE_DIR}/toolchain.cmake
    DESTINATION . RENAME ${ARCH}.cmake)
endforeach()
