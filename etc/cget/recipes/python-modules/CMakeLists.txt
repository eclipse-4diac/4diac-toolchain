project(python-modules)
cmake_minimum_required(VERSION 3.13)

include(toolchain-utils)
python_detect_version()

download_extra_source(get_pip get-pip.py
  https://bootstrap.pypa.io/pip/3.5/get-pip.py
  311afebb7cdd310eb3a3a6bb6fffef53d84493db98c7cebf4008a18d3418c8be)

add_custom_target(pip ALL
  COMMAND python ${SOURCE_get_pip}
  COMMAND sed -e "s,^#!.*,#!/usr/bin/env python," -i ${CGET_PREFIX}/../bin/pip)

# # Extract the bootstrap pip and install it bare-bones; no pip script since
# # functionality with a static python is extremely limited. This is really just
# # for "python setup.py" support
# add_custom_target(pip ALL
#   COMMAND ${CMAKE_COMMAND} -E tar xf ${CGET_PREFIX}/../lib/python3.6/ensurepip/_bundled/pip*.whl
#   COMMAND ${CMAKE_COMMAND} -E tar xf ${CGET_PREFIX}/../lib/python3.6/ensurepip/_bundled/setuptools*.whl)
# install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/pip DESTINATION lib/python3.6/site-packages)
# install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/setuptools DESTINATION lib/python3.6/site-packages)

# locally bundled packages
install(DIRECTORY "${CGET_RECIPE_DIR}/lib/." DESTINATION lib/python${pymajor}/site-packages)
