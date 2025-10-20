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

foreach (arch x86_64 aarch64)
	foreach (prog clang clang++ lld ld.lld)
		install(PROGRAMS ${CGET_RECIPE_DIR}/wrapper.sh DESTINATION clang-toolchain/bin RENAME ${arch}-apple-darwin20.2-${prog})
		install(FILES "${CGET_RECIPE_DIR}/../cross-toolchain/toolchain.cmake" DESTINATION . RENAME "${arch}-apple-darwin20.2.cmake")

		foreach(tool as nm objcopy objdump rc strip windres)
			file(CREATE_LINK llvm-${tool} ${LLVM_INSTALL_PREFIX}/bin/${arch}-apple-darwin20.2-${tool} SYMBOLIC)
		endforeach()
	endforeach()
endforeach()
