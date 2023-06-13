@@cd %~dp0 & %WINDIR%\system32\windowspowershell\v1.0\powershell.exe -Command Invoke-Expression $([String]::Join(';',(Get-Content 'install-toolchain.cmd') -notmatch '^^@@.*EOF$')) & goto :EOF
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

"Checking toolchain installation..."

if (-not (Test-Path "bin\sh.exe")) {

	if (-not (Test-Path "Windows-toolchain-x86_64-w64-mingw32.zip")) {
		""
		"======================================================================"
		""
		"ERROR: You need a base toolchain archive to install. You should get it"
		"wherever you got this file."
		"The file you need is called Windows-toolchain-x86_64-w64-mingw32.zip"
		""
		"======================================================================"
		""
		Read-Host -Prompt "Press Enter to exit"
		exit

	} else {
		if (Test-Path "Linux-toolchain-x86_64-linux-musl.tar.gz") {
			""
			"======================================================================"
			""
			"ERROR: Copy ONLY the required files (e.g. all Windows-* files) to an"
			"empty folder and run this script again."
			""
			"======================================================================"
			""
			Read-Host -Prompt "Press Enter to exit"
			exit
		}

		"Extracting toolchain environment..."
		$arch = [System.IO.Path]::Combine($PWD, "Windows-toolchain-x86_64-w64-mingw32.zip")
		$shap = New-Object -com Shell.Application
		$src = $shap.NameSpace($arch)
		$dest = $shap.NameSpace("$PWD\")
		$dest.CopyHere($src.Items(), 24)

		New-Item ".cache" -Force -ItemType Directory
		Move-Item $arch -Destination ".cache"
	}

	copy C:\Windows\system32\cmd.exe bin\cmd.exe
	bin\busybox.exe --install bin\
}
bin\sh.exe ./etc/install-crosscompiler.sh

""
""
Read-Host -Prompt "Press Enter to exit"
