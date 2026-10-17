---
id: tic-d1qb
status: closed
deps: []
links: []
created: 2026-10-17T23:14:42Z
type: bug
priority: 1
assignee: Chris Vaillancourt
tags: [listing, closed]
---
# Keep closed from exiting on SIGPIPE with large ticket lists

cmd_closed piped 'ls -t' into 'head -n 100' in the main shell under set -euo pipefail. When the file list overflows the pipe buffer (many tickets or long paths), ls gets SIGPIPE, the pipeline returns 141 and tk closed exits with no output. Found by the field-branch reviewer on a copy of jiramisu's 249 tickets under a long scratch path; reproduced with 300 tickets under a long directory.

## Acceptance Criteria

tk closed succeeds and prints up to --limit lines when the file list is larger than a pipe buffer; a Behave scenario with 400 long-ID closed tickets fails before and passes after.

## Notes

**2026-10-17T23:14:42Z**

Fixed in 2a9c38d: both head limits in cmd_closed replaced with awk 'NR <= n', which drains its input. Red: scenario exited 141. Green: make test 252 passed; long-path repro exits 0 under /bin/bash 3.2.
