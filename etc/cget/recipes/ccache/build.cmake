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
project(ccache CXX)

include(toolchain-utils)
patch(src/third_party/fmt/fmt/base.h "#ifndef FMT_MODULE" "#ifndef FMT_MODULE\n#include <stdlib.h>")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
