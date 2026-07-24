---
id: tic-9nfk
status: closed
deps: [tic-495c, tic-pzkp]
links: []
created: 2026-07-22T18:37:59Z
type: feature
priority: 2
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [release, distribution, actions]
---
# Add a hosted release only when distribution demand exists

The selected immediate distribution path is a local checkout installer, so no hosted release is currently required. Reopen or replace this ticket only when the fork must be installed without a maintained Git checkout or another user requests a stable downloadable version.

## Design

When the trigger occurs, create a new manual fork-native GitHub Release workflow from first principles. Publish a deterministic runtime bundle containing core, curated plugins and aliases, LICENSE, README, and SHA256SUMS under a fork-qualified tag. Use least-privilege jobs, immutable action SHAs, a protected environment approval gate, and separate build/test from publish. Do not revive or adapt the removed Homebrew/AUR publishers.

## Acceptance Criteria

This ticket is closed as intentionally not selected for the current trusted-machine audience. Its reconsideration triggers and minimum future design are recorded. If reopened, acceptance must be expanded for the concrete release channel before implementation.

## Notes

**2026-07-23T23:40:12Z**

2026-07-23: Closed as intentionally not selected by tic-495c. Reopen or create a fresh implementation ticket only when a non-checkout installation or stable downloadable artifact is concretely needed.
