---
id: tic-pont
status: open
deps: []
links: []
created: 2026-07-22T18:37:59Z
type: feature
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [install, docs, fork]
---
# Document and verify a local fork installation path

The fork should be usable immediately without waiting for hosted CI, a GitHub release, Homebrew, or AUR. The current development checkout contains the core ticket executable plus plugins. A machine may already have an upstream tk installed, so installation guidance must make command precedence and rollback explicit.

The local path must install or link both the core tk executable and the desired plugins; pointing only at ticket can leave extracted commands such as query, list, edit, or migrate-beads unavailable. Avoid modifying Git authentication, remotes, or signing configuration.

## Design

Evaluate the smallest reversible developer installation for macOS/Linux. Likely options are symlinks from a user-owned bin directory, a tiny install/uninstall script, or documented PATH entries for the core and plugin directories. Prefer a user-scoped destination such as ~/.local/bin when it is already on PATH.

Document how to confirm which executable is active, how plugins are discovered, how to switch between upstream and fork installations, how to update after git pull, and how to uninstall cleanly. Do not require sudo or overwrite an existing tk without an explicit backup/confirmation step.

## Acceptance Criteria

A clean test environment can invoke tk help and all curated plugin commands from the fork. The instructions identify the active executable with command -v/readlink or equivalent, handle an existing upstream installation safely, include uninstall/rollback steps, and do not depend on Release workflow credentials. Automated smoke coverage is added where practical.
