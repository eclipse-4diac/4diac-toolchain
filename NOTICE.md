# Notices for Eclipse 4DIAC

This content is produced and maintained by the Eclipse 4DIAC project.

* Project home: https://projects.eclipse.org/projects/iot.4diac

## Trademarks

 Eclipse 4DIAC is a trademark of the Eclipse Foundation.

## Copyright

All content is the property of the respective authors or their employers. For
more information regarding authorship of content, please consult the listed
source code repository logs.

## Declared Project Licenses

This program and the accompanying materials are made available under the terms
of the Eclipse Public License v. 2.0 which is available at
https://www.eclipse.org/legal/epl-2.0.

SPDX-License-Identifier: EPL-2.0

## Source Code

The project maintains the following source code repositories:

* https://github.com/eclipse-4diac/4diac-toolchain

## Third-party Content

This project leverages third party content in the following way:

No third-party content is included in the source code itself, and the core
infrastructure does not use third-party software beyond a standard shell
environment. During build/setup, a variety of reputable open-source software
packages are downloaded and built, depending on user choices.

During build/setup, this software uses at a minimum the external software
packages `busybox`, `make`, `gcc`, `cmake`, `libressl`, `ccache`, `curl`, and
`ninja`. Depending on user configuration, additional packages may be built.
These packages represent a major part of the end-user visible functionality
of this software. The list of external packages including download location
and build configuration is available in subdirectory `etc/cget/recipes`, with
one directory per third-party software package.

Source code is downloaded from the authoritative download servers or source
code repositories. In some cases, minor compatibility patches are applied.
Version pinning via cryptographically secure checksums are used to ensure
reproducibility and authenticity.

Licenses for third-party packages vary. At the time of this writing, all
downloaded packages allow legal free usage in commercial and non-commercial
settings and do not proliferate licensing terms to user code when used in the
documented way. That being said, it is solely the user's responsibility to
check if the licenses of third-party packages allow usage in the user's
setting.


## Cryptography

Content may contain encryption software. The country in which you are currently
may have restrictions on the import, possession, and use, and/or re-export to
another country, of encryption software. BEFORE using any encryption software,
please check the country's laws, regulations and policies concerning the import,
possession, or use, and re-export of encryption software, to see if this is
permitted.
