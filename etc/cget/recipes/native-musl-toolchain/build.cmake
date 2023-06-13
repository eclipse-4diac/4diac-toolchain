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

PROJECT(native-musl-toolchain C CXX)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

if (NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  message(FATAL_ERROR "\nThis currently only works on Linux hosts, not ${CMAKE_HOST_SYSTEM_NAME}.\n")
endif()

if (CMAKE_CROSSCOMPILING)
  message(FATAL_ERROR "\nThis only works for native builds.\n")
endif()

include(toolchain-utils)

##############################################################
set(MCPU "")
if (CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "arm")
  set(ARCH "arm-linux-musleabi"
	CACHE STRING "Host triple for the machine running this build.")
elseif (CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "x86_64")
  set(ARCH "i686-linux-musl"
	CACHE STRING "Host triple for the machine running this build.")
  set(MCPU "--with-cpu=i686")
else()
  set(ARCH "${CMAKE_HOST_SYSTEM_PROCESSOR}-linux-musl"
	CACHE STRING "Host triple for the machine running this build.")
endif()
##############################################################

# use global cache dir
file(MAKE_DIRECTORY ${CGET_PREFIX}/download-cache)
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${CGET_PREFIX}/download-cache ${CMAKE_CURRENT_SOURCE_DIR}/sources)

##############################################################
# common build configuration

# determine build settings for manual build commands
if (CMAKE_BUILD_TYPE)
  string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
  foreach(prog IN ITEMS C CXX EXE_LINKER)
	  set(CMAKE_${prog}_FLAGS "${CMAKE_${prog}_FLAGS} ${CMAKE_${prog}_FLAGS_${CMAKE_BUILD_TYPE}} ")
  endforeach()
endif()

set(CMAKE_C_COMPILER "${CMAKE_CURRENT_BINARY_DIR}/stage1/bin/${ARCH}-gcc")
set(CMAKE_CXX_COMPILER "${CMAKE_CURRENT_BINARY_DIR}/stage1/bin/${ARCH}-g++")
set(my_C_FLAGS "-O3")
set(my_CXX_FLAGS "-O3")
set(my_EXE_LINKER_FLAGS "--static -static -O3")
set(my_EXE_LINKER_FLAGS_RELEASE "-O3 -s")

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${my_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${my_CXX_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_CXX_FLAGS} ${my_EXE_LINKER_FLAGS_RELEASE} ${my_EXE_LINKER_FLAGS}")

get_property(ccache GLOBAL PROPERTY RULE_LAUNCH_COMPILE)
if (ccache)
  set(ccache "${ccache} ")
endif()

file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/config.mak
  "GCC_VER = 7.2.0\n"
  "COMPILER = CC='${ccache}${CMAKE_C_COMPILER} --static' CXX='${ccache}${CMAKE_CXX_COMPILER} --static'\n"
  "COMMON_CONFIG += CFLAGS='${CMAKE_C_FLAGS}' CXXFLAGS='${CMAKE_CXX_FLAGS}' LDFLAGS='${CMAKE_EXE_LINKER_FLAGS}' $(COMPILER)\n"
  "COMMON_CONFIG += --with-debug-prefix-map=$(CURDIR)= --disable-nls --disable-shared --enable-deterministic-archives\n"
  "GCC_CONFIG += --enable-languages=c,c++ --disable-libquadmath --disable-decimal-float --disable-multilib ${MCPU}\n"
  "DL_CMD = curl -k -o\n"
)

include(ProcessorCount)
ProcessorCount(CPUS)

##############################################################
# build stage1 compiler
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/stage1
  COMMAND sed -e '/sh-protos.h/,/sh_fsca_int2sf/d' -i ${CMAKE_CURRENT_SOURCE_DIR}/patches/gcc-7.2.0/0011-j2.diff
  COMMAND make -j${CPUS} -C ${CMAKE_CURRENT_SOURCE_DIR}
                "COMPILER=CC='${ccache}gcc -static --static' CXX='${ccache}g++ -static --static'"
                TARGET=${ARCH}
                OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/stage1
                install
  COMMAND rm -rf ${CMAKE_CURRENT_SOURCE_DIR}/build)
add_custom_target(toolchain-stage1 DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/stage1)

##############################################################
# build final target
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}
  DEPENDS toolchain-stage1
  COMMAND make -j${CPUS} -C ${CMAKE_CURRENT_SOURCE_DIR}
                TARGET=${ARCH}
                OUTPUT=${CMAKE_CURRENT_BINARY_DIR}/${ARCH}
				install
  COMMAND patch -i ${CGET_RECIPE_DIR}/spi.diff
                ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}/${ARCH}/include/linux/spi/spidev.h
)
add_custom_target(toolchain-${ARCH} ALL DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${ARCH})

install(
  DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}
  DESTINATION .
  USE_SOURCE_PERMISSIONS
  MESSAGE_NEVER)

# wrapper scripts for convenience
file(WRITE gcc "#!/bin/sh\nexec \"\$(dirname \"\$0\")/../${ARCH}/bin/${ARCH}-gcc\" -static --static \"\$@\"\n")
file(WRITE g++ "#!/bin/sh\nexec \"\$(dirname \"\$0\")/../${ARCH}/bin/${ARCH}-g++\" -static --static \"\$@\"\n")
file(WRITE ld "#!/bin/sh\nexec \"\$(dirname \"\$0\")/../${ARCH}/bin/${ARCH}-ld\" -static \"\$@\"\n")

install(PROGRAMS
  ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}/${ARCH}/bin/ar
  ${CMAKE_CURRENT_BINARY_DIR}/${ARCH}/${ARCH}/bin/ranlib
  ${CMAKE_CURRENT_SOURCE_DIR}/gcc
  ${CMAKE_CURRENT_SOURCE_DIR}/g++
  ${CMAKE_CURRENT_SOURCE_DIR}/ld
  DESTINATION bin)


install(FILES ${CGET_RECIPE_DIR}/../cross-toolchain/toolchain.cmake
  DESTINATION . RENAME ${ARCH}.cmake)

file(WRITE native-toolchain.cmake "include(\${CMAKE_CURRENT_LIST_DIR}/${ARCH}.cmake)\nset(CMAKE_CROSSCOMPILING OFF)\n")
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/native-toolchain.cmake DESTINATION .)
