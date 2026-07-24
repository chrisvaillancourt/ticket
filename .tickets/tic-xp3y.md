---
id: tic-xp3y
status: open
deps: []
links: []
created: 2026-07-23T23:37:58Z
type: chore
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [actions, security, settings]
---
# Require approval for all external pull-request workflows

Before enabling fork pull-request workflows, require approval for every external contributor while preserving read-only token defaults and ensuring no pull_request_target trigger is present.

## Design

Make this narrow live-settings change independently of later action allowlisting, SHA enforcement, and branch policy so Test hardening has a non-circular prerequisite.

## Acceptance Criteria

The fork approval policy is all_external_contributors; default GITHUB_TOKEN permissions remain read-only and cannot approve pull requests; no pull_request_target trigger or Actions secret is introduced; before/after settings and reproducible read-only verification commands are recorded.
