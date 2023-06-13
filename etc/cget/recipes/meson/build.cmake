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

project(meson NONE)
cmake_minimum_required(VERSION 3.13)

include(toolchain-utils)

python_setuppy_install()
python_install_wrapper(meson mesonbuild.mesonmain)
