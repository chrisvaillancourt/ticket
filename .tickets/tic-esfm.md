---
id: tic-esfm
status: closed
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

## Notes

**2026-07-24T18:03:10Z**

Implementation complete.

Commits:
- 5c0b92b: orthogonal deferred-work handling.
- ebc359e: safe YAML and JSON encoding for free-text metadata.

TDD and verification evidence:
- Initial red: 4 scenarios passed, 17 failed, with no undefined steps.
- Initial green focused: 1 feature, 22 scenarios, 212 steps passed.
- Initial related: 7 features, 83 scenarios, 596 steps passed.
- Initial full: 14 features, 165 scenarios, 1,169 steps passed.
- Independent review found two serialization blockers: raw defer_reason punctuation could produce invalid YAML, and ticket-query did not JSON-escape keys or values.
- Correction red: 2 features failed; 24 scenarios and 247 steps passed, 6 scenarios and 6 steps failed, 22 steps skipped.
- Final focused: 2 features, 30 scenarios, 275 steps passed.
- Final related: 5 features, 74 scenarios, 562 steps passed.
- Final full: 14 features, 169 scenarios, 1,200 steps passed.
- Bulk query verified exact results across 300 tickets for both unfiltered and filtered paths.
- bash -n and git diff --check passed. ShellCheck reported no new plugin warnings and only the six pre-existing warnings in ticket.

Final independent re-review verified semantic YAML and JSON punctuation cases, legacy compatibility, CR/LF rejection without file mutation, and the bulk one-AWK/one-jq query path. Result: no meaningful issues and no deferred risk.
