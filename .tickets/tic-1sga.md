---
id: tic-1sga
status: closed
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

## Notes

**2026-10-17T22:27:51Z**

Implemented in 0884cff; 88c69a3 limits detection to '<cmd> --help|-h' so option values and note text stay data, with create's parser handling a later --help. Verification: make test 206 scenarios pass; bash 3.2 smoke test; review findings fixed in 88c69a3.
