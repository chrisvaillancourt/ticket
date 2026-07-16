---
id: tic-oo4g
status: open
deps: []
links: []
created: 2026-07-16T19:48:41Z
type: bug
priority: 1
assignee: Chris Vaillancourt
---
# Guarantee one final newline in generated ticket files

Generated ticket files currently end with an extra blank line. Fix both the core create writer and the ticket-migrate-beads writer so every generated Markdown file ends with exactly one newline and contains no trailing whitespace.

## Design

Refactor create to place separators before optional Markdown sections and emit final content with printf. Refactor migrate-beads to join body sections with blank lines, preserve one jq-provided terminal newline, and omit created when created_at is absent or empty.

## Acceptance Criteria

Cover all eight combinations of description, design, and acceptance for create. Cover minimal, fully populated, and missing-created_at Beads records. Verify one terminal newline, no double terminal newline, no trailing whitespace, full Behave suite, Bash syntax, and isolated reproduction.
