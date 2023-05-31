##############################################################################
#
# CMake script to build meson-based packages correctly
#
##############################################################################
# Usage:
#[[

# all set() commands are optional
set(MESON_C_FLAGS "-O1")
set(MESON_CXX_FLAGS "-std=c++03")
set(MESON_EXE_LINKER_FLAGS "-lz")

# pass multiple options as separate strings
set(MESON_CONFIGURE_OPTIONS
  "-D" "foo=bar"
)

# files are installed into ${CMAKE_CURRENT_BINARY_DIR}/install, you need to
# install() them separately
install(PROGRAMS
  ${CMAKE_CURRENT_BINARY_DIR}/install/foo${CMAKE_EXECUTABLE_SUFFIX}
  DESTINATION bin)

include(meson-build)
#]]
##############################################################################


###################################################################
# set up build rule to invoke build script
if (NOT CMAKE_SCRIPT_MODE_FILE)
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/install)

  string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
  set(C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_C_FLAGS_${BUILD_TYPE}}")
  set(CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_${BUILD_TYPE}}")
  set(EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${CMAKE_EXE_LINKER_FLAGS_${BUILD_TYPE}} ${CMAKE_C_STANDARD_LIBRARIES}")
  
  add_custom_target(meson-build ALL VERBATIM
    COMMAND ${CMAKE_COMMAND}
    -DMESON_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DMESON_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}
    -DMESON_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
    -DMESON_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    "-DMESON_C_FLAGS=${C_FLAGS} ${MESON_C_FLAGS}"
    "-DMESON_CXX_FLAGS=${CXX_FLAGS} ${MESON_CXX_FLAGS}"
    "-DMESON_EXE_LINKER_FLAGS=${EXE_LINKER_FLAGS} ${MESON_EXE_LINKER_FLAGS}"
    -DTOOLCHAINS_ROOT=${TOOLCHAINS_ROOT}
    "-DMESON_PATH=$ENV{PATH}"
    "-DMESON_CONFIGURE_OPTIONS=${MESON_CONFIGURE_OPTIONS}"
    -P ${CMAKE_CURRENT_LIST_FILE}
    )
  return()
endif()

################################################################################
# actual builds are performed through this part, which is invoked in script mode
include("${TOOLCHAINS_ROOT}/native-toolchain.cmake")
set(native_arch "${TOOLCHAIN_ARCH}")
include(${MESON_TOOLCHAIN_FILE})
if (NOT native_arch STREQUAL TOOLCHAIN_ARCH)
  set(CMAKE_CROSSCOMPILING ON)
endif()

if (NOT MESON_BUILD_TYPE)
  set(MESON_BUILD_TYPE "Release")
endif()

set(build "release")
string(TOUPPER ${MESON_BUILD_TYPE} MESON_BUILD_TYPE)
if (MESON_BUILD_TYPE STREQUAL "DEBUG")
  set(build "debug")
endif()

set(ENV{PATH} "${MESON_PATH}")
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

function(make_meson_array outvar)
  separate_arguments(arglist UNIX_COMMAND "${ARGN}")
  list(JOIN arglist "','" array)
  set(${outvar} "'${array}'" PARENT_SCOPE)
endfunction()
make_meson_array(c_args ${MESON_C_FLAGS})
make_meson_array(cpp_args ${MESON_CXX_FLAGS})
make_meson_array(c_link_args ${MESON_EXE_LINKER_FLAGS})

string(TOLOWER "${CMAKE_SYSTEM_NAME}" system)
string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" cpu)

file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/cross-file.ini
  "[binaries]\n"
  "c = '${CMAKE_C_COMPILER}'\n"
  "cpp = '${CMAKE_CXX_COMPILER}'\n"
  "ar = '${CMAKE_AR}'\n"
  "as = '${CMAKE_C_COMPILER}'\n"
  "ld = '${CMAKE_LINKER}'\n"
  "nm = '${CMAKE_NM}'\n"
  "strip = '${CMAKE_STRIP}'\n"
  "exe_wrapper = ['false']\n"
  "\n"
  "[built-in options]\n"
  "c_args = [${c_args}]\n"
  "cpp_args = [${cpp_args}]\n"
  "c_link_args = [${c_link_args}]\n"
  "\n"
  "[properties]\n"
  "needs_exe_wrapper = true\n"
  "skip_sanity_check = true\n"
  "\n"
  "[host_machine]\n"
  "system = 'none'\n"
  "cpu_family = '${cpu}'\n"
  "cpu = '${cpu}'\n"
  "endian = 'little'\n")

file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/build)
message("${TOOLCHAINS_ROOT}/bin/meson
    ${MESON_SOURCE_DIR} .
    --prefix=${MESON_INSTALL_PREFIX}
    --buildtype=${build}
    --cross-file=${CMAKE_CURRENT_BINARY_DIR}/cross-file.ini
    ${MESON_CONFIGURE_OPTIONS}")
execute_process(COMMAND ${TOOLCHAINS_ROOT}/bin/meson
    ${MESON_SOURCE_DIR} .
    --prefix=${MESON_INSTALL_PREFIX}
    --buildtype=${build}
    --cross-file=${CMAKE_CURRENT_BINARY_DIR}/cross-file.ini
    ${MESON_CONFIGURE_OPTIONS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/build
    RESULT_VARIABLE RC)
if (NOT RC EQUAL 0)
  message(FATAL_ERROR "Configuration failed.")
endif()

message("${TOOLCHAINS_ROOT}/bin/ninja ${MESON_TARGET}")
execute_process(COMMAND ${TOOLCHAINS_ROOT}/bin/ninja
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/build
  RESULT_VARIABLE RC)
if (NOT RC EQUAL 0)
  message(FATAL_ERROR "Build failed.")
endif()

execute_process(COMMAND ${TOOLCHAINS_ROOT}/bin/meson install --destdir=${CMAKE_CURRENT_BINARY_DIR}/install
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/build
  RESULT_VARIABLE RC)
if (NOT RC EQUAL 0)
  message(FATAL_ERROR "Install failed.")
endif()
