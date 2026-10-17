---
id: tic-yxhx
status: closed
deps: []
links: []
created: 2026-10-17T22:38:35Z
type: bug
priority: 1
assignee: Chris Vaillancourt
tags: [plugins]
---
# Plugins crash when no .tickets directory exists

With no .tickets directory and no TICKETS_DIR, the core leaves TICKETS_DIR unset and execs the plugin. ticket-ls (and its ticket-list alias), ticket-edit and ticket-query run under `set -u` and die with `TICKETS_DIR: unbound variable` instead of a clear error. ticket-migrate-beads defaults TICKETS_DIR to .tickets on purpose and is not affected.

## Acceptance Criteria

With no tickets directory, `tk ls`, `tk list`, `tk edit <id>` and `tk query` exit non-zero with the core's "no .tickets directory found" message and no unbound-variable error. Each plugin stays self-contained. migrate-beads still creates .tickets. A TICKETS_DIR that points at a missing directory still fails before the plugin runs. Changed plugins get a patch version bump and a CHANGELOG Plugins entry.

## Notes

**2026-10-17T22:40:27Z**

Implemented in 4110ac0: ticket-ls 1.1.2, ticket-edit 1.0.1 and ticket-query 1.1.1 exit 1 with the core message when TICKETS_DIR is unset; ticket-list is a symlink to ticket-ls. Red: the four new ticket_directory.feature outline rows failed with "TICKETS_DIR: unbound variable" before the fix. migrate-beads is unchanged (it creates .tickets; a scenario now covers that). A TICKETS_DIR that points at a missing directory already fails in the core before exec (now covered). Verification: make test 213 scenarios pass; bash -n on ticket and all plugins; git diff --check clean; manual tk ls/list/edit/query in a mktemp dir print the core error.
