---
id: tic-yt78
status: closed
deps: []
links: [tic-hcn2]
created: 2026-10-17T23:00:46Z
type: bug
priority: 2
assignee: Chris Vaillancourt
---
# Scope frontmatter edits to the opening block and match IDs exactly

Frontmatter reads and writes leaked into the ticket body, and ID checks matched substrings and regexes.

- `update_yaml_field` checked and replaced `^field:` anywhere in the file, so `close` rewrote a body line such as `status: degraded`. `yaml_field` read every `---` pair, so a body `---` block fed fields to `undep` and `unlink`.
- The bulk awk readers (`ready`, `blocked`, `closed`, `deferred`, `show`, `dep tree`, `dep cycle`) and the `ls` and `query` plugins toggled frontmatter on every `---`, so a body `---` pair overrode real fields.
- Missing-field inserts went after the first `---` anywhere, so a ticket with no frontmatter but a body rule got the field in its body and the command succeeded. `link` inserted `links: []` into one ticket before failing on another.
- `dep`, `undep`, and `unlink` used `grep "$id"` and unescaped sed regexes: `t-1` matched `t-10` (`dep` said it already existed; `undep` and `unlink` turned `[t-10]` into `[0]`), and `a.1` matched `ab1`. `dep tree t-1` was ambiguous with `t-10`.
- Values went into sed `s///` unescaped, so an ID with `&` or `\` corrupted `deps`.
- CRLF tickets and unclosed frontmatter were edited or reported as success instead of failing with an accurate error.

## Acceptance Criteria

- Frontmatter means a `---` on line 1 through the next `---`; every reader and writer in `ticket` and the `ls` and `query` plugins stays inside it.
- Writers share one awk helper that passes values through `ENVIRON` and fails without writing on missing, unclosed, or CRLF frontmatter, with a message naming the case.
- `link` validates every ticket before writing any.
- `dep`, `undep`, `unlink`, and `link` compare whole IDs; `dep tree` prefers an exact ID.
- Behave scenarios for each case fail against the previous HEAD and pass after; `make test` passes on macOS and Linux.

## Notes

**2026-10-17T23:00:56Z**

Fixed in 8a9f951 (frontmatter scoping: shared _edit_frontmatter awk helper, line-1 frontmatter in all bulk readers and the ls/query plugins, link validates first, accurate no-frontmatter/unclosed/CRLF errors, literal values) and d80a79c (exact-match ID lists for dep/undep/unlink, exact root for dep tree). Verification: 29 new scenarios failed against 98d26f4 on macOS and pass now; make test 251 scenarios pass on macOS (BSD sed) and in python:3.13-slim (GNU sed 4.9, jq 1.7); ticket under /bin/bash 3.2 passes all but the help-guard scenario, which parses the wrapper file rather than the script; bash -n and git diff --check clean; manual repro of each bug before (main c059a80) and after on macOS and debian:stable-slim.
