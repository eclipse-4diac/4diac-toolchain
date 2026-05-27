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
project(putty C)

include(toolchain-utils)

set(CMAKE_BUILD_TYPE RelWithDebInfo)
include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

set_target_properties(pscp PROPERTIES OUTPUT_NAME scp)
set_target_properties(psftp PROPERTIES OUTPUT_NAME sftp)
install(PROGRAMS ${CGET_RECIPE_DIR}/ssh DESTINATION bin)

