---
id: tic-dez8
status: open
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
