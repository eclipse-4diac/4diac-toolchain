@@REM ********************************************************************************
@@REM  Copyright (c) 2018,2024 OFFIS e.V.
@@REM 
@@REM  This program and the accompanying materials are made available under the
@@REM  terms of the Eclipse Public License 2.0 which is available at
@@REM  http://www.eclipse.org/legal/epl-2.0.
@@REM 
@@REM  SPDX-License-Identifier: EPL-2.0
@@REM  
@@REM  Contributors:
@@REM     Jörg Walter - initial implementation
@@REM  *******************************************************************************/
@@cd %~dp0 & %WINDIR%\system32\windowspowershell\v1.0\powershell.exe -Command Invoke-Expression $([String]::Join(';',(Get-Content %~nx0) -notmatch '^^@@.*$')) & goto :EOF

if (Test-Path "cget\cget.sh") {
	cd ..
}

if (-not (Test-Path "bin\sh.exe")) {
	$baseurl = "https://sourceforge.net/projects/fordiac/files/4diac-fbe"
	$release='2024-02'
	$hash='ff39a329f3fed746fac6561a653ca7c74368d78e2478d12263665a4b7668b608'
	$download = "Windows-toolchain-x86_64-w64-mingw32.zip"

	if (-not (Test-Path "$download")) {
		"Downloading $baseurl/$release/Windows-toolchain-x86_64-w64-mingw32.zip/download..."
		Invoke-WebRequest -UserAgent "curl/7.54.1" "$baseurl/release-$release/Windows-toolchain-x86_64-w64-mingw32.zip/download" -OutFile "$download"
	}

	if ((Get-FileHash "$download").Hash -ne "$hash") {
		"ERROR: Downloaded file does not match expected hash value."
		Read-Host -Prompt "Press Enter to exit"
		Move-Item -Force "$download" -Destination "$download.broken"
		exit 1
	}

	"Extracting toolchain environment..."
	$shap = New-Object -com Shell.Application
	$src = $shap.NameSpace("$PWD\$download")
	$dest = $shap.NameSpace("$PWD\")
	$dest.CopyHere($src.Items(), 0x10)

	copy C:\Windows\system32\cmd.exe bin\cmd.exe
	bin\busybox.exe --install bin\

	bin\mkdir.exe -p ".cache/sha256-$hash"
	bin\mv.exe "$download" ".cache\sha256-$hash\Windows-toolchain-x86_64-w64-mingw32.zip"
	bin\rm.exe *-toolchain-*.tar.gz
	bin\sh.exe ./install-crosscompiler.sh
}

""
""
Read-Host -Prompt "Installation successful. Press Enter to exit"
