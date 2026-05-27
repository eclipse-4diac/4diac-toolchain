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
project(clang-runtime C CXX)

include(toolchain-utils)
include(${CGET_RECIPE_DIR}/../clang-bootstrap/helpers.cmake)
include(${CGET_RECIPE_DIR}/../clang/llvm-config-options.cmake)

# FIXME: timezone handling might be broken on MacOS
patch(libcxx/src/experimental/tzdb.cpp "defined\\(__linux__\\)" "1")

foreach(LLVM_ARCH ${LLVM_ARCH_LIST})
	set(LLVM_SYSROOT "lib/clang/${LLVM_MAJOR_VERSION}/lib/${LLVM_ARCH}")
	set(LLVM_COMPILER_ARGS
		"CC=${HOST_TOOLCHAIN}/bin/${LLVM_ARCH}-clang"
		"CXX=${HOST_TOOLCHAIN}/bin/${LLVM_ARCH}-clang++"
		"LD=${HOST_TOOLCHAIN}/bin/${LLVM_ARCH}-ld.lld"
		"AR=${HOST_TOOLCHAIN}/bin/llvm-ar"
		"RANLIB=${HOST_TOOLCHAIN}/bin/llvm-ranlib"
		"CFLAGS=-O3 --sysroot=${HOST_TOOLCHAIN}/${LLVM_SYSROOT} -isystem ${HOST_TOOLCHAIN}/${LLVM_SYSROOT}/usr/include"
		"CXXFLAGS=-O3 --sysroot=${HOST_TOOLCHAIN}/${LLVM_SYSROOT} -isystem ${HOST_TOOLCHAIN}/${LLVM_SYSROOT}/usr/include"
		"LDFLAGS=-static --sysroot=${HOST_TOOLCHAIN}/${LLVM_SYSROOT} -L ${HOST_TOOLCHAIN}/${LLVM_SYSROOT}"
	)

	set(arch_config)
	if (NOT LLVM_ARCH MATCHES "musl")
		set(arch_config -DLIBCXX_HAS_MUSL_LIBC=OFF)
	endif ()

	file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/cxx-${LLVM_ARCH}")
	add_custom_target(cxx-${LLVM_ARCH} ALL
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/cxx-${LLVM_ARCH}
		COMMAND ${CMD_SET_PATH} ${LLVM_COMPILER_ARGS} ${CMAKE_COMMAND} ${CMAKE_CURRENT_SOURCE_DIR}/runtimes ${LLVM_CONFIG_OPTIONS} ${arch_config} "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind" "-DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr" "-DLLVM_DEFAULT_TARGET_TRIPLE=${LLVM_ARCH}" "-DLLVM_HOST_TRIPLE=${LLVM_ARCH}" -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF
		COMMAND ${CMD_SET_PATH} ninja unwind cxxabi cxx
		COMMAND ${CMD_SET_PATH} ninja install-unwind install-cxxabi install-cxx
		COMMAND mkdir -p "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/sys/"
		COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/libc/include/sys/queue.h "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/sys/"
		COMMAND cp -r ${CMAKE_CURRENT_SOURCE_DIR}/libc/include/llvm-libc-macros/. "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/llvm-libc-macros/"
		COMMAND mv "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/lib/libc++.a" "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/lib/libc++base.a"
		COMMAND ${CMD_JOIN_ARCHIVES} "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/lib/libc++.a" "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/lib/libc++base.a" "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/lib/libc++abi.a"
		COMMAND echo ================ libcxx ${LLVM_ARCH} done ==========
		VERBATIM
	)

	if (NOT LLVM_ARCH MATCHES "musl")
		continue()
	endif ()

	set(LLVM_RT_ARGS
		"CFLAGS=-O3 --sysroot=${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT} -isystem ${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/c++/v1 -isystem ${TARGET_TOOLCHAIN}/${LLVM_SYSROOT}/usr/include"
		"CXXFLAGS=-O3 --sysroot=${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT} -isystem ${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/c++/v1 -isystem ${TARGET_TOOLCHAIN}/${LLVM_SYSROOT}/usr/include"
		"LDFLAGS=-static --sysroot=${TARGET_TOOLCHAIN}/${LLVM_SYSROOT} -L ${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/lib -L ${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT} -stdlib=libc++"
	)

	file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/rt-${LLVM_ARCH}")
	add_custom_target(rt-${LLVM_ARCH} ALL
		DEPENDS cxx-${LLVM_ARCH}
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/rt-${LLVM_ARCH}
		COMMAND ${CMD_SET_PATH} ${LLVM_COMPILER_ARGS} ${LLVM_RT_ARGS} ${CMAKE_COMMAND} ${CMAKE_CURRENT_SOURCE_DIR}/llvm ${LLVM_CONFIG_OPTIONS} "-DLLVM_ENABLE_PROJECTS=compiler-rt" "-DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL_PREFIX}" -DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${LLVM_ARCH} "-DLLVM_DEFAULT_TARGET_TRIPLE=${LLVM_ARCH}" "-DLLVM_HOST_TRIPLE=${LLVM_ARCH}"
		COMMAND ${CMD_SET_PATH} ninja compiler-rt
		COMMAND ${CMD_SET_PATH} ninja install-compiler-rt
		COMMAND echo ================ compiler-rt ${LLVM_ARCH} done ==========
		VERBATIM
	)
endforeach()

install(DIRECTORY ${LLVM_INSTALL_PREFIX} DESTINATION .)
