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
project(regex C)


add_library(regex regex.c)
target_compile_definitions(regex PRIVATE STDC_HEADERS)
target_compile_options(regex PRIVATE -std=c90)

install(TARGETS regex DESTINATION lib)
install(FILES regex.h DESTINATION include)
