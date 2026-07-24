---
id: tic-495c
status: closed
deps: []
links: []
created: 2026-07-22T18:37:59Z
type: feature
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [release, distribution, design]
---
# Choose a fork-native release and distribution strategy

This fork currently serves its maintainer and a small set of trusted development machines. It is not committing to compatibility with the upstream release architecture or to being a generally packaged public CLI.

Options to compare:
- no formal releases; documented local/source installation only
- GitHub Releases with source/archive checksums and a manual, approval-gated workflow
- a fork-owned Homebrew tap for macOS
- an install/uninstall script consuming GitHub release artifacts
- version-manager integration such as mise/asdf only if demand justifies it
- fork-specific AUR packages with non-conflicting names only if Linux demand justifies maintenance
- waiting for upstream PR CI/releases for changes intended to remain upstream-compatible

Resources:
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
- https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments
- https://docs.brew.sh/Taps
- https://docs.brew.sh/Formula-Cookbook
- https://wiki.archlinux.org/title/AUR_submission_guidelines

## Design

Immediate distribution is a documented local checkout plus the reversible symlink installer in `tic-pont`. Use exact commits when identifying an installed version. There is no hosted release workflow, package-manager publication, or external publisher credential.

Reconsider a manual GitHub Release only when the fork must be installed on a machine that should not maintain a Git checkout or when another user requests a stable downloadable version. At that point create a new implementation ticket for a manually dispatched, approval-gated workflow that publishes a deterministic runtime bundle containing `tk`, the curated plugins and aliases, LICENSE, README, and SHA256SUMS. Use fork-owned, fork-qualified tags such as `v0.3.3-cv.1`; do not rely on mutable auto-generated source archives as the canonical artifact.

Homebrew is deferred until repeated one-command macOS installation demand exists. AUR is deferred until there is an identified Linux maintainer and package demand. Install scripts that execute remotely, mise/asdf integration, npm/PyPI/Cargo wrappers, Deb/RPM, and Nix are out of scope until a maintainer and concrete demand exist.

## Acceptance Criteria

The ticket records the trusted-machine target audience, selects local checkout installation now, gives concrete reconsideration triggers for a fork-owned manual GitHub Release, and explicitly defers package-manager/version-manager/remote-script channels. The inherited combined Homebrew/AUR release path is removed rather than reused. Any future hosted release must use fork-owned qualified tags, deterministic artifacts and checksums, least-privilege permissions, an approval gate, and documented rollback. No credentials, release workflow, or release tags are created by this decision.

## Notes

**2026-07-22T18:40:37Z**

2026-07-23 decision: optimize for the maintainer and trusted development machines. Use local checkout installation now and remove the inherited release/publisher system. Hosted releases and package managers are demand-triggered future work, not dormant automation retained in this fork.

Additional resources:
- https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases
- https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/verify-release-integrity
- https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives#stability-of-source-code-archives
- https://cli.github.com/manual/gh_release_create
- https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
- https://docs.brew.sh/Acceptable-Formulae#forks
- https://wiki.archlinux.org/title/PKGBUILD#Package_relations

**2026-07-23T23:40:11Z**

2026-07-23: Decision completed. Target Chris/trusted development machines; use commit-identified local checkout installation now; remove inherited publishing; reconsider a fork-owned manual GitHub Release only on documented distribution demand.
