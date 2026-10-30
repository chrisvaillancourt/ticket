---
id: tic-h7km
status: closed
deps: []
links: [tic-r1vs]
created: 2026-10-29T23:11:58Z
type: bug
priority: 3
assignee: Chris Vaillancourt
tags: [cli, notes]
---
# create and add-note keep a trailing CR from CRLF stdin, leaving a blank line at EOF

`create --description-file -` (and the design and acceptance forms) and `add-note` read stdin with `$(cat)`, which strips the final LF before `_strip_trailing_newlines` runs. For CRLF input the helper then gets a value ending in `\r` and leaves it, so the file keeps a trailing `\r` or a blank line at EOF.

Repro: `printf '\r\n\r\n' | tk add-note ID` fails `git diff --check` with "new blank line at EOF". The same text passed as an argument (`$'\r\n'`) is fine.

Found by the Opus review of tic-r1vs (fixed in `51023d1`). Possible fix: read stdin with `content=$(cat; printf x); content=${content%x}` at `ticket:427` and in `cmd_add_note`, so the helper sees the raw trailing bytes. Add Behave scenarios for both commands.

## Notes

**2026-10-29T23:26:01Z**

Fixed in 64880fd: new _read_stripped helper reads stdin and field files with a sentinel so _strip_trailing_newlines sees CRLF. Also covers create field files read from a path (same cause). Reviews: GPT-6.1 Sol (high, via omp) and a fresh Opus agent both said ship with no blockers. Added after review: a test that interior CRLF is kept, a comment fix, and the add-note CRLF-only case in the CHANGELOG. Deferred to known limits in docs/fork-maintenance.md: interior CRs, a CR before CRLF or a lone trailing CR, and quadratic stripping for thousands of trailing line breaks. Skipped: the bash 5 NUL-byte warning is now hidden for field-file paths (NUL was already dropped).
