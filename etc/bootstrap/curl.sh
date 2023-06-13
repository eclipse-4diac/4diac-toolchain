#!/bin/sh
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
#
# minimalistic shell+cmake curl drop-in for bootstrap

dir="$(cd "$(dirname "$0")"; pwd)"
while [ "$#" -gt 0 ]; do
	case "$1" in
		-o) out="$2"; shift;;
		-*) ;;
		*) url="$1";;
	esac
	shift
done
if [ -z "$out" -o -z "$url" -o -n "${url%%http*://*.*/*}" ]; then
	echo "This command line is not supported" >&2
	exit 1
fi
echo "Downloading $url => $out"
exec cmake -Dfile="$(cd "$(dirname "$out")"; pwd)/${out##*/}" -DURL="$url" -P "$dir/../etc/cget/cget.sh"
