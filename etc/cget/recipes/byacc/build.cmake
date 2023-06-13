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

PROJECT(byacc C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

add_executable(byacc
  closure.c
  error.c
  graph.c
  lalr.c
  lr0.c
  main.c
  mkpar.c
  mstring.c
  output.c
  reader.c
  yaccpar.c
  symtab.c
  verbose.c
  warshall.c)

file(STRINGS VERSION VERSION)
target_compile_definitions(byacc PRIVATE YYPATCH="${VERSION}")

install(TARGETS byacc DESTINATION bin)
