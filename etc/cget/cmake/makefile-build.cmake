#********************************************************************************
# Copyright (c) 2018, 2025 OFFIS e.V.
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
##############################################################################
#
# CMake script to build Makefile-based packages correctly -- even on windows
#
##############################################################################
# Usage:
#[[

# all set() commands are optional
set(MAKEFILE_C_FLAGS "-O1")
set(MAKEFILE_CXX_FLAGS "-std=c++03")
set(MAKEFILE_EXE_LINKER_FLAGS "-lz")

# pass multiple options as separate strings
set(MAKEFILE_OPTIONS
  "--enable-static"
  "--disable-shared"
  "--disable-nls")

# set(MAKEFILE_TARGET "-C" "src")           # to build a single subdirectory
# set(MAKEFILE_TARGET "install")            # to let the package install itself
# set(MAKEFILE_TARGET "-C" "src" "install") # to build and install a single subdirectory
# instead of using "install": minimal install via custom cmake rules
install(PROGRAMS
  ${CMAKE_CURRENT_BINARY_DIR}/src/foo${CMAKE_EXECUTABLE_SUFFIX}
  DESTINATION bin)

include(makefile-build)
#]]
##############################################################################


###################################################################
# set up build rule to invoke build script
if (NOT CMAKE_SCRIPT_MODE_FILE)
  string(TOUPPER "${CMAKE_BUILD_TYPE}" BUILD_TYPE)
  set(C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${BUILD_TYPE}}")
  set(CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${BUILD_TYPE}}")
  set(EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS_${BUILD_TYPE}} ${CMAKE_C_STANDARD_LIBRARIES}")

  add_custom_target(makefile-build ALL VERBATIM USES_TERMINAL
    COMMAND ${CMAKE_COMMAND}
    -DMAKEFILE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DMAKEFILE_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -DMAKEFILE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    -DMAKEFILE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    "-DMAKEFILE_C_FLAGS=${C_FLAGS} ${MAKEFILE_C_FLAGS}"
    "-DMAKEFILE_CXX_FLAGS=${CXX_FLAGS} ${MAKEFILE_CXX_FLAGS}"
    "-DMAKEFILE_EXE_LINKER_FLAGS=${EXE_LINKER_FLAGS} ${MAKEFILE_EXE_LINKER_FLAGS}"
    -DTOOLCHAINS_ROOT=${TOOLCHAINS_ROOT}
    "-DMAKEFILE_PATH=$ENV{PATH}"
    "-DMAKEFILE_OPTIONS=${MAKEFILE_OPTIONS}"
    "-DMAKEFILE_TARGET=${MAKEFILE_TARGET}"
    -P ${CMAKE_CURRENT_LIST_FILE}
    )
  return()
endif()

################################################################################
# actual builds are performed through this part, which is invoked in script mode
include("${TOOLCHAINS_ROOT}/native-toolchain.cmake")
set(native_arch "${TOOLCHAIN_ARCH}")
include(${MAKEFILE_TOOLCHAIN_FILE})
if (NOT native_arch STREQUAL TOOLCHAIN_ARCH)
  set(CMAKE_CROSSCOMPILING ON)
endif()

if (MAKEFILE_BUILD_TYPE)
  string(TOUPPER ${MAKEFILE_BUILD_TYPE} MAKEFILE_BUILD_TYPE)
  foreach(prog IN ITEMS C CXX EXE_LINKER)
	  set(CMAKE_${prog}_FLAGS_INIT "${CMAKE_${prog}_FLAGS_${MAKEFILE_BUILD_TYPE}_INIT}")
  endforeach()
endif()
foreach(prog IN ITEMS C CXX EXE_LINKER)
	string(APPEND CMAKE_${prog}_FLAGS_INIT " ${MAKEFILE_${prog}_FLAGS}")
endforeach()

set(ENV{PATH} "${MAKEFILE_PATH}")
if (WIN32)
  # construct a PATH variable that works with unix and windows conventions,
  # i.e. first a colon-separated list, then a semicolon-separated list
  set(unixpath "")
  foreach(element IN ITEMS $ENV{PATH})
	  string(REGEX REPLACE "^([a-zA-Z]):" "/\\1" element "${element}")
	  set(unixpath "${unixpath}${element}:")
  endforeach()
  set(ENV{PATH} "${unixpath};$ENV{PATH}")
endif()

set(ENV{SHELL} "${TOOLCHAINS_ROOT}/bin/sh")
set(ENV{CONFIG_SHELL} "${TOOLCHAINS_ROOT}/bin/sh")
set(ENV{CC_FOR_BUILD} "${TOOLCHAINS_ROOT}/bin/gcc")
set(ENV{CC} "${CMAKE_C_COMPILER}")
set(ENV{CXX} "${CMAKE_CXX_COMPILER}")
set(ENV{CFLAGS} "${CMAKE_C_FLAGS_INIT}")
set(ENV{CPPFLAGS} "${CMAKE_CPP_FLAGS_INIT}")
set(ENV{CXXFLAGS} "${CMAKE_CXX_FLAGS_INIT}")
set(ENV{LDFLAGS} "${CMAKE_EXE_LINKER_FLAGS_INIT}")
set(ENV{LIBS} "${CMAKE_EXE_LINKER_FLAGS_INIT}")
set(ENV{LD} "${CMAKE_LINKER}")

foreach (tool IN ITEMS AR NM OBJCOPY OBJDUMP STRIP RANLIB)
  set(ENV{${tool}} "${CMAKE_${tool}}")
endforeach()

foreach (tool IN ITEMS sed grep m4)
  string(TOUPPER ${tool} utool)
  set(ENV{${utool}} "${TOOLCHAINS_ROOT}/bin/${tool}")
endforeach()

foreach (var IN ITEMS PATH CC CXX CFLAGS CPPFLAGS CXXFLAGS LDFLAGS LIBS LD)
  message(STATUS "${var} = $ENV{${var}}")
endforeach()

message(STATUS "Cross-Compiling: ${CMAKE_CROSSCOMPILING}, host/target: ${TOOLCHAIN_ARCH}, build: ${native_arch}")
set(cross_args)
if (CMAKE_CROSSCOMPILING)
  set(cross_args "--host=${TOOLCHAIN_ARCH}" "--target=${TOOLCHAIN_ARCH}" "--build=${native_arch}")
endif()

message(STATUS "${TOOLCHAINS_ROOT}/bin/sh
    ${MAKEFILE_SOURCE_DIR}/configure
        --prefix=${MAKEFILE_INSTALL_PREFIX}
        --disable-dependency-tracking --disable-silent-rules --disable-rpath
        ${MAKEFILE_CONFIGURE_OPTIONS}
        ${cross_args}")

include(ProcessorCount)
ProcessorCount(CPUS)
#set(CPUS 1)

message("${TOOLCHAINS_ROOT}/bin/make -j${CPUS} ${MAKEFILE_OPTIONS} ${MAKEFILE_TARGET}")
execute_process(COMMAND ${TOOLCHAINS_ROOT}/bin/make -j${CPUS}
#	"CC=${CMAKE_C_COMPILER}"
#	"CXX=${CMAKE_CXX_COMPILER}"
#	"CFLAGS=${CMAKE_C_FLAGS_INIT}"
#	"CPPFLAGS=${CMAKE_C_FLAGS_INIT}"
#	"CXXFLAGS=${CMAKE_CXX_FLAGS_INIT}"
#	"LDFLAGS=${CMAKE_EXE_LINKER_FLAGS_INIT}"
#	"LIBS=${CMAKE_EXE_LINKER_FLAGS_INIT}"
#	"LD=${CMAKE_LINKER}"
	${MAKEFILE_OPTIONS}
	${MAKEFILE_TARGET}
  WORKING_DIRECTORY ${MAKEFILE_SOURCE_DIR}
  RESULT_VARIABLE RC)
if (NOT RC EQUAL 0)
  message(FATAL_ERROR "Build failed.")
endif()
