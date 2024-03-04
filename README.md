Reliable Cross-Platform Cross-Compilation Toolchains
====================================================

This repository contains a build environment that sets up native and
cross-compilation toolchains for reproducible builds without any system library
dependencies.  Tested host OSes are Windows (32/64-bit) and Linux (x86 64-bit),
tested target OSes are Windows (32-bit) and Linux (x86 and ARM).

Toolchains are set up for fully static linking for Linux targets and mostly
static for windows targets (only stock system DLLs are needed).  Thus, binaries
produced by these toolchains can easily be transferred to other systems and run
there.  It should even be possible to run x86_64 Linux binaries on FreeBSD due
to the Linux syscall emulation in FreeBSD (this is untested).

Toolchains are set up for easy cross-compilation via CMake, which is also used
by the bootstrap process itself (via the highly recommended cget utility).
Ninja is available and recommended as build driver.

Finally, the toolchain also provides native versions of GNU make and busybox in
order to compile non-CMake software in a reproducible environment regardless of
OS.


Installation
============

If using this as part of the 4diac FORTE build environment (4diac-fbe), you
don't need to do anything, 4diac-fbe handles this automatically for you.

When using this as a standalone toolchain, the easiest way to install the
toolchain environment is through a binary release. Check out the `release`
branch of `4diac-toolchains` and run `etc/install-Linux.sh` or
`etc/install-Windows.cmd` (as appropriate). This will securely download and
install a pre-built release of the base toolchain for native compilation. To
install cross-compilers for additional targets, see below.

These packages do not need administrative rights and can be installed into
any folder.  In fact, there is no actual installation, you can extract the
binary archive wherever you want and it works out of the box.

Some recommendations: You should use a new, empty folder as destination.  As
some programs do not like spaces in file names or very long path names, try
to use a destination path that is short and without any spaces anywhere.


Adding cross-compiler toolchains later
======================================

Use `./install-crosscompiler.sh` (or `.cmd` on Windows) to add pre-built
cross-compilers. See `etc/crosscompilers.sha256sum` for a list of available
targets. If your target is not available as a pre-built release, use `bin/sh
etc/toolchain.sh <target-triple>` to build one from source. This probably
only works on Linux, so write a ticket in the issue tracker if you need
another target on Windows.


Usage with plain CMake
======================

After bootstrap, use any of the top-level ``*.cmake`` files as
``CMAKE_TOOLCHAIN_FILE``.  For best cross-platform compatibility, use the
provided Ninja as build system.  You can even set ``PATH`` to just the toolchain
build directory, it should contain everything needed for building your code.
That will yield a predictable build environment across all supported
machines/OSes.

Example::

    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAINS/native-toolchain.cmake" .
	ninja


Usage with other plain code
===========================

The toolchains directory contains a script that sets up canonical environment
variables for a given (cross-)compiler. Some of the variables are CC, CXX,
CFLAGS, CXXFLAGS, and so on. Most build systems honour these.

Example::

    …/toolchains/cross-env.sh arm-linux-musleabihf

On Windows hosts, run this from ``bin\sh.exe``.

In order to make builds isolated and reproducable, the script will open a new
shell with an environment that tries very hard to prevent that system files are
used by accident. Since this toolchain contains a predictable and reasonably
complete shell environment on all supported platforms, this new shell should be
sufficient to build most code out there.

The ``cross-env.sh`` script also supports sourcing instead of executing, but
that is not fully documented right now. Follow the on-screen messages if you use
this mode.


Usage with CGet
===============

If you want to manage multiple packages with dependencies, CGet is a good
solution to do so -- in fact, this entire toolchain is built with CGet.

See http://cget.readthedocs.io/en/latest/ for more information on CGet.  For
some samples, look at ``etc/cget/recipes`` for the CGet recipes for the
toolchain itself; useful examples are:

 * cmake: how to build a CMake-based package with some cross-compilation fixups
 * m4: how to build a basic GNU autoconf-package
 * ninja: how to build a package using none of these by hand

This toolchain contains a stand-alone re-implementation of CGet that is easier
to distribute in binary archives.  It only needs basic shell tools and should be
drop-in compatible to the official CGet (minus some exotic features).

The bundled cget should behave like the original, except for one addition:
subcommand ``init`` has a new command line option ``--ccache``, which enables
ccache for that cget prefix.

You can use shell scripts to automate/orchestrate your top-level cget builds in
a cross-platform way. Example::

    # prepare default environment
    . …/toolchains/set-path.sh arm-linux-musleabihf
    cget_init

    # default config in current directory
    cget install my-fancy-package # assumes you have a etc/cget/recipes dir


List of available tools
=======================

A full toolchain build also includes various generic build and development
tools.  At the time of this writing, included are:

 * A complete POSIX-like shell environment with many extra tools (busybox)
 * extra compression tools (lzip, 7zip)
 * cmake, GNU make, and ninja
 * ccache (config in subdirectory ``etc``, cache in ``.cache/ccache``)
 * curl (with SSL support)
 * flex and byacc
 * git
 * python (stripped down: no pip, no dynamic module loading)
 * ssh, scp, sftp (putty-based versions)


Internals
=========

Additional documentation for maintainers is in ``docs/README-MAINTAINER.rst``.
It also contains information on how to bootstrap a toolchain without pre-built
binary archives.


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
