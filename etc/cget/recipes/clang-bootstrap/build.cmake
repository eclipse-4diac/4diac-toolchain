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

cmake_minimum_required(VERSION 3.19)
project(clang-bootstrap C CXX)

include(toolchain-utils)
include(${CGET_RECIPE_DIR}/../clang-bootstrap/helpers.cmake)
include(${CGET_RECIPE_DIR}/../clang/llvm-config-options.cmake)

if (NOT CMAKE_CROSSCOMPILING)
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${LLVM_ARCH})
	add_custom_target(${LLVM_ARCH} ALL
		WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${LLVM_ARCH}
		COMMAND env "CFLAGS=${CMAKE_C_FLAGS}" "CXXFLAGS=${CMAKE_CXX_FLAGS}" "LDFLAGS=${CMAKE_EXE_LINKER_FLAGS}" ${CMAKE_COMMAND} ${CMAKE_CURRENT_SOURCE_DIR}/llvm ${LLVM_CONFIG_OPTIONS} "-DLLVM_ENABLE_PROJECTS=clang;lld" "-DLLVM_ENABLE_RUNTIMES=compiler-rt" "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}" "-DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL_PREFIX}/bootstrap" "-DLLVM_TARGETS_TO_BUILD=X86;AArch64;ARM;RISCV" -DENABLE_LIBCXX=ON "-DDEFAULT_SYSROOT:PATH=${TOOLCHAIN_ROOT}/${TOOLCHAIN_ARCH}"
		  COMMAND ninja clang lld
		  COMMAND ninja install
		  COMMAND ${LLVM_INSTALL_PREFIX}/bootstrap/bin/llvm-ar rcs "${LLVM_INSTALL_PREFIX}/bootstrap/lib/libgcc_eh.a"
		  COMMAND ${LLVM_INSTALL_PREFIX}/bootstrap/bin/llvm-ar rcs "${LLVM_INSTALL_PREFIX}/bootstrap/lib/libgcc_s.a"
		  COMMAND echo ================ stage1 ${LLVM_ARCH} done ==========
		  VERBATIM
	)

	foreach(tool clang clang++ lld ld.lld)
		install(PROGRAMS ${CGET_RECIPE_DIR}/wrapper.sh DESTINATION clang-toolchain/bin RENAME ${tool})
	endforeach()

	foreach(tool ar as dlltool nm objcopy objdump ranlib rc strip windres tblgen)
		install(PROGRAMS ${CGET_RECIPE_DIR}/wrapper.sh DESTINATION clang-toolchain/bin RENAME llvm-${tool})
	endforeach()
endif()
