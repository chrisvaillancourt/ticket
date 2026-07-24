---
deferred: true
defer_reason: Deferred because the curated manifest is stable; reconsider on any pkg/extras.txt or maintained-alias name-set change.
id: tic-08b3
status: open
deps: []
links: []
created: 2026-07-24T17:41:02Z
type: chore
priority: 3
assignee: Chris Vaillancourt
parent: tic-pont
tags: [install, deferred, hardening, manifest, ownership]
---
# Preserve installer ownership across manifest changes

The local installer derives its desired and owned link set from the current pkg/extras.txt and maintained plugin aliases. If curated plugins or aliases are added, removed, renamed, or become non-executable after an installation, a later reinstall or uninstall may not recognize formerly owned links or may stop before safe cleanup. Preserve deliberate update behavior and provable ownership across those manifest transitions.

## Design

Define an explicit manifest-evolution contract for install, update/reinstall, and uninstall. Evaluate a checkout-scoped ownership receipt or migration-aware reconciliation that records previously created destinations without claiming unrelated or retargeted entries. Cover curated plugin and maintained-alias additions, removals, renames, and non-executable entries while keeping cleanup limited to links provably created for this checkout.

## Acceptance Criteria

Automated temporary-prefix coverage installs a first manifest, changes pkg/extras.txt and maintained aliases, then exercises deliberate reinstall/update and uninstall behavior. Cases cover plugin and alias additions, removals, renames, and non-executable entries. Formerly owned links are cleaned up only when ownership is provable; unrelated files, directories, broken links, and retargeted links remain untouched. The documented update workflow explains when reconciliation is required and how failures are recovered safely.
