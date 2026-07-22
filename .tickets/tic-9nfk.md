---
id: tic-9nfk
status: open
deps: [tic-495c, tic-pzkp]
links: []
created: 2026-07-22T18:37:59Z
type: feature
priority: 2
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [release, distribution, actions]
---
# Implement the selected fork-native release path

Implement the release and installation channels chosen by the release-strategy ticket. This ticket intentionally does not predetermine GitHub Releases, Homebrew, AUR, or another channel. The implementation must target chrisvaillancourt-owned repositories and package names, not wedow publishing infrastructure, and must preserve a clean path for exporting generally useful code commits back to upstream.

## Design

Use least-privilege jobs and credentials, immutable action SHAs, explicit manual or tag triggers, and an environment approval gate for publishing. Separate build/test from publish so untrusted code never shares a privileged publishing job. Generate verifiable checksums and document rollback. Keep release-specific fork customization isolated from upstream-exportable product changes. Never reuse upstream publisher credentials.

## Acceptance Criteria

The selected channel installs a released core executable and intended plugins from fork-owned artifacts. A release dry run or non-publishing validation passes before the first real tag. The workflow has explicit minimal permissions, reviewed immutable action references, protected secrets or tokenless authentication where available, and an approval gate. Documentation covers install, upgrade, rollback, uninstall, and artifact verification. No workflow can publish to wedow-owned or upstream AUR targets.
