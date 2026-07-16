---
id: tic-esfm
status: open
deps: []
links: []
created: 2026-07-16T19:48:41Z
type: feature
priority: 1
assignee: Chris Vaillancourt
---
# Add explicit deferred-work handling

Design and implement explicit deferred-work handling as a follow-up workstream. Compare the intended orthogonal model with upstream issue #39 (https://github.com/wedow/ticket/issues/39) and PR #50 (https://github.com/wedow/ticket/pull/50). Do not cherry-pick PR #50 during the newline kickoff.

## Design

Keep lifecycle status and deferral orthogonal. Candidate metadata includes deferred, defer_reason, and defer_until, but command and field names remain non-final until the design phase.

## Acceptance Criteria

Document the upstream overlap and choose a model before implementation. Add CLI behavior and tests on a separate branch. Ensure deferred work is excluded from ready output without conflating deferral with lifecycle status.
