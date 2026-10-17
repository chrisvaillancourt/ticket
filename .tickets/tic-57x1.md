---
id: tic-57x1
status: closed
deps: []
links: []
created: 2026-10-17T22:20:03Z
type: feature
priority: 1
assignee: Chris Vaillancourt
tags: [cli, create]
---
# Read create rich-text fields from files or stdin

-d, --design and --acceptance only take inline strings, so multi-line Markdown with backticks, dollar signs and quotes needs fragile shell quoting. add-note already reads stdin; create does not.

## Design

Add --description-file, --design-file and --acceptance-file. A path of - reads stdin. Reject giving both the inline and file form of one field, and more than one field reading stdin. Validate before writing anything.

## Acceptance Criteria

Each file flag sets its section byte-for-byte apart from trailing newline normalization, including backticks, dollar signs and quotes. - reads stdin. Missing files, inline/file conflicts and two stdin fields fail without creating a ticket or the tickets directory. Help and README document the flags.

## Notes

**2026-10-17T22:27:51Z**

Implemented in f8bdb67; 88c69a3 accepts any readable non-directory path (/dev/stdin, process substitution), requires a path, and refuses '-' on a terminal. Verification: make test 206 scenarios pass; bash 3.2 smoke test; review findings fixed in 88c69a3.
