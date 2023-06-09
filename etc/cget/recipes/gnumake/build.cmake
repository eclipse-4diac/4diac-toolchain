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

PROJECT(gnumake C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

set(iswin $<BOOL:${WIN32}>)
set(notwin $<NOT:${iswin}>)

add_executable(make

  ar.c arscan.c commands.c default.c dir.c expand.c file.c function.c getopt.c
  getopt1.c guile.c implicit.c job.c load.c loadapi.c main.c misc.c output.c
  read.c remake.c rule.c signame.c strcache.c variable.c version.c vpath.c
  hash.c remote-stub.c glob/fnmatch.c glob/glob.c

  $<${notwin}: posixos.c>

  $<${iswin}: getloadavg.c w32/compat/posixfcn.c w32/pathstuff.c
  w32/subproc/misc.c w32/subproc/sub_proc.c w32/subproc/w32err.c w32/w32os.c>)

install(TARGETS make DESTINATION bin)

file(TO_CMAKE_PATH "${CGET_PREFIX}" CGET_PREFIX)

target_include_directories(make PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(make PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/glob)
target_compile_definitions(make PRIVATE INCLUDEDIR="${CGET_PREFIX}/include")
target_compile_definitions(make PRIVATE LIBDIR="${CGET_PREFIX}/lib")
target_compile_definitions(make PRIVATE LOCALEDIR="")
target_compile_definitions(make PRIVATE HAVE_CONFIG_H=1)

if (WIN32)
  target_include_directories(make PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/w32/include)
  target_compile_definitions(make PRIVATE WINDOWS32)
  target_compile_options(make PRIVATE -mthreads)

  file(RENAME config.h.W32 config.h)
else()

  target_compile_definitions(make PRIVATE __alloca=alloca)
  # Regex for simplification: <Ctrl-J>*/\*[^*]*\*/
  file(WRITE config.h "
#define FILE_TIMESTAMP_HI_RES 1
#define HAVE_ALLOCA 1
#define HAVE_ALLOCA_H 1
#define HAVE_ATEXIT 1
//#define HAVE_CASE_INSENSITIVE_FS 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_DECL_BSD_SIGNAL 1
#define HAVE_DECL_DLERROR 1
#define HAVE_DECL_DLOPEN 1
#define HAVE_DECL_DLSYM 1
#define HAVE_DECL_SYS_SIGLIST 0
#define HAVE_DECL__SYS_SIGLIST 0
#define HAVE_DECL___SYS_SIGLIST 0
#define HAVE_DIRENT_H 1
#define HAVE_DUP 1
#define HAVE_DUP2 1
#define HAVE_FCNTL_H 1
#define HAVE_FDOPEN 1
#define HAVE_FILENO 1
#define HAVE_FORK 1
#define HAVE_GETCWD 1
#define HAVE_GETGROUPS 1
#define HAVE_GETLOADAVG 1
#define HAVE_GETRLIMIT 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_INTTYPES_H 1
#define HAVE_ISATTY 1
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
#define HAVE_LSTAT 1
#define HAVE_MEMORY_H 1
#define HAVE_MKSTEMP 1
#define HAVE_MKTEMP 1
#define HAVE_PIPE 1
#define HAVE_PSELECT 1
#define HAVE_READLINK 1
#define HAVE_REALPATH 1
#define HAVE_SA_RESTART 1
#define HAVE_SETEGID 1
#define HAVE_SETEUID 1
#define HAVE_SETLINEBUF 1
#define HAVE_SETREGID 1
#define HAVE_SETREUID 1
#define HAVE_SETRLIMIT 1
#define HAVE_SETVBUF 1
#define HAVE_SIGACTION 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRCASECMP 1
#define HAVE_STRCOLL 1
#define HAVE_STRDUP 1
#define HAVE_STRERROR 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_STRNCASECMP 1
#define HAVE_STRNDUP 1
#define HAVE_STRSIGNAL 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_RESOURCE_H 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIMEB_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_TTYNAME 1
#define HAVE_UINTMAX_T 1
#define HAVE_UNISTD_H 1
#define HAVE_UNSIGNED_LONG_LONG_INT 1
#define HAVE_VFORK 1
#define HAVE_WAIT3 1
#define HAVE_WAITPID 1
#define HAVE_WORKING_FORK 1
#define HAVE_WORKING_VFORK 1
#define MAKE_HOST \"x86_64-pc-linux-gnu\"
#define MAKE_JOBSERVER 1
#define MAKE_SYMLINKS 1
#define PACKAGE \"make\"
#define PACKAGE_BUGREPORT \"bug-make@gnu.org\"
#define PACKAGE_NAME \"GNU make\"
#define PACKAGE_STRING \"GNU make 4.2\"
#define PACKAGE_TARNAME \"make\"
#define PACKAGE_URL \"http://www.gnu.org/software/make/\"
#define PACKAGE_VERSION \"4.2\"
#define PATH_SEPARATOR_CHAR ':'
#define RETSIGTYPE void
#define SCCS_GET \"get\"

/* Define to 1 if the `S_IS*' macros in <sys/stat.h> do not work properly. */
#define STDC_HEADERS 1
#define ST_MTIM_NSEC st_mtim.tv_nsec
#define TIME_WITH_SYS_TIME 1
#ifndef _ALL_SOURCE
# define _ALL_SOURCE 1
#endif
#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif
#ifndef _POSIX_PTHREAD_SEMANTICS
# define _POSIX_PTHREAD_SEMANTICS 1
#endif
#ifndef _TANDEM_SOURCE
# define _TANDEM_SOURCE 1
#endif
#ifndef __EXTENSIONS__
# define __EXTENSIONS__ 1
#endif
#define VERSION \"4.2\"
#ifndef _DARWIN_USE_64_BIT_INODE
# define _DARWIN_USE_64_BIT_INODE 1
#endif
")

endif()
