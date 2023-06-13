/********************************************************************************
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

// Creates an executable that runs a shell script of the same name
// (sans .exe), emulating the script calling convention of Linux on Windows

#include <wchar.h>
#include <windows.h>
#include <shlwapi.h>

int WINAPI wWinMain(HINSTANCE i, HINSTANCE p, PWSTR cmdline, int s) {
	wchar_t filename[MAX_PATH];
	if (!GetModuleFileName(NULL, filename, MAX_PATH)) return 1;
	wchar_t *dot = wcsrchr(filename, '.');
	if (dot) *dot = 0;
	PathQuoteSpaces(filename);

	PWSTR newcmdline = malloc((wcslen(cmdline)+wcslen(filename)+10)*sizeof(filename[0]));
	wcscpy(newcmdline, L"sh.exe ");
	wcscat(newcmdline, filename);
	wcscat(newcmdline, L" ");
	wcscat(newcmdline, cmdline);

	OutputDebugString(newcmdline);

	STARTUPINFO si;
	memset(&si, 0, sizeof(si));
	si.cb = sizeof(si);
	PROCESS_INFORMATION pi;
	if (!CreateProcess(NULL, newcmdline, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) return 1;
	if (WaitForSingleObject(pi.hProcess, INFINITE)) return 1;
	DWORD rc = 1;
	if (!GetExitCodeProcess(pi.hProcess, &rc)) return 1;
	return rc;
}
