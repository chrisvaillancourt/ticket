---
id: tic-ilee
status: open
deps: []
links: []
created: 2026-10-17T22:20:03Z
type: feature
priority: 3
assignee: Chris Vaillancourt
tags: [cli, create]
---
# Add tk create --dry-run

tk create writes immediately, so there is no way to check parsed types, tags and section boundaries before a ticket lands.

## Design

Render the ticket through one function used for both the real write and --dry-run. Dry-run prints the rendered file to stdout and writes nothing; its ID is not reserved.

## Acceptance Criteria

--dry-run prints the full ticket (frontmatter and body) with the same bytes a real create would write, creates no file and no tickets directory, and still validates options such as --parent.
