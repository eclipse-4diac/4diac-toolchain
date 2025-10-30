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


set(LLVM_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/clang-toolchain)
file(MAKE_DIRECTORY "${LLVM_INSTALL_PREFIX}/bin")
install(DIRECTORY ${LLVM_INSTALL_PREFIX} DESTINATION . USE_SOURCE_PERMISSIONS)

set(HOST_TOOLCHAIN "${TOOLCHAIN_ROOT}/../clang-toolchain")
set(TARGET_TOOLCHAIN "${CMAKE_INSTALL_PREFIX}/clang-toolchain")

if (EXISTS "${TARGET_TOOLCHAIN}/bootstrap/lib/clang/")
	file(GLOB LLVM_MAJOR_VERSION RELATIVE "${TARGET_TOOLCHAIN}/bootstrap/lib/clang/" "${TARGET_TOOLCHAIN}/bootstrap/lib/clang/*")
elseif (EXISTS "${TARGET_TOOLCHAIN}/lib/clang/")
	file(GLOB LLVM_MAJOR_VERSION RELATIVE "${TARGET_TOOLCHAIN}/lib/clang/" "${TARGET_TOOLCHAIN}/lib/clang/*")
else()
	file(GLOB LLVM_MAJOR_VERSION RELATIVE "${HOST_TOOLCHAIN}/lib/clang/" "${HOST_TOOLCHAIN}/lib/clang/*")
endif()

string(REPLACE "-linux-" "-unknown-linux-" LLVM_ARCH "${TOOLCHAIN_ARCH}")
set(LLVM_HOSTARCH "x86_64-unknown-linux-musl") # TODO: bootstrapping only works on x86 for now
set(LLVM_SYSROOT "lib/clang/${LLVM_MAJOR_VERSION}/lib/${LLVM_ARCH}")

set(CMD_SET_PATH "${TOOLCHAINS_ROOT}/bin/env" "PATH=${TOOLCHAINS_ROOT}/bin:${TOOLCHAINS_ROOT}/clang-toolchain/bin:${TOOLCHAINS_ROOT}/x86_64-linux-musl/bin:${TOOLCHAINS_ROOT}/aarch64-linux-musl/bin")
set(CMD_JOIN_ARCHIVES ${CMD_SET_PATH} "${TOOLCHAINS_ROOT}/bin/sh" "${CGET_RECIPE_DIR}/../clang-bootstrap/join-archives.sh")

file(GLOB LLVM_ARCH_LIST RELATIVE "${TARGET_TOOLCHAIN}/lib/clang/${LLVM_MAJOR_VERSION}/lib/" "${TARGET_TOOLCHAIN}/lib/clang/${LLVM_MAJOR_VERSION}/lib/*-*")

include(ProcessorCount)
ProcessorCount(CPUS)

