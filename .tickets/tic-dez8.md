---
id: tic-dez8
status: closed
deps: []
links: []
created: 2026-10-17T22:38:35Z
type: chore
priority: 2
assignee: Chris Vaillancourt
tags: [tests, help]
---
# Guard that every built-in command has a help entry

Per-command help comes from _command_help, which filters the shared _help_commands text. If a built-in in the dispatch case has no help line, `tk <cmd> --help` finds no entry, falls through and runs the command. The help feature lists each command by hand, so a new built-in without a help line goes unnoticed.

## Acceptance Criteria

A Behave scenario derives the built-in command list from the script's dispatch case, not a hand-kept list, and asserts that `ticket <cmd> --help` exits 0 and prints that command's entry for each one. Deleting any command's help line makes the scenario fail and name that command.

## Notes

**2026-10-17T22:40:27Z**

Implemented in 08599a9: the "Every dispatched built-in command has a help entry" scenario in features/ticket_help.feature reads the last `case "${1:-help}" in` block of ticket (17 commands; help aliases skipped). super is excluded: it is a prefix consumed before dispatch, and `tk super --help` prints the full help. Red check: deleting the `show <id>` help line failed the scenario with "show: exit 1 ... no .tickets directory found"; the line was restored, not committed. Verification: make test 213 scenarios pass.

**2026-10-17T22:45:47Z**

Review follow-up in cc0a119: the dispatch parser now accepts quoted ("show")) and space-separated (a | b)) arms and fails on any other line at arm indentation. Checked on scratch copies with the show help line deleted: the quoted and spaced arms fail naming show, and a show*) arm fails with "Cannot parse dispatch arm". Verification: make test 213 scenarios pass; git diff --check clean.
