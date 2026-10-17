---
id: tic-mduj
status: closed
deps: []
links: []
created: 2026-10-17T23:27:05Z
type: bug
priority: 2
assignee: Chris Vaillancourt
---
# Fix final-review silent failures in unlink, read-then-write commands, closed, and create

The final reviews of the frontmatter and ID fixes found more silent failures:

- `unlink` wrote the first ticket before finding the second unreadable, so a retry said `Link not found`.
- `yaml_field` reports a missing field and unreadable frontmatter the same way, so `undep` on a CRLF ticket said `Dependency not found`, and `unlink` with a CRLF target said `Removed link` and exited 0 with the target unchanged.
- `closed --limit` lost validation when `head` became awk: `garbage` and `5x` printed every ticket and `-1` printed none, all with exit 0.
- With no tickets, `closed` exited 1 and `ready`, `blocked`, `deferred`, `dep cycle`, and the `ls` plugin exited 2, all with no output, because the `*.md` glob stayed literal.
- `create --description-file -` with empty stdin created a ticket with an empty field.
- `closed` split paths with spaces, because it passed them through `xargs`.

## Acceptance Criteria

- `dep`, `undep`, and `unlink` check frontmatter on every ticket they touch before reading fields; `unlink` writes nothing unless both tickets are valid.
- `closed --limit` accepts only a whole number and otherwise fails with an error.
- Listing commands succeed with no output in an empty tickets directory; `dep cycle` reports no cycles.
- `create` fails without writing when a `--*-file -` field reads empty stdin.
- `closed` handles a tickets path with spaces.
- Behave scenarios fail against main and pass after; `make test` passes on macOS and Linux.

## Notes

**2026-10-17T23:27:11Z**

Fixed in ee22df1 (check frontmatter before dep/undep/unlink read fields; unlink checks both first), c49970e (closed --limit must be a whole number, 0 allowed; empty-directory guard for closed, ready, blocked, deferred, dep cycle, dep tree, and ticket-ls 1.1.4), b0fb3fd (empty stdin for --*-file - fails), and e118450 (closed passes paths to awk without xargs; found during manual repro in a path with a space). Verification: 16 new scenarios failed against main a10f3bd and pass now; status/dep/defer/undefer CRLF guard scenarios already passed; make test 272 scenarios pass on macOS and in python:3.13-slim (GNU sed 4.9, jq 1.7); bash -n and git diff --check clean; manual repro of each finding before and after under /bin/bash 3.2 (BSD sed) and in debian:stable-slim (GNU sed).

**2026-10-17T23:37:47Z**

Re-review follow-up: a5c4831 makes _have_tickets loop over the quoted tickets directory with a *.md suffix instead of compgen -G, so a project[1] directory is matched literally. d93a6e5 keeps an ls -t failure in closed visible ("could not list tickets", exit 1; it was exit 0 on bash 5 and an unbound files[@] on bash 3.2), widens the scan window to max(100, limit), accepts --limit N, and reports -a, -T, or --limit without a value in closed, ready, blocked, and ticket-ls 1.1.5 instead of an unbound variable. Verification: 13 new scenarios failed against 856b666 and pass now; make test 285 scenarios pass on macOS and in python:3.13-slim; bash -n and git diff --check clean; manual repro before and after under /bin/bash 3.2 (including a real "Argument list too long" with 6000 tickets with 200-character IDs) and in debian:stable-slim.
