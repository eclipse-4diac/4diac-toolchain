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

project(python-modules NONE)
cmake_minimum_required(VERSION 3.13)

include(toolchain-utils)
python_detect_version()

set(pycmd ${CMAKE_COMMAND} -E env
  HOME=${CGET_PREFIX}
  PYTHONHOME=${CMAKE_CURRENT_BINARY_DIR}
  PYTHONPATH=${TOOLCHAINS_ROOT}/lib/python${pymajor}
  ${TOOLCHAINS_ROOT}/bin/python)

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib/python${pymajor}/site-packages)
add_custom_target(pip ALL
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib/python${pymajor}/site-packages
  COMMAND ${CMAKE_COMMAND} -E tar xf ${CGET_PREFIX}/lib/python${pymajor}/ensurepip/_bundled/pip*.whl
  COMMAND ${CMAKE_COMMAND} -E tar xf ${CGET_PREFIX}/lib/python${pymajor}/ensurepip/_bundled/setuptools*.whl
  COMMAND sed -e "'s/ = glibc_version_string()/ = None/'" -i pip/_internal/utils/glibc.py
  COMMAND sed -e "'s/not _have_compatible_abi(arch)/True/'" -i pip/_vendor/packaging/_manylinux.py)

set(pipcommand ${pycmd} -m pip install --isolated --no-deps --force-reinstall)

add_custom_target(six ALL DEPENDS pip COMMAND ${pipcommand} six==1.15.0)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib DESTINATION .)
install(PROGRAMS ${CGET_RECIPE_DIR}/pip DESTINATION bin)

