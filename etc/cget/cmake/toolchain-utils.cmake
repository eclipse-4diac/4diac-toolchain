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
###############################################################################
# this needs a project() command that matches the recipe subdirectory name
set(CGET_RECIPE_DIR ${CGET_PREFIX}/etc/cget/recipes/${CMAKE_PROJECT_NAME})
file(TO_CMAKE_PATH "${CGET_RECIPE_DIR}" CGET_RECIPE_DIR)
list(INSERT CMAKE_MODULE_PATH 0 "${CGET_RECIPE_DIR}")

###############################################################################

# set variable "pymajor" to python major version
macro(python_detect_version)
  file(GLOB pymajor "${TOOLCHAINS_ROOT}/lib/python*.*")
  string(REGEX REPLACE ".*python" "" pymajor "${pymajor}")
endmacro()

# python module installation via setup.py
# will not install any binaries, as their #!-line is not portable
macro(python_setuppy_install)
  python_detect_version()
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib/python${pymajor}/site-packages)
  add_custom_target(python ALL
    COMMAND
    ${CMAKE_COMMAND} -E env
    HOME=${CGET_PREFIX}
    PYTHONHOME=${CMAKE_CURRENT_BINARY_DIR}
    PYTHONPATH=${TOOLCHAINS_ROOT}/lib/python${pymajor}:${TOOLCHAINS_ROOT}/lib/python${pymajor}/site-packages
    ${TOOLCHAINS_ROOT}/bin/python setup.py install
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/lib DESTINATION .)
endmacro()

macro(python_install_wrapper name module)
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/wrapper)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/wrapper/${name} [=[
#!/bin/sh
dir="$(cd "$(dirname "$0")/.."; pwd)"
export PATH="$dir/bin"
export LD_LIBRARY_PATH="$dir/lib"
export CCACHE_CONFIGPATH="$dir/etc/ccache.conf"
export CCACHE_DIR="$dir/.cache/ccache"
export SHELL="$dir/bin/sh"
unset PYTHONHOME PYTHONPATH MAKEFLAGS
]=]
    "exec \"\$dir/bin/python\" -m ${module} \"\$@\"\n")
  install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/wrapper/${name} DESTINATION bin)
endmacro()

###############################################################################
# Modify <file> in place by replacing all occurrences of <regex> with <replace>
function(patch file regex replace)
  file(READ ${file} PATCHING)
  string(REGEX REPLACE "${regex}" "${replace}" PATCHING "${PATCHING}")
  file(WRITE ${file} "${PATCHING}")
endfunction()


###############################################################################
# Modify <dir> by applying the external diff file. The first directory level is
# stripped, i.e. diffs should follow 'git diff' conventions
function(patch_diff dir patchfile)
  execute_process(
    COMMAND patch -p1 -i "${patchfile}"
    WORKING_DIRECTORY "${dir}"
    RESULT_VARIABLE RC)
  if (NOT RC EQUAL 0)
    message(FATAL_ERROR "ERROR: Could not apply '${patchfile}' to '${dir}'!")
  endif()
endfunction()


###############################################################################
# download <url>, check that it has <sha256hash>; variable SOURCE_<tag> is set
# to final filename, which will be <filename> in some cache directory
function(download_extra_source tag filename url sha256hash)
  set(cache_dir "${CGET_PREFIX}/.cache/cget/")
	file(MAKE_DIRECTORY "${cache_dir}/sha256-${sha256hash}")
  set(file "${cache_dir}/sha256-${sha256hash}/${filename}")
	if (NOT EXISTS "${file}")
	  message("Downloading ${url}...")
	  file(DOWNLOAD "${url}" "${file}" EXPECTED_HASH SHA256=${sha256hash})
	endif()
	file(SHA256 "${file}" file_hash)
	if (NOT "${sha256hash}" STREQUAL "${file_hash}")
	  message(FATAL_ERROR "Invalid checksum for ${file}!")
	endif()
	set("SOURCE_${tag}" "${file}" PARENT_SCOPE)
endfunction()


###############################################################################
# download <url> as <filename>, check that it has <sha256hash>; extract it
# inside directory <destination>; if it contains a lone top-level directory,
# strip that; the destination is emptied if it exists and created if not
function(add_source destination filename url sha256hash)
  download_extra_source(add_source "${filename}" "${url}" "${sha256hash}")
  file(REMOVE_RECURSE "${destination}")
  file(MAKE_DIRECTORY "${destination}")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xf ${SOURCE_add_source}
    WORKING_DIRECTORY ${destination})
  file(GLOB toplevel "${destination}/*")
  if (IS_DIRECTORY "${toplevel}")
    file(RENAME "${toplevel}" "${destination}.new")
    file(REMOVE "${destination}")
    file(RENAME "${destination}.new" "${destination}")
  endif()
endfunction()


###############################################################################
# usage: install_export_config([<export-name> [<namespace-name>]])
# create cmake package configuration files for targets marked as EXPORT
function(install_export_config)
  set(export_name "${ARGV0}")
  set(namespace_name "${ARGV1}")
  if (NOT export_name)
	  set(export_name "${CMAKE_PROJECT_NAME}")
  endif()
  if (NOT namespace_name)
	  set(namespace_name "${export_name}")
  endif()

install(CODE "
  file(GLOB_RECURSE export_file \${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/Export/${export_name}.cmake*)
  file(READ \${export_file} data)
  string(REPLACE \" IMPORTED)\" \" IMPORTED GLOBAL)\" data \"\${data}\")
  file(WRITE \${export_file} \"\${data}\")
")

  install(EXPORT ${export_name} DESTINATION share/cmake/${export_name}/export
	  NAMESPACE ${namespace_name}::
	  EXPORT_LINK_INTERFACE_LIBRARIES)

  include(CMakePackageConfigHelpers)

  get_cmake_property(vnames VARIABLES)
  set(pkgs "")
  foreach (name ${vnames})
	  if (name MATCHES "[a-zA-Z0-9_-]*_CONSIDERED_VERSIONS")
	    string(REPLACE "_CONSIDERED_VERSIONS" "" name ${name})
	    if (${name}_FOUND)
		    set(pkgs "${pkgs}find_package(${name} CONFIG)\n")
	    endif()
	  endif()
  endforeach()

  file(WRITE ${export_name}-config.cmake.in
	  "set(${export_name}_VERSION ${CMAKE_PROJECT_VERSION})\n"
	  "${pkgs}"
	  "@PACKAGE_INIT@\n"
	  "include(\${CMAKE_CURRENT_LIST_DIR}/export/${export_name}.cmake)\n"
	)

  configure_package_config_file(
	  ${export_name}-config.cmake.in
	  ${export_name}-config.cmake
	  INSTALL_DESTINATION share/cmake/${export_name}
	  PATH_VARS CMAKE_INSTALL_PREFIX)

  write_basic_package_version_file(
	  ${CMAKE_CURRENT_BINARY_DIR}/${export_name}-config-version.cmake
	  VERSION ${CMAKE_PROJECT_VERSION}
	  COMPATIBILITY SameMajorVersion)

  install(FILES
	  ${CMAKE_CURRENT_BINARY_DIR}/${export_name}-config.cmake
	  ${CMAKE_CURRENT_BINARY_DIR}/${export_name}-config-version.cmake
	  DESTINATION ${CMAKE_INSTALL_PREFIX}/share/cmake/${export_name})
endfunction()
