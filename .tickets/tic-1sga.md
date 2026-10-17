---
id: tic-1sga
status: open
deps: []
links: []
created: 2026-10-17T22:20:03Z
type: feature
priority: 2
assignee: Chris Vaillancourt
tags: [cli, help]
---
# Accept --help and -h on every built-in subcommand

tk create --help fails with 'Unknown option: --help' (and creates .tickets as a side effect). Agents and people expect per-command help.

## Design

Derive per-command help from the main help text so the two cannot drift. Intercept -h/--help before tickets-directory initialization so help never needs or creates .tickets. Plugins keep handling their own arguments.

## Acceptance Criteria

tk <cmd> --help and -h print that command's usage and options and exit 0 for every built-in. dep help includes dep tree and dep cycle. No .tickets directory is required or created. Unknown commands still fail.
