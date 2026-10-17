---
id: tic-hcn2
status: closed
deps: []
links: [tic-yt78]
created: 2026-10-17T22:40:46Z
type: bug
priority: 2
assignee: Chris Vaillancourt
---
# Insert missing frontmatter fields portably

`update_yaml_field()` inserted a missing frontmatter field with GNU-only sed (`0,/^---$/ { ... a\ }`). BSD sed on macOS accepts that script, exits 0, and writes nothing, so `status` on a ticket without a `status:` line printed `Updated` without saving it.

Two related silent failures, on GNU and BSD alike:

- `dep` and `undep` on a ticket with no `deps:` line exited 1 with no output, because `yaml_field` fails under `set -euo pipefail` when the field is missing.
- `link` only rewrote an existing `links:` line. A ticket without one got no link, and the command printed `All links already exist` or left the pair out of the `Added link:` report.

Every writer emits `deps: []` and `links: []`, so this only affects hand-written or externally generated tickets.

## Acceptance Criteria

- Missing frontmatter fields are inserted right after the opening `---` with awk, on BSD and GNU sed.
- A ticket with no frontmatter makes the command fail with an error instead of reporting success.
- `dep` treats a missing `deps` field as `[]`; `undep` reports `Dependency not found`.
- `link` adds a missing `links` field, saves the link, and reports the pair.
- Behave scenarios cover each case and fail against the previous script on macOS.
- `make test` passes; a manual check on macOS and in a Debian container shows the fields written.

## Notes

**2026-10-17T22:41:03Z**

Fixed in 18b7d0c: awk insert_yaml_field() replaces the GNU-only sed insert and errors when a ticket has no frontmatter; dep/undep treat a missing deps field as empty; link adds a missing links field before merging. Verification: 7 new Behave scenarios fail against the previous script on macOS (BSD sed) and pass after; make test 213 scenarios pass; bash -n and git diff --check clean; manual status/dep/link check writes the fields on macOS and in debian:stable-slim (GNU sed 4.9, mawk).

**2026-10-17T23:00:56Z**

Review follow-up: insertion after a body --- rule, the dep body-line overwrite, link writing before validation, and the generic no-frontmatter message are fixed under tic-yt78 (8a9f951).
