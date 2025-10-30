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
project(clang-macos NONE)

include(toolchain-utils)
include(${CGET_RECIPE_DIR}/../clang-bootstrap/helpers.cmake)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/. DESTINATION clang-toolchain/SDK/MacOSX11.1.sdk USE_SOURCE_PERMISSIONS)

foreach(LLVM_ARCH x86_64-apple-darwin20.2 aarch64-apple-darwin20.2)
	set(LLVM_SYSROOT "lib/clang/${LLVM_MAJOR_VERSION}/lib/${LLVM_ARCH}")
	install(DIRECTORY DESTINATION "clang-toolchain/${LLVM_SYSROOT}")
	foreach (prog clang clang++ lld ld.lld)
		install(PROGRAMS ${CGET_RECIPE_DIR}/wrapper.sh DESTINATION clang-toolchain/bin RENAME ${LLVM_ARCH}-${prog})
		install(FILES "${CGET_RECIPE_DIR}/../cross-toolchain/toolchain.cmake" DESTINATION . RENAME "${LLVM_ARCH}.cmake")

		foreach(tool as nm objcopy objdump rc strip windres)
			file(CREATE_LINK llvm-${tool} ${CMAKE_INSTALL_PREFIX}/clang-toolchain/${LLVM_ARCH}-${tool} SYMBOLIC)
		endforeach()
	endforeach()
endforeach()

# this installs libc++ for macos
install(CODE "execute_process(WORKING_DIRECTORY \"${CMAKE_INSTALL_PREFIX}\" COMMAND ./bin/cget install -U clang-runtime)")
