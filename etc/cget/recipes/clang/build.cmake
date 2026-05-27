#********************************************************************************
# Copyright (c) 2024 OFFIS e.V.
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

cmake_minimum_required(VERSION 3.13)
project(clang-native C CXX)

include(toolchain-utils)
include(${CGET_RECIPE_DIR}/../clang-bootstrap/helpers.cmake)
include(${CGET_RECIPE_DIR}/../clang/llvm-config-options.cmake)

set(LLVM_COMPILER_ARGS
	"CC=${HOST_TOOLCHAIN}/bin/${LLVM_ARCH}-clang"
	"CXX=${HOST_TOOLCHAIN}/bin/${LLVM_ARCH}-clang++"
	"LD=${HOST_TOOLCHAIN}/bin/${LLVM_ARCH}-ld.lld"
	"AR=${HOST_TOOLCHAIN}/bin/llvm-ar"
	"RANLIB=${HOST_TOOLCHAIN}/bin/llvm-ranlib"
	"CFLAGS=-O3 -stdlib=libc++ --start-no-unused-arguments --gcc-toolchain=/nonexistant --end-no-unused-arguments -I ${TARGET_TOOLCHAIN}/${LLVM_SYSROOT}/usr/include"
	"CXXFLAGS=-O3 -stdlib=libc++ --start-no-unused-arguments --gcc-toolchain=/nonexistant --end-no-unused-arguments -I ${TARGET_TOOLCHAIN}/${LLVM_SYSROOT}/usr/include"
	"LDFLAGS=-static -stdlib=libc++ -rtlib=compiler-rt -unwindlib=libunwind --gcc-toolchain=/nonexistant"
)

if (APPLE)
	list(APPEND LLVM_CONFIG_OPTIONS "-DCMAKE_SYSROOT=${CGET_PREFIX}")
endif ()

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stage2)
add_custom_target(clang ALL
	WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/stage2
	COMMAND ${CMD_SET_PATH} ${LLVM_COMPILER_ARGS} ${CMAKE_COMMAND} ${CMAKE_CURRENT_SOURCE_DIR}/llvm ${LLVM_CONFIG_OPTIONS} "-DCMAKE_AR=${HOST_TOOLCHAIN}/bin/llvm-ar" "-DLLVM_ENABLE_PROJECTS=clang;lld" "-DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL_PREFIX}" "-DCMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}"
	COMMAND ${CMD_SET_PATH} ninja clang lld
	COMMAND ${CMD_SET_PATH} cp /dev/null runtimes/cmake_install.cmake
	COMMAND ${CMD_SET_PATH} ninja install
	COMMAND echo ================ clang done ==========
	VERBATIM
)

add_custom_target(fixup ALL
	DEPENDS clang
	WORKING_DIRECTORY ${LLVM_INSTALL_PREFIX}
	COMMAND ${CMD_SET_PATH} sh -c "for i in bin/*; do [ -L \"$i\" ] || bin/llvm-strip -s \"$i\" 2>/dev/null; done"
	COMMAND ${CMD_SET_PATH} sh -c "rm -f lib/*.a"
	COMMAND ${CMD_SET_PATH} rm -rf include share
	COMMAND ${CMD_SET_PATH} rm -rf "${CMAKE_INSTALL_PREFIX}/clang-toolchain/bootstrap"
	COMMAND echo ================ fixup done ==========
	VERBATIM
)
