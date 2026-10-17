---
id: tic-yxhx
status: open
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
