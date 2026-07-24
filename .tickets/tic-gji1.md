---
deferred: true
defer_reason: Deferred because current installs are supervised single-writer operations on stable storage; reconsider for unattended or concurrent installs, or when strict all-or-nothing I/O guarantees are required.
id: tic-gji1
status: open
deps: []
links: []
created: 2026-07-24T17:41:12Z
type: chore
priority: 3
assignee: Chris Vaillancourt
parent: tic-pont
tags: [install, deferred, hardening, transaction, concurrency]
---
# Make local installer link creation transactional

The installer preflights destination collisions before creating links, but link creation is sequential. A mid-link filesystem failure or concurrent writer can therefore leave a partial set of newly installed links even though unrelated entries remain protected. Add rollback-safe behavior if the installation environment eventually requires a strict all-or-nothing I/O guarantee.

## Design

Track only links newly created by the current invocation and roll them back on any later creation failure, verifying exact target ownership before removal. Evaluate a portable prefix-level coordination mechanism for concurrent writers without introducing sudo or broad destructive cleanup. Provide deterministic failure injection so rollback paths are tested rather than dependent on real storage faults.

## Acceptance Criteria

Automated temporary-prefix tests inject failure after at least one new link is created and prove the command fails with no partial new checkout links remaining. Pre-existing exact checkout links, unrelated files and directories, broken or foreign links, and retargeted entries are preserved. Concurrent-prefix behavior is explicitly defined and tested if coordination is implemented. Normal install, idempotent reinstall, and ownership-safe uninstall continue to pass on macOS and Linux.
