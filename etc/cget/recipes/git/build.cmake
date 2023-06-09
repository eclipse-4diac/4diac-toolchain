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

project(git C)
cmake_minimum_required(VERSION 3.5)

include(toolchain-utils)

if (WIN32)
  add_compile_options(-Wno-cpp)
  add_definitions(-DNO_SETENV -DNO_MKDTEMP -DNO_MEMMEM
	  -DNO_STRCASESTR -DNO_PREAD -D_WIN32_WINNT=0x0599)
  link_libraries(ws2_32 crypt32)
  set(COMPAT compat/setenv.c compat/mkdtemp.c compat/memmem.c
	  compat/strcasestr.c compat/pread.c compat/mingw.c compat/winansi.c)
endif ()

file(READ compat/mingw.h PATCHING)
file(WRITE compat/mingw.h "${PATCHING}\n#undef ERROR\n#undef ALTERNATE\n")
# mingw doesn't have this, and why at all?
patch(git-compat-util.h "#include <syslog.h>" "")

# List of source files taken from the Makefile
add_library(gitlib STATIC
  ${COMPAT}
  abspath.c
  advice.c
  alias.c
  alloc.c
  apply.c
  archive.c
  archive-tar.c
  archive-zip.c
  argv-array.c
  attr.c
  base85.c
  bisect.c
  blame.c
  blob.c
  branch.c
  bulk-checkin.c
  bundle.c
  cache-tree.c
  color.c
  column.c
  combine-diff.c
  commit.c
  compat/obstack.c
  compat/terminal.c
  config.c
  connect.c
  connected.c
  convert.c
  copy.c
  credential.c
  csum-file.c
  ctype.c
  date.c
  decorate.c
  diffcore-break.c
  diffcore-delta.c
  diffcore-order.c
  diffcore-pickaxe.c
  diffcore-rename.c
  diff-delta.c
  diff-lib.c
  diff-no-index.c
  diff.c
  dir.c
  dir-iterator.c
  editor.c
  entry.c
  environment.c
  ewah/bitmap.c
  ewah/ewah_bitmap.c
  ewah/ewah_io.c
  ewah/ewah_rlw.c
  exec_cmd.c
  fetch-pack.c
  fsck.c
  gettext.c
  gpg-interface.c
  graph.c
  grep.c
  hashmap.c
  help.c
  hex.c
  ident.c
  kwset.c
  levenshtein.c
  line-log.c
  line-range.c
  list-objects.c
  ll-merge.c
  lockfile.c
  log-tree.c
  mailinfo.c
  mailmap.c
  match-trees.c
  merge.c
  merge-blobs.c
  merge-recursive.c
  mergesort.c
  mru.c
  name-hash.c
  notes.c
  notes-cache.c
  notes-merge.c
  notes-utils.c
  object.c
  oidset.c
  pack-bitmap.c
  pack-bitmap-write.c
  pack-check.c
  pack-objects.c
  pack-revindex.c
  pack-write.c
  pager.c
  parse-options.c
  parse-options-cb.c
  patch-delta.c
  patch-ids.c
  path.c
  pathspec.c
  pkt-line.c
  preload-index.c
  pretty.c
  prio-queue.c
  progress.c
  prompt.c
  quote.c
  reachable.c
  read-cache.c
  reflog-walk.c
  refs.c
  refs/files-backend.c
  refs/iterator.c
  refs/ref-cache.c
  ref-filter.c
  remote.c
  replace_object.c
  repository.c
  rerere.c
  resolve-undo.c
  revision.c
  run-command.c
  send-pack.c
  sequencer.c
  server-info.c
  setup.c
  sha1-array.c
  sha1-lookup.c
  sha1_file.c
  sha1_name.c
  shallow.c
  sideband.c
  sigchain.c
  split-index.c
  strbuf.c
  streaming.c
  string-list.c
  submodule.c
  submodule-config.c
  sub-process.c
  symlinks.c
  tag.c
  tempfile.c
  thread-utils.c
  tmp-objdir.c
  trace.c
  trailer.c
  transport.c
  transport-helper.c
  tree-diff.c
  tree.c
  tree-walk.c
  unpack-trees.c
  url.c
  urlmatch.c
  usage.c
  userdiff.c
  utf8.c
  varint.c
  version.c
  versioncmp.c
  walker.c
  wildmatch.c
  worktree.c
  wrapper.c
  write_or_die.c
  ws.c
  wt-status.c
  xdiff-interface.c
  zlib.c
  block-sha1/sha1.c
  compat/strlcpy.c
  compat/qsort.c
  compat/qsort_s.c
  compat/mmap.c
  compat/poll/poll.c
  compat/regex/regex.c
  xdiff/xdiffi.c
  xdiff/xprepare.c
  xdiff/xutils.c
  xdiff/xemit.c
  xdiff/xmerge.c
  xdiff/xpatience.c
  xdiff/xhistogram.c
  )



add_library(builtins STATIC
  builtin/add.c
  builtin/am.c
  builtin/annotate.c
  builtin/apply.c
  builtin/archive.c
  builtin/bisect--helper.c
  builtin/blame.c
  builtin/branch.c
  builtin/bundle.c
  builtin/cat-file.c
  builtin/check-attr.c
  builtin/check-ignore.c
  builtin/check-mailmap.c
  builtin/check-ref-format.c
  builtin/checkout-index.c
  builtin/checkout.c
  builtin/clean.c
  builtin/clone.c
  builtin/column.c
  builtin/commit-tree.c
  builtin/commit.c
  builtin/config.c
  builtin/count-objects.c
  builtin/credential.c
  builtin/describe.c
  builtin/diff-files.c
  builtin/diff-index.c
  builtin/diff-tree.c
  builtin/diff.c
  builtin/difftool.c
  builtin/fast-export.c
  builtin/fetch-pack.c
  builtin/fetch.c
  builtin/fmt-merge-msg.c
  builtin/for-each-ref.c
  builtin/fsck.c
  builtin/gc.c
  builtin/get-tar-commit-id.c
  builtin/grep.c
  builtin/hash-object.c
  builtin/help.c
  builtin/index-pack.c
  builtin/init-db.c
  builtin/interpret-trailers.c
  builtin/log.c
  builtin/ls-files.c
  builtin/ls-remote.c
  builtin/ls-tree.c
  builtin/mailinfo.c
  builtin/mailsplit.c
  builtin/merge.c
  builtin/merge-base.c
  builtin/merge-file.c
  builtin/merge-index.c
  builtin/merge-ours.c
  builtin/merge-recursive.c
  builtin/merge-tree.c
  builtin/mktag.c
  builtin/mktree.c
  builtin/mv.c
  builtin/name-rev.c
  builtin/notes.c
  builtin/pack-objects.c
  builtin/pack-redundant.c
  builtin/pack-refs.c
  builtin/patch-id.c
  builtin/prune-packed.c
  builtin/prune.c
  builtin/pull.c
  builtin/push.c
  builtin/read-tree.c
  builtin/rebase--helper.c
  builtin/receive-pack.c
  builtin/reflog.c
  builtin/remote.c
  builtin/remote-ext.c
  builtin/remote-fd.c
  builtin/repack.c
  builtin/replace.c
  builtin/rerere.c
  builtin/reset.c
  builtin/rev-list.c
  builtin/rev-parse.c
  builtin/revert.c
  builtin/rm.c
  builtin/send-pack.c
  builtin/shortlog.c
  builtin/show-branch.c
  builtin/show-ref.c
  builtin/stripspace.c
  builtin/submodule--helper.c
  builtin/symbolic-ref.c
  builtin/tag.c
  builtin/unpack-file.c
  builtin/unpack-objects.c
  builtin/update-index.c
  builtin/update-ref.c
  builtin/update-server-info.c
  builtin/upload-archive.c
  builtin/var.c
  builtin/verify-commit.c
  builtin/verify-pack.c
  builtin/verify-tag.c
  builtin/worktree.c
  builtin/write-tree.c
)

find_library(CURL curl)
find_library(ZLIB z)
find_library(SSL ssl)
find_library(CRYPTO crypto)

include_directories(. compat/poll compat/regex)

target_link_libraries(builtins PRIVATE gitlib ${ZLIB} pthread)

add_executable(git git.c common-main.c)
target_link_libraries(git PRIVATE builtins)

add_executable(git-remote-http remote-curl.c http.c http-walker.c common-main.c)
target_link_libraries(git-remote-http PRIVATE builtins ${CURL} ${SSL} ${CRYPTO})

add_executable(git-remote-https remote-curl.c http.c http-walker.c common-main.c)
target_link_libraries(git-remote-https PRIVATE builtins ${CURL} ${SSL} ${CRYPTO})

install(TARGETS git DESTINATION bin)
install(TARGETS git-remote-http git-remote-https DESTINATION libexec/git-core)

file(TO_CMAKE_PATH "${CGET_PREFIX}" CGET_PREFIX)
file(TO_CMAKE_PATH "${CMAKE_INSTALL_PREFIX}" CMAKE_INSTALL_PREFIX)

add_definitions(
  -DCURL_STATICLIB -DSHA1_BLK -DNO_STRLCPY -DINTERNAL_QSORT
  -DNO_POLL -DNO_SYS_POLL_H -DGAWK -DNO_MBSUPPORT -DNO_MMAP -DNO_ICONV
  -DNO_GETTEXT -DNO_NSEC -DNO_ST_BLOCKS_IN_STRUCT_STAT -DNO_POSIX_GOODIES
  "-DETC_GITATTRIBUTES=\"${CGET_PREFIX}/etc/gitattributes\""
  "-DETC_GITCONFIG=\"${CGET_PREFIX}/etc/gitconfig\""
  "-DPREFIX=\"${CGET_PREFIX}\""
  "-DGIT_EXEC_PATH=\"${CMAKE_INSTALL_PREFIX}/lib/git-core\""
  "-DGIT_LOCALE_PATH=\"${CMAKE_INSTALL_PREFIX}/share/locale\""
  "-DGIT_HTML_PATH=\"${CMAKE_INSTALL_PREFIX}/share/doc/git-doc\""
  "-DGIT_MAN_PATH=\"${CMAKE_INSTALL_PREFIX}/share/man\""
  "-DGIT_INFO_PATH=\"${CMAKE_INSTALL_PREFIX}/share/info\""
  "-DPAGER_ENV=\"LESS=FRX LV=-c\""
  "-DGIT_VERSION=\"2.14.2\""
  "-DGIT_USER_AGENT=\"git/2.14.2\""
  )

file(WRITE common-cmds.h
  "/* Automatically generated by ./generate-cmdlist.sh */
struct cmdname_help {
        char name[16];
        char help[80];
        unsigned char group;
};

static const char *common_cmd_groups[] = {
        N_(\"start a working area (see also: git help tutorial)\"),
        N_(\"work on the current change (see also: git help everyday)\"),
        N_(\"examine the history and state (see also: git help revisions)\"),
        N_(\"grow, mark and tweak your common history\"),
        N_(\"collaborate (see also: git help workflows)\"),
};

static struct cmdname_help common_cmds[] = {
        {\"add\", N_(\"Add file contents to the index\"), 1},
        {\"bisect\", N_(\"Use binary search to find the commit that introduced a bug\"), 2},
        {\"branch\", N_(\"List, create, or delete branches\"), 3},
        {\"checkout\", N_(\"Switch branches or restore working tree files\"), 3},
        {\"clone\", N_(\"Clone a repository into a new directory\"), 0},
        {\"commit\", N_(\"Record changes to the repository\"), 3},
        {\"diff\", N_(\"Show changes between commits, commit and working tree, etc\"), 3},
        {\"fetch\", N_(\"Download objects and refs from another repository\"), 4},
        {\"grep\", N_(\"Print lines matching a pattern\"), 2},
        {\"init\", N_(\"Create an empty Git repository or reinitialize an existing one\"), 0},
        {\"log\", N_(\"Show commit logs\"), 2},
        {\"merge\", N_(\"Join two or more development histories together\"), 3},
        {\"mv\", N_(\"Move or rename a file, a directory, or a symlink\"), 1},
        {\"pull\", N_(\"Fetch from and integrate with another repository or a local branch\"), 4},
        {\"push\", N_(\"Update remote refs along with associated objects\"), 4},
        {\"rebase\", N_(\"Reapply commits on top of another base tip\"), 3},
        {\"reset\", N_(\"Reset current HEAD to the specified state\"), 1},
        {\"rm\", N_(\"Remove files from the working tree and from the index\"), 1},
        {\"show\", N_(\"Show various types of objects\"), 2},
        {\"status\", N_(\"Show the working tree status\"), 2},
        {\"tag\", N_(\"Create, list, delete or verify a tag object signed with GPG\"), 3},
};
")
