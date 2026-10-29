---
id: tic-h7km
status: open
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
