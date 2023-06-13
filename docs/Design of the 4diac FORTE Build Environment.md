Design of the 4diac FORTE Build Environment
===========================================

> Jörg Walter \
> OFFIS -- Institute for Information Technology \
> Oldenburg, Germany \
> joerg.walter@offis.de \
> 2022-07-20


Introduction
------------

For a variety of reasons, Eclipse 4diac requires users to rebuild the runtime
environment FORTE regularly. While there is some work into reducing the
frequency of such rebuilds (e.g. via dynamic types), some use cases
inherently require occasional recompilation (e.g. interfacing 3rd party code
via SIFBs). A vendor-supplied generic FORTE binary (e.g. as part of a
device's preinstalled software) does not fit into the core design of Eclipse
4diac. Such an approach would limit the power of 4diac significantly,
especially regarding its excellent extensibility.

This means that recompiling the FORTE runtime is something that average users
of Eclipse 4diac will have to do on a semi-regular basis. Compiling C++ code
isn't rocket science, but neither is it a trivial endeavour, especially when
3rd party dependencies are needed for certain FORTE features
(e.g. communication protocols or I/O modules).

Unlike Python or node.js, the C++ software ecosystem does not have a
universally accepted packaging system of platform, not even a widely adopted
one. Furthermore, FORTE targets a variety of developer (host) and device
(target) platforms, compilers, and operating systems, including targets that
don't have a traditional general-purpose operating system at all.

This makes building FORTE challenging. Installing the build tools varies
across host and target platforms. Installing 3rd party dependencies ranges
from "pretty straightforward" through "nearly unachievable by mortals". New
users often spend days of their time to get an initial build up and running,
not including any optional dependency libraries.

The overall goal of the 4diac FORTE Build Environment (FBE) is to give new
users a single, fully integrated software package that enables them to easily
build FORTE binaries across all sensible use cases and on all host platforms,
with bit-by-bit reproducibility. As a long-term goal, it should be possible
to distribute the FBE alongside 4diac IDE releases so that no separate
download/installation is needed and building FORTE can become an invisible
automatic background process.

This document will explain the design goals for the FBE, show why some of the
better-known tools in the solution space do not meet these goals, and finally
give details on the final design choices. As far as evaluation goes, this
document will *not* provide a systematic user study. However, the FBE has been
in use at OFFIS for more than four years, enabling us to do many student
projects with very short onboarding times. Throughout the text there will be
occasional references to observations and experiences collected in that time.


Design Goals
------------

### Expected Usage

The users targeted by the FBE fall into four categories:

1. Corporate/industrial users that use 4diac for production systems
2. Students and Teachers using 4diac in schools and universities
3. Scientists using 4diac to perform IEC 61499-related research
4. Developers of 4diac


### Summary of Goals

With respect to these four user groups, the overarching design goal of the
4diac FORTE Build Environment (FBE) is to facilitate

1. *fully automatic* building of FORTE binaries
2. for *all supported target platforms*
3. using *any combination of optional dependencies*,
4. *everywhere* where users can be expected to use 4diac IDE.

From Goal 4 follows that the FBE must run on

5. *all supported host systems*
6. including *very old systems* that might still be in use,
7. and it must be usable *without administrative privileges*.

The only viable path towards this goal is

8. nearly complete *host system independence*
9. with a *fully reproducible* build system.

Deployment is currently not handled by 4diac tools, but experience with state
of the art tools suggests that 

10. *output artifacts should be fully self-contained*.

Where it doesn't conflict with the above goals, it should try to provide fast
build times and a reasonable level of ease-of-use.


### Discussion

This subsection explains the above goals in some more detail. Features that
are labeled as "Ideally" are optional goals that may not be part of the
current state of the build environment, but design decisions should allow
future extension in that direction.


#### 1: Fully Automatic Builds

The long-term goal is that a suitable runtime binary can be generated in the
background while using 4diac IDE, so that users do not need to worry about
this process at all. Since the very point of rebuilding FORTE is to customize
it, there must be some form of customization/configuration management.

For developers and industrial users, a more agile workflow with Continuous
Integration (CI) infrastructure is important, which also requires automatic
builds.


#### 2: Cross-Compilation

Since many use cases exist where the control software is not run on the system
it was developed, the FBE must support creating runtime binaries for all
possible target systems. In case of targets without general-purpose operating
system (e.g. FreeRTOS-based targets), this should include building the
appropriate bootable image.

Users should also be able to specify target-specific compilation options,
which should apply to all code built during the build process.


#### 3: Configuration and Dependency Management

As far as possible, the FBE should be able to build all dependencies that
FORTE can optionally use when enabling certain features of the runtime. It
should also be able to manage configuration options in any combination,
ideally for multiple output binaries. Users writing their own FORTE modules
should be able to extend this build system.

Some targets or hardware interfaces may require proprietary software that
cannot be integrated into the build environment for legal reasons. The FBE
should be able to work with such external software packages; it is
permissible that this may be more difficult to set up than normal usage.


#### 4: Everywhere

Users of the four identified user groups should all be able to use the FBE as
their primary, most productive build tool. Windows and Linux are the primary
platforms, but it should be able to port this to any other Desktop OS as
well (e.g. MacOS or FreeBSD). Ideally, it could even run on Android.


#### 5: Host System Independence

For the long-term goal of full integration into 4diac IDE, the FBE must run on
all supported host (developer) operating systems. It should require no host
system dependencies except for a minimal/default installation of the
corresponding operating system, i.e. no add-on software beyond 4diac, no
tight version requirements.


#### 6: Legacy System Support

The FBE should work on pretty old (host) systems. 10 year old installations do
exist in the wild: Corporate users may be stuck on old but stable systems,
and under-funded teaching institutions might be forced to work with ancient
equipment.

For Linux this should cover at least 10 years of any Linux distribution that
roughly adheres to Linux Standard Base conventions; support for diverging
Linux environments like NixOS or Android would be a nice bonus. For Windows
this should include Windows 7; Windows XP would be a nice bonus.


#### 7: User Privileges Only

In corporate and teaching scenarios, multi-user machines and/or machines with
tight access controls are common. 4diac IDE runs without installing anything
to access-restricted locations, so the FBE should do so, too.

We can't do anything if users are not allowed to run 3rd party software at
all -- in that case 4diac IDE would not run either. But even in such a
scenario, a behaviour that does not rely on privileged system components will
help administrators assess and manage 4diac/FBE installations for their
users.


#### 9: Fully Reproducible Builds

In single-user settings, high reproducibility of builds means that the build
process should never fail due to factors that stem from the diversity of
(supported) developer systems.

In CI settings, a high level of reproducibility is beneficial for testing
purposes. Ideally the FBE produces bit-identical reproducible artifacts
independent of host platform.

This also means that there must be a way to specify build configurations,
ideally having a customizable set of configurations to choose from.
Furthermore, the integrity of all source code should be verified, for example
via checksums.


#### 10: Self-Contained Output

Deployment is the final obstacle to get FORTE binaries up and running. For
cross-compilation scenarios, this means that there is another set of system
dependencies involved, that of the target system. Notably, embedded targets
can have quite unconventional software configurations (Embedded Windows,
minimized Linux installations, ancient system software, etc.). Furthermore,
being fully self-contained improves the chance that the output will be
compatible with any given deployment infrastructure that users might have in
place, from scp to Eclipse hawkBit.

Therefore, output artifacts should be as system-independent as the build
environment itself (see Goal #5). Ideally, the resulting FORTE is a single
binary that does not depend on any user-space system libraries and that works
with reasonably old kernel APIs (Windows XP / Linux 2.6). For embedded
RTOSes, it would be desirable to get a bootable image in whatever format the
target may require.


#### Secondary Goal: Performance

The FBE should try to reduce build times. Caching and dependency management
should help in avoiding unneccessary recompilation. However, there should be
no false positives: If any build artifact doesn't get updated even though it
should have been, users will disable the caching and dependency management
systems.


Related Work
------------

There are several existing technologies that address similar problems.

The Linux ecosystem probably has the most mature package management
infrastructure of all software ecosystems. Linux distributions excel at
resolving complex dependency chains, dealing with difficult upgrade
scenarios, and managing compatibilities and conflicts. However, they assume
that there is a small set of target platforms, whereas FORTE configuration
variants are virtually infinite due to the large number of configuration
options and compiler settings. This precludes using precompiled libraries
from Linux distributions, and wouldn't solve the problem for Windows targets
either.

Customized Linux build systems like Buildroot and BitBake almost fit the bill.
However, these are very much not host system independent. Real-world
experience with these shows that these are much too dependent on system
software versions(compilers, libraries). For example, when trying to build a
2019 PetaLinux(which is based on BitBake) on a fully up-to-date Linux system
in 2021, you can spend days of developer time fixing bugs introduced through
compiler and library version changes until finally giving up. In fact, the
recommended way to use them is via a container image of a reference Linux
distribution. Windows is also not supported unless trying to use a Linux
container.

Containers in general (e.g. Docker or Podman) are great tools to get host
system independence. They also provide some Windows compatibility. For CI
scenarios, they are well suited and the de-facto standard. However, they
either require complicated setup, administrative privileges, or both,
violating multiple design goals (primarily #6 and #7). They also lower
compatibility with older or uncommon systems (Goals #4 and #5).

The C++ world has various proposed package management systems, but no
obviously dominating one. In fact, the core of the FBE is built around one of
these, with some pragmatic reasons for the choice outlined in the next
section. The others were not significantly worse, they just happened to fit
less in some of the goals; most didn't support cross-compilation with
multiple configurations (Goal #2) as well as the tool that was chosen in the
end.

Finally, there is old-school BSD-like package management just using a build
tool like `make`. This does have some advantages, but in its bare form it is
too inflexible. Nevertheless, the FBE keeps the idea of a build tool as its
central workhorse.


The FORTE Build Environment
---------------------------

From the specified goals and the assessment of related work results the final
design of the FORTE Build Environment (FBE):

### Overview

A top-level executable script is the primary (and for most users sole) entry
point to FBE functionality. Users can specify build options in text-based
configuration files and add new dependencies by adding cget recipes.

The FBE uses cget as a package management tool, which in turn uses CMake to
manage builds themselves to produce statically-linked FORTE binaries. It
doesn't use any system libraries to build FORTE executables, it builds all
dependencies from scratch and uses only those. It also doesn't use any system
tools for the build process itself. It contains a build toolchain that
contains all neccessary programs.

The entire environment is supposed to be distributed in binary form. Its
binaries achieve complete system independence on Windows (XP and up) and
Linux (2.6 and later), other platforms are not yet supported.
POSIX-compatible platforms like MacOS or BSD are probably easy to add.


#### Intended Workflow

The FBE contains a top-level build script called `compile.sh` (or `compile.cmd`
on Windows). In the most basic case, users simply start this script
(double-clicking on windows works fine), and the FBE builds two FORTE
binaries that run on the host system: one in release mode and one with full
debug options enabled. These binaries are configured by default with all
possible features enabled.

In order to build FORTE binaries for other systems or with a controlled set of
features, users create a configuration file in subdirectory `configurations`.
Running the compile script again will then build one executable per config
file. An optional command line argument specifies a specific configuration to
build.

For each configuration, the build system creates subdirectories
`build/<config-name>/...`, with the final binary residing in
`build/<config-name>/output/bin`. A top-level README file explains this
workflow with all its optional features.


#### Configuration Management

The config files are plain text files that contain arbitrary CMake
configuration options, one per line, plus a few special directives for
convenience, dependencies, and target management. 

One configuration file corresponds to one FORTE executable. For easier reuse
between multiple configurations, there is an include mechanism for shared
configuration file fragments. 

Configuration files can be organized in subdirectories, and calling the build
script with a directory as command-line argument will build all configurations
in that directory.


#### Package and Build Management

As mentioned above, the FBE manages its packages through cget
(https://cget.readthedocs.io). cget uses the cross-platform properties of the
build tool CMake to provide flexible and easy cross-compilation builds. It
adds proper package and dependency management on top. For each build target,
it manages a self-contained installation directory where it can build,
install, update, and remove packages, although most FBE users will not be
aware of these features.

cget works with so-called *recipes* that describe build commands. These are
just cmake scripts, and if a package already uses CMake then the recipe can
be very short or it may even be left out. Within a recipe, there are also
instructions how to fetch code (authenticated via checksums), and what
other packages a given recipe depends on.

When extending FORTE, it may be required to write new recipes. The current
state of the FBE includes many different packages in a variety of
difficulties. These can serve as templates. The cget author also provides a
sizeable list of recipes for many more C/C++ packages:
https://github.com/pfultz2/cget-recipes/tree/master/recipes

The original cget is written in python, but this made bootstrap complex. On
the other hand, most of cget's functionality is actually provided by CMake
itself, and there is also the POSIX shell language that is required by
virtually all C/C++ build processes. Therefore, the FBE includes a small but
fully compatible reimplementation of cget written in the POSIX shell script
language. This removes one core dependency and so the FBE only uses two
languages: POSIX shell script for its core tools and the CMake build language
for recipes.


#### Host Toolchain

The FBE actually consists of two parts that are only loosely coupled: the
primary build script with recipes for FORTE binaries, and a toolchain with
generic build tools. The toolchain contains all host tools needed to run
FORTE builds in any configuration including dependencies. However, except for
the fact that it only contains build tools needed for FORTE and its
dependencies, it is completely independent of FORTE.

The host toolchain uses GCC (version 10 at the time of this writing) as its
compiler. All host/target platform combinations use the exact same version of
GCC, so it is safe to use `-Werror` for development -- your build will not
fail simply because a version upgrade introduced a new kind of warning.

Also, tools are built with options for reproductible builds, so a given FORTE
configuration should always result in a bit-identical file across all build
(host) systems.

For basic POSIX command line tools, the toolchain uses a windows port of
busybox; for identical command-line behaviour, the same port is used on
Linux. It gives enough shell compatibility for common configuration scripts.
In order to reduce the dependency tree, some other build tools are also
reduced/smaller variants of more common counterparts. Most build tools are
exactly what everyone else uses, however.

The toolchain even includes a full Python 3 interpreter, but since everything
is statically linked, add-on modules that use native code will not work.


#### Bootstrap

Building the FBE boils down to building the toolchain. This is a lengthy
process that is not suitable for users of the FBE, so the intended usage is
to release binary packages for each supported host platform.

The FBE itself is produced through its own build engine in a bootstrap
process. This means that the FBE itself and the FORTE binaries it produces
are in the same way system-independent. It also means that there is only one
build system for both parts, making it well-tested. While usually only FBE
developers would perform the bootstrap process, the package build
instructions are tiny, so every copy of the FBE contains the complete code
required to rebuild itself.

Bootstrap cannot fulfill the goal of host system independence by its very
nature, so the FBE makes some minor concessions. Bootstrapping is only
supported on Linux systems that provide basic system tools (POSIX shell
utilities and one of a variety of common download tools). Initial bootstrap
builds a toolchain for the current system (i.e. Linux), afterwards
maintainers can cross-bootstrap toolchains for other host systems
(e.g. Windows).

For maximum portability and reproducibility, this process reuses as much of
the cget infrastructure as possible. Therefore bootstrap proceeds in three
stages:

1. Set up an initial build environment by downloading a specific precompiled
version of GCC. This step and the next one require some basic system tools
(POSIX-compatible shell utilities). These downloads are authenticated via
checksums just like regular cget recipes.

2. Perform a first-stage boostrap that results in just enough tools to build
the actual toolchain. This builds GNU Make and a bootstrap CMake by hand, then
switches to cget for all remaining tools. After this step is done, no system
tools are used anymore.

3. Use the regular cget-based build system to build the complete FBE

4. Optional: Build cross-compilers for as many platforms as you like.

5. Optional: Repeat Step 3 and 4 for other FBE host platforms (i.e. Windows).

The result are compressed archives and an installation script that will unpack
the archives into the current directory. Cross-compilers are separate
archives, so that users only need to download what they want to use. The base
toolchain without cross-compiler is about 200MB compressed, each
cross-compiler adds about 60MB.


### Relation to Goals

#### 1: Fully Automatic Builds

The top-level build script manages all build steps based on the configuration
files. There is no user intervention needed (or possible). The configuration
file language even includes a basic hack for automated deployment.


#### 2: Cross-Compilation

CMake contains a robust cross-compilation mechanism through so-called
toolchain files. The toolchain bootstrap process creates matching toolchain
files, and the build wrapper selects the appropriate configuration options
for CMake based on a setting in the configuration file. Some cget recipes may
need to be adapted to support cross-compilation, but a CMake file written
according to best practices will automatically work in cross-compilation
settings.

For more exotic (e.g. deeply embedded) targets, configuration files can also
specify compiler flags to use. General-purpose OS targets should not have a
need to do so, toolchain files should already contain all recommended flags.


#### 3: Configuration and Dependency Management

The configuration file system is simple yet full-featured and easy to parse or
generate, should additional tooling be desired. cget provides built-in
dependency management.

For proprietary dependencies that cannot be included as a gcget recipe, the
config file language provides sufficient options to include external
dependencies. This requires some experience with compiler flags.


#### 4: Everywhere

The FBE uses config files and the build script as its sole user interface, so
this poses no portability problems. Providing a richer user interface is out
of scope; the long-term goal would be to have some sort of automated
integration into 4diac IDE. But even without an additional user interface,
all user groups already save significant amounts of time using the FBE.


#### 5: Host System Independence

Since the toolchain itself is as portable as the generated FORTE binaries,
there is no restriction on where it is run. Executables use no system tools
or libraries at all, only stock kernel APIs.


#### 6: Legacy System Support

Due to the degree of host system independence, the FBE should run on ancient
Linux systems, Android, or Windows XP likewise. Windows XP compatibility is
be fragile, however: There is a trend in software packages to disregard
Windows XP as supported target and use some useful newer kernel APIs. This is
beyond FBEs scope of influence.


#### 7: User Privileges Only

The toolchain is configured to be location-independent. It uses no privileged
kernel APIs and no files in fixed locations that could conflict with other
users or even multiple installations of the FBE.


#### 9: Fully Reproducible Builds

All source code (including initial bootstrap) is authenticated via SHA256
checksums. GCC and binutils are configured for reproducible builds, which
means they will not record timestamps in generated files, which they usually
do. Since the exact same compiler version is used across all host platforms,
output artifacts should be bit-identical no matter which host system they
were built on.


#### 10: Self-Contained Output

The main mechanism for system independence (both host and target) is static
linking. All executables and libraries are statically linked. On Linux, this
uses the musl C library, which is a full-featured modern C library that
explicitly supports static linking (unlike the traditional GNU C library). On
Windows, this uses the MinGW compiler infrastructure which directly uses
Windows system APIs.

For situations where users need to (dynamically) link against an external
pre-compiled Linux library, there is a separate compiler variant that uses
the standard GNU C library. Even in this case, the build script tries to make
this relocatable and self-contained by copying all dependent libraries into
the output directory, but this is may miss some dependencies in some corner
cases.


#### Secondary Goal: Performance

The FBE reuses intermediate results with robust dependency tracking. Build
trees of FORTE itself are kept and reused, so that the actual build tools
will only rebuild those parts that have actually changed. Changes in
configuration files will result in their corresponding build directories
being deleted and rebuilt from scratch. A rebuild of FORTE after a small
change need less than a minute of overall build time, a few seconds at best.

Additionaly, the toolchain includes ccache, a well-known program that caches
compilation output files, so even complete rebuilds will be faster than
initial builds.

Both mechanisms have in common that they err on the side of caution, never
risking reusing a stale cached result that could be inappropriate to the
current configuration.

Downloads are cached as well. It is possible to distribute a common download
cache in-house to speed up installations.


License
-------

This section only contains an intuitive judgement by the author. It does not
constitute legal advice. Refer to your legal department or a lawyer for
definitve answers.

The FBE tools themselves are licensed under the Eclipse Public License. Build
recipes may contain patches or configuration file fragments, however. This is
inevitable for any build system that manages lots of dependencies. Depending
on licensing terms and jurisdiction this might make the overall FBE source
code more restrictively licensed.

A fully bootstrapped toolchain most definitely contain parts that are licensed
under the GNU General Public License (GPL), thus if you distribute a binary
FBE outside your organisation, you are (at a minimum) obliged to provide all
source code as well. This is inevitable with the variety of build tools
required for full-featured FORTE builds. However, the download cache is a
complete collection of source code archives so it could possibly serve to
fulfill this obligation. Furthermore, binary FBE builds retain complete build
instructions with all recipes they were built from.

GPL restrictions do not (neccessarily) apply to the output FORTE binaries. If
you only use permissively-licensed dependencies, the resulting FORTE binary
will be unencumbered by GPL licensing terms and can be freely distributed in
binary-only form. It is the user's obligation to check and adhere to all
licensing terms their specific FORTE configuration might require.

