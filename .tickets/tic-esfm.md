---
id: tic-esfm
status: in_progress
deps: []
links: []
created: 2026-07-16T19:48:41Z
type: feature
priority: 1
assignee: Chris Vaillancourt
---
# Add explicit deferred-work handling

Design and implement explicit deferred-work handling. Compare the orthogonal model with upstream issue #39 (https://github.com/wedow/ticket/issues/39) and PR #50 (https://github.com/wedow/ticket/pull/50), but do not cherry-pick PR #50: its `pending` lifecycle status conflates two independent concepts and its current ready-loop change can still emit dependency-free pending tickets.

## Design

Keep lifecycle status and deferral orthogonal:

- `deferred: true` marks explicit deferral; absence/false means not deferred.
- `defer_reason` is optional free text.
- `defer_until` is an optional ISO date (`YYYY-MM-DD`). The ticket is deferred through the preceding day and becomes eligible on that date. Lexical ISO-date comparison avoids GNU/BSD `date` differences; expiration does not rewrite the file.
- `tk defer <id> [--until <date>] [--reason <text>]` sets or replaces deferral metadata.
- `tk undefer <id>` removes all deferral metadata and is idempotent.
- `tk deferred` lists currently effective deferred tickets.

Lifecycle commands preserve deferral metadata, including close and reopen; only `undefer` clears it. Open or in-progress effectively deferred tickets are excluded from `ready` and appear in `deferred`. `blocked` remains a structural dependency view independent of deferral, so a deferred ticket with unresolved dependencies may appear in both lists. Closed tickets remain excluded from active-work views. A dependent ticket remains blocked until its dependency is closed, regardless of whether that dependency is deferred. `ls`, `show`, and `query` retain visibility of deferral fields, including elapsed dates.

Reject malformed or impossible calendar dates without modifying the ticket. Existing tickets without deferral fields remain fully compatible.

## Acceptance Criteria

Document the upstream overlap. Implement and document `defer`, `undefer`, and `deferred`; update help, README, and CHANGELOG. Tests cover field parsing and cleanup, valid/invalid dates and expiration, reasons with spaces, idempotency, partial IDs, lifecycle preservation, ready/blocked/deferred behavior, dependency behavior, plugin-overridden `ls`, and backward compatibility. Effective deferred work never appears in ready, remains structurally visible in blocked when applicable, and is discoverable through `tk deferred` without adding another lifecycle status.
