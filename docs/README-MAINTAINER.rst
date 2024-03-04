=========================
Development Documentation
=========================

Maintainers may be interested in the following topics:


Installation Without Pre-Built Archive (Bootstrap)
==================================================

TL;DR: run ``./etc/bootstrap/everything.sh`` to rebuild the entire toolchain
for Windows and Linux hosts, including a wide range of cross-compilers.

The bootstrap process will download and/or build the same GCC version for all
platforms (GCC 11.3.0 at the time of this writing).  It will also install a few
basic tools often required for building software, see below for a list.

NOTE: Bootstrapping is only supported on a plain Linux system with a basic set
of shell utilities.  The bootstrap process tries very hard to cope with any
known Linux variant and builds essential tools first in order to be as
independent of system environment as possible.

Bootstrapping using Linux in a virtual machine works (slowly), Windows
(including WSL) doesn't. Provide as many CPU cores as you can get, the build
environment uses them.

The build process uses ``ccache`` to speed up repeated builds. If you are
satisfied with your build, you might want to save space by deleting its cache
directory, ``.cache``.

Bootstrap actually happens in multiple stages, and some packages may be compiled
more than once, but the net result is that the final toolchain always has the
same tools (and versions) regardless of host CPU and operating system.



Packaging and Distribution
==========================

Since these toolchains use themselves for building, they have no dependencies on
the system they are running on.  They can be distributed in binary archives (but
mind the licensing note below).

To create base toolchain and cross-compiler archives, use script
``etc/package.sh <release-tag>``.  It will package up the current toolchain
environment in the exact state it is in, with all the currently installed
tools.  It will separate any cross-compilers into separate archives and
different host systems in separate subdirectories.

The resulting archives are placed in the ``release-<release-tag>`` subdirectory
alongside an install script for each platform. The generated install scripts
will download missing files from a canonical release server. They have SHA256
checksums hardcoded to ensure authenticity of downloaded binaries.

If you build additional cross-toolchains after packaging, runr
``package.sh <release-tag> -a``, which will package any new toolchain. It will
also update the core toolchain archives, as they contain all known SHA256
checksums, and the install scripts, as they contain the root SHA256 checksum.


Bootstrapping in individual steps
=================================

In case you have problems or want a more controlled setup of tools/compilers,
you can bootstrap in several individual steps.

The very first step is the initial bootstrap performed by
``./etc/bootstrap/initial.sh``. You can run ``./etc/bootstrap/clean.sh``
beforehand to remove all traces of previous builds.



Building Cross-Compiler Toolchains
==================================

Once the basic native toolchain is done, you can add cross-compilers. Run the
cross-toolchain build process like this::

    bin/sh etc/toolchain.sh <target> ...

Some examples for supported targets:
* arm-linux-musleabi
* x86_64-linux-muslx32
* x86_64-linux-musl
* i686-w64-mingw32
* x86_64-linux-gnu
* arm-linux-gnueabihf
* "arm-linux-musleabihf,--with-cpu=arm1176jzf-s --with-fpu=vfp --with-float=hard"

Note the last example: for ``musl`` targets, you can append compiler
configuration options to the target.

The GNU variants support shared linking.  This seems to defy the purpose of
these toolchains, but sometimes you might be forced to use binary-only shared
libraries.  The runtime linker path is configured so that you can dump a binary
and all of its dependent shared libraries in one directory and expect the binary
to work.  Script ``etc/package-dynamic.sh`` does all the neccessary work for
that.

You can also run ``etc/toolchain.sh`` without arguments to install a set of
default toolchains (x86/ARM/Windows/Linux).



Creating Toolchains for use on Other Platforms
==============================================

Once you have a working native toolchain environment, script
``./etc/bootstrap/bootstrap.sh`` allows you to build toolchain environments that
users on other platforms can use. Most notably, this way a Windows environment can be
created.  Right now, Windows is the only alternate host environment that is tested.



About Licensing
===============

Licensing is an inherently difficult topic, so below statements are only a
best-effort attempt to summarise open-source licensing terms that apply to the
programs built as part of the toolchain.  This document does not contain legal
advice and is not a substitute for professional legal advice.

When supplying *toolchain* binaries (e.g., the binary toolchain archives
mentioned earlier) to people outside your organisation, the GPL says you must
distribute the full source code alongside the binaries.  Downloaded source
archives are cached in subdirectory ``download-cache`` after building, so you could
just make the contents of that directory available alongside your binary
archives.

This does not apply to your *own* binaries produced with these toolchains.  Your
own source code and binaries primarily fall under their own respective licensing
terms.  GCC and its libraries will not affect that status if using the
toolchains as documented here.  Only the different C libraries impose additional
obligations:

Binaries using the musl C library (*-linux-musl* targets) need to obey a
permissive MIT-style license, which basically states that you need to include
its copyright notice, but othwerwise can do whatever you like.  Similar terms
apply for MinGW binaries (*-mingw* targets).  The GNU C library (*-linux-gnu*
targets) is more problematic, don't use it when distributing statically linked
proprietary code (in-house use is fine, only distribution is problematic).

Sources:
 * https://www.gnu.org/licenses/gcc-exception-faq.html
 * https://git.musl-libc.org/cgit/musl/tree/COPYRIGHT
 * http://www.mingw.org/license
 * https://lwn.net/Articles/117972/

