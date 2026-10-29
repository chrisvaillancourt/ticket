---
id: tic-r1vs
status: closed
deps: []
links: [tic-oo4g, tic-h7km]
created: 2026-10-29T20:54:09Z
type: bug
priority: 2
assignee: Chris Vaillancourt
tags: [cli, notes]
---
# tk add-note leaves a blank line at end of file when the note is empty or ends with a newline

`tk add-note` leaves a blank line at the end of the ticket file when the note text is empty or ends with a newline. The file then ends in `\n\n` (or `\n\n\n`), which fails `git diff --check` and whitespace pre-commit hooks with "new blank line at EOF".

Affected builds: fork `main` at `8f49f29` and upstream wedow/ticket v0.3.2 (`266b9d3`). Both have the same `cmd_add_note`.

Related: `tk create` had the same symptom on every create. That was fixed in `f50f1dc` (tic-oo4g), which added `_strip_trailing_newlines` and is an upstream candidate in `docs/fork-maintenance.md`. `add-note` was not covered by that fix.

### Minimal reproduction

```bash
d=$(mktemp -d) && cd "$d" && git init -q && mkdir .tickets
id=$(tk create T)
tk add-note "$id" $'note\n'      # or: tk add-note "$id" ''
tail -c 32 ".tickets/$id.md" | od -c
git add .tickets && git diff --cached --check
```

Evidence on fork `8f49f29` (2026-10-29):

```
0000020    5   3   :   3   1   Z   *   *  \n  \n   n   o   t   e  \n  \n
.tickets/tkr-f37v.md:18: new blank line at EOF.
```

v0.3.2 gives the same bytes and reports line 19, because its create also leaves a trailing blank line.

### Trigger matrix (identical in both builds; each case run in a fresh `mktemp -d` git repo)

| Input | File tail | `git diff --check` |
|---|---|---|
| arg `note` | `note\n` | clean |
| arg `l1\nl2` | `l2\n` | clean |
| two args `two words` | `words\n` | clean |
| arg `note\n` | `note\n\n` | new blank line at EOF |
| arg `note\n\n` | `note\n\n\n` | new blank line at EOF |
| arg `l1\nl2\n` | `l2\n\n` | new blank line at EOF |
| arg `''` | `**\n\n\n` | new blank line at EOF |
| stdin `note` | `note\n` | clean |
| stdin `note\n` | `note\n` | clean |
| stdin `l1\nl2\n\n` | `l2\n` | clean |
| stdin empty | `**\n\n\n` | new blank line at EOF |
| stdin `\n\n` only | `**\n\n\n` | new blank line at EOF |

Stdin with text is fine because `$(cat)` strips trailing newlines. Empty or newline-only stdin still fails because the note becomes empty.

### Suspected source

`ticket` in fork `8f49f29`, `cmd_add_note()` (line 1640):

- line 1652: `note="$*"` keeps the argument's trailing newlines.
- line 1654: `note=$(cat)` strips them, but the note can end up empty.
- line 1667: `printf '\n**%s**\n\n%s\n' "$timestamp" "$note" >> "$file"` always writes the `\n\n` separator and a final `\n`, so an empty note or one ending in `\n` leaves a blank line at EOF.

In v0.3.2 the same lines are 1273, 1285, 1287 and 1300.

### Impact

Any ticket edited this way fails `git diff --check` and whitespace hooks. Downstream repositories (for example jiramisu, which runs a check-whitespace step) have to strip trailing newlines by hand after `add-note`. Arguments ending in a newline are common when agents pass multi-line quoted text.

### Notes for the fix

`features/ticket_notes.feature` has "Add note with empty string adds timestamp-only note". Keep that behavior, but end the file with exactly one newline. `_strip_trailing_newlines` from tic-oo4g can probably be reused. Record the fix in CHANGELOG.md and add it to the upstream candidates in `docs/fork-maintenance.md`.

## Acceptance Criteria

- After `tk add-note` with any argument or stdin form, the ticket file ends with exactly one newline and passes `git diff --check`. That covers plain, multi-line, multiple-argument, empty, trailing-newline and newline-only input, with and without an existing `## Notes` section.
- An empty note still adds a timestamp-only entry, as the existing scenario expects.
- Non-empty note text is kept byte-for-byte apart from trailing newline normalization.
- Behave regression scenarios in `features/ticket_notes.feature` cover these cases using the existing "should end with exactly one newline and have no trailing whitespace" step.
- `make test` passes, and CHANGELOG.md records the fix under Fixed.

## Notes

**2026-10-29T23:11:58Z**

Fixed in 51023d1: the note goes through _strip_trailing_newlines and an empty note writes only the timestamp line. Reviews: GPT-6.1 Sol (high, via omp) and a fresh Opus agent both said ship with no blockers. Deferred: CRLF on stdin (tic-h7km, shared with create). Left as is: whitespace-only notes such as 'note ' or two empty arguments, which are user content kept byte-for-byte.
