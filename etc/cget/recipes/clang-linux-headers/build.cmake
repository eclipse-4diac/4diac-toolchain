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
project(clang-linux-headers C CXX)

include(toolchain-utils)
include(${CGET_RECIPE_DIR}/../clang-bootstrap/helpers.cmake)

# workaround for kernel header install
file(COPY "${CGET_RECIPE_DIR}/../cross-toolchain/rsync" DESTINATION ${CMAKE_CURRENT_SOURCE_DIR} USE_SOURCE_PERMISSIONS)
patch("${CMAKE_CURRENT_SOURCE_DIR}/rsync" "#!/bin/sh" "#!${TOOLCHAINS_ROOT}/bin/sh")

add_custom_target(linux-scripts ALL
	WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
	COMMAND make headers
	VERBATIM
)
foreach(LLVM_ARCH x86_64-unknown-linux-musl aarch64-unknown-linux-musl)
	string(REGEX REPLACE "-.*" "" linux_arch "${LLVM_ARCH}")
	string(REPLACE "aarch64" "arm64" linux_arch "${linux_arch}")
	string(REPLACE "x86_64" "x86" linux_arch "${linux_arch}")

	set(LLVM_SYSROOT "lib/clang/${LLVM_MAJOR_VERSION}/lib/${LLVM_ARCH}")

	add_custom_target(linux-${LLVM_ARCH} ALL
		DEPENDS linux-scripts
		WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
		COMMAND make -C "${CMAKE_CURRENT_SOURCE_DIR}" "ARCH=${linux_arch}" "O=${CMAKE_CURRENT_BINARY_DIR}/linux-${LLVM_ARCH}" "INSTALL_HDR_PATH=${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr" "PATH=${CMAKE_CURRENT_SOURCE_DIR}:$ENV{PATH}" headers headers_install
		COMMAND find "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/" -name *.cmd -delete
		COMMAND cp -r "${CMAKE_CURRENT_SOURCE_DIR}/include/linux/percpu_counter.h" "${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/linux"
		COMMAND sh -c "cd '${LLVM_INSTALL_PREFIX}/${LLVM_SYSROOT}/usr/include/asm-generic'; yes n | cp -r -i * '../asm/'"
		COMMAND echo ================ kernel-headers ${LLVM_ARCH} done ==========
		VERBATIM
	)
endforeach()
