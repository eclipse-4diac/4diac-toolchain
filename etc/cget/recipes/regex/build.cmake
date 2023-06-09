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

PROJECT(regex C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

add_library(regex regex.c)
target_compile_definitions(regex PRIVATE STDC_HEADERS)

install(TARGETS regex DESTINATION lib)
install(FILES regex.h DESTINATION include)
