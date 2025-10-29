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
project(clang-musl C)

include(toolchain-utils)
include(${CGET_RECIPE_DIR}/../clang-bootstrap/helpers.cmake)

execute_process(
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND patch -p 1 -i ${CGET_RECIPE_DIR}/musl-1.2.5-security.patch
  RESULT_VARIABLE RC)
if (${RC} GREATER 0)
	message(FATAL_ERROR "patch failed")
endif()

set(LLVM_COMPILER_ARGS
	"CC=${HOST_TOOLCHAIN}/bin/clang"
	"CXX=${HOST_TOOLCHAIN}/bin/clang++"
	"LD=${HOST_TOOLCHAIN}/bin/ld.lld"
	"AR=${HOST_TOOLCHAIN}/bin/llvm-ar"
	"RANLIB=${HOST_TOOLCHAIN}/bin/llvm-ranlib"
	"CFLAGS=-O3"
	"CXXFLAGS=-O3"
	"LDFLAGS=-static"
)

foreach(LLVM_ARCH ${LLVM_ARCH_LIST})
	set(LLVM_SYSROOT "lib/clang/${LLVM_MAJOR_VERSION}/lib/${LLVM_ARCH}")
	file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_ARCH}")

	add_custom_target(musl-${LLVM_ARCH} ALL
		WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${LLVM_ARCH}"
		COMMAND ${CMD_SET_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/configure" "--target=${LLVM_ARCH}" "--prefix=${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr" --disable-shared ${LLVM_COMPILER_ARGS} "CFLAGS=-target ${LLVM_ARCH} -O3"
		COMMAND ${CMD_SET_PATH} make -j${CPUS} install
		COMMAND echo ================ musl ${LLVM_ARCH} done ==========
		VERBATIM
	)
	foreach(tool clang clang++ lld ld.lld)
		file(CREATE_LINK ${tool} ${LLVM_INSTALL_PREFIX}/bin/${LLVM_ARCH}-${tool} SYMBOLIC)
	endforeach()

	foreach(tool as nm objcopy objdump rc strip windres)
		file(CREATE_LINK llvm-${tool} ${LLVM_INSTALL_PREFIX}/bin/${LLVM_ARCH}-${tool} SYMBOLIC)
	endforeach()
	install(FILES "${CGET_RECIPE_DIR}/../cross-toolchain/toolchain.cmake" DESTINATION . RENAME "${LLVM_ARCH}.cmake")
endforeach()
