cmake_minimum_required(VERSION 3.13)
project(remake)

string(REGEX REPLACE "^.*/share/cmake" "${CMAKE_INSTALL_PREFIX}/share/cmake" TARGET_ROOT "${CMAKE_ROOT}")
install(FILES ReMake.cmake DESTINATION ${TARGET_ROOT}/Modules)
