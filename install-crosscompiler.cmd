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
@@cd %~dp0 & %WINDIR%\system32\windowspowershell\v1.0\powershell.exe -Command Invoke-Expression $([String]::Join(';',(Get-Content 'install-crosscompiler.cmd') -notmatch '^^@@.*$')) & goto :EOF

if ($args.count -lt 1) {
	[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
	$arch = [Microsoft.VisualBasic.Interaction]::InputBox('Enter target architecture (e.g., arm-linux-musleabi)', 'Install cross-compiler')
	bin\sh.exe ./etc/install-crosscompiler.sh $arch
} else {
	bin\sh.exe ./etc/install-crosscompiler.sh $args
}
