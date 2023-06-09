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

project(putty C)
cmake_minimum_required(VERSION 3.5)


# These assignments were taken as-is from file Recipes and transformed into
# CMake syntax

set(NONSSH telnet raw rlogin ldisc pinger)

set(SSH ssh sshcrc sshdes sshmd5 sshrsa sshrand sshsha sshblowf sshdh sshcrcda
  sshpubk sshzlib sshdss x11fwd portfwd sshaes sshccp sshsh256 sshsh512 sshbn
  wildcard pinger ssharcf sshgssc pgssapi sshshare sshecc aqsync)

set(WINSSH ${SSH} windows/winnoise windows/wincapi windows/winpgntc
  windows/wingss windows/winshare windows/winnps windows/winnpc windows/winhsock
  errsock)

set(UXSSH ${SSH} unix/uxnoise unix/uxagentc unix/uxgss unix/uxshare)

set(SFTP sftp int64 logging)

set(MISC timing callback misc version settings tree234 proxy conf be_misc)

set(WINMISC ${MISC} windows/winstore windows/winnet windows/winhandl cmdline
  windows/windefs windows/winmisc windows/winproxy windows/wintime
  windows/winhsock errsock windows/winsecur windows/winucs miscucs)

set(UXMISC ${MISC} unix/uxstore unix/uxsel unix/uxnet unix/uxpeer cmdline
  unix/uxmisc unix/uxproxy time)

set(IMPORT import sshbcrypt sshblowf)

set(BE_ALL be_all cproxy)
set(BE_NOSSH be_nossh nocproxy)
set(BE_SSH be_ssh cproxy)
set(BE_NONE be_none nocproxy)

set(W_BE_ALL be_all_s windows/winser cproxy)
set(W_BE_NOSSH be_nos_s windows/winser nocproxy)
set(U_BE_ALL be_all_s unix/uxser cproxy)
set(U_BE_NOSSH be_nos_s unix/uxser nocproxy)


if (WIN32)

  set(EXE_SSH windows/winplink windows/wincons ${NONSSH} ${WINSSH} ${W_BE_ALL}
    logging ${WINMISC} windows/winx11 windows/winnojmp noterm)

  set(RC_SSH windows/plink.rc)

  set(EXE_SCP pscp windows/winsftp windows/wincons ${WINSSH} ${BE_SSH} ${SFTP}
    wildcard ${WINMISC} windows/winnojmp)

  set(RC_SCP windows/pscp.rc)

  set(EXE_SFTP psftp windows/winsftp windows/wincons ${WINSSH} ${BE_SSH} ${SFTP}
    wildcard ${WINMISC} windows/winnojmp)

  set(RC_SFTP windows/psftp.rc)

  set(EXE_PUTTYGEN windows/winpgen sshrsag sshdssg sshprime sshdes sshbn
    sshmd5 version sshrand windows/winnoise sshsha windows/winstore misc
    windows/winctrls sshrsa sshdss windows/winmisc sshpubk sshaes sshsh256
    sshsh512 ${IMPORT} windows/winutils tree234 notiming windows/winhelp
    windows/winnojmp conf windows/wintime sshecc sshecdsag windows/winsecur)

  set(RC_PUTTYGEN windows/puttygen.rc)

  set(INC windows)

  set(DEFS _WINDOWS=1 WIN32=1 _WIN32=1 WINSOCK_TWO=1 NO_IPV6=1 _WIN32_IE=0x0500
	WINVER=0x0500 _WIN32_WINDOWS=0x0410 _WIN32_WINNT=0x0500)

  link_libraries(gdi32 comdlg32)
else ()

  set(EXE_SSH unix/uxplink unix/uxcons ${NONSSH} ${UXSSH} ${U_BE_ALL} logging
         ${UXMISC} unix/uxsignal unix/ux_x11 noterm unix/uxnogtk)

  set(EXE_SCP pscp unix/uxsftp unix/uxcons ${UXSSH} ${BE_SSH} ${SFTP} wildcard
	${UXMISC} unix/uxnogtk)

  set(EXE_SFTP psftp unix/uxsftp unix/uxcons ${UXSSH} ${BE_SSH} ${SFTP} wildcard
	${UXMISC} unix/uxnogtk)

  set(EXE_PUTTYGEN cmdgen sshrsag sshdssg sshprime sshdes sshbn sshmd5 version
    sshrand unix/uxnoise sshsha misc sshrsa sshdss unix/uxcons unix/uxstore
    unix/uxmisc sshpubk sshaes sshsh256 sshsh512 ${IMPORT} time
    tree234 unix/uxgen notiming conf sshecc sshecdsag unix/uxnogtk)

  set(INC unix charset)
  set(DEFS NO_LIBDL=1 NO_GSSAPI=1 NO_IPV6=1)
endif ()


# plink
add_executable(ssh $<JOIN:${EXE_SSH},.c >.c ${RC_SSH})
target_include_directories(ssh PRIVATE . ${INC})
target_compile_definitions(ssh PRIVATE ${DEFS})

# pscp
add_executable(scp $<JOIN:${EXE_SCP},.c >.c ${RC_SCP})
target_include_directories(scp PRIVATE . ${INC})
target_compile_definitions(scp PRIVATE ${DEFS})

# psftp
add_executable(sftp $<JOIN:${EXE_SFTP},.c >.c ${RC_SFTP})
target_include_directories(sftp PRIVATE . ${INC})
target_compile_definitions(sftp PRIVATE ${DEFS})

# puttygen
add_executable(puttygen $<JOIN:${EXE_PUTTYGEN},.c >.c ${RC_PUTTYGEN})
target_include_directories(puttygen PRIVATE . ${INC})
target_compile_definitions(puttygen PRIVATE ${DEFS})

install(TARGETS ssh scp sftp puttygen DESTINATION bin)
