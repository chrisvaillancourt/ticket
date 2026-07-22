---
id: tic-495c
status: open
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

The upstream project automates GitHub Releases, a Homebrew tap, and AUR packages in one privileged workflow. That shape is not automatically correct for this fork. The fork first needs a clear audience and support promise: personal development checkout, a small set of trusted machines, or a generally installable public CLI. Distribution choices should follow that need rather than copying upstream credentials and package names.

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

Prefer staged adoption. Immediate use should rely on the local-install ticket. The likely first public channel is a manually initiated GitHub Release owned by this fork, with contents: write limited to the release job and an environment approval gate. A personal Homebrew tap is likely the next useful convenience for macOS. AUR should be optional and renamed rather than attempting to update upstream-owned package names.

Compare credential models, rollback, provenance/checksums, action pinning, tag/version ownership, plugin packaging, cross-platform support, maintenance cost, and how fork-only release commits stay separate from upstream-exportable code changes. Consider whether a release workflow is necessary at all while the fork is primarily for personal use.

## Acceptance Criteria

A decision record names the target users and selects an immediate, medium-term, and explicitly deferred distribution path. It explains why the upstream combined Homebrew/AUR workflow is reused, replaced, or omitted. It defines tag/version ownership, artifact contents, checksum/provenance expectations, required permissions/credentials, approval gates, rollback, and package naming. It includes a recommendation for GitHub Releases, Homebrew, AUR, source installation, and at least one version-manager or install-script alternative. No credentials or release tags are created during design.

## Notes

**2026-07-22T18:40:37Z**

2026-07-22 research recommendation: first decide whether this fork is only an upstream patch queue or a maintained distribution. If it is only a patch queue, publish no independent releases and use exact commit SHAs. If it needs distribution now, disable the inherited Release workflow and create one manual GitHub prerelease from a reviewed fork commit, using a fork-qualified version such as v0.3.3-cv.1. Prefer a deterministic runtime bundle containing tk, curated plugins/aliases, LICENSE, and README plus SHA256SUMS; publish as a draft and make the release immutable before publication. Do not configure external publishing secrets.

Use GitHub Releases as the likely canonical long-term channel. Add a manually maintained chrisvaillancourt/homebrew-tap with one distinctly named formula only after one-command-install demand exists. Point it at the immutable fork release asset and checksum. Defer install scripts because of PATH/rollback and remote-code-execution concerns; never promote curl-pipe-shell. Defer AUR because upstream already maintains ticket 0.3.2-1 and a fork requires a distinct package identity, conflicts/provides semantics, an SSH key, and ongoing demand. Do not wrap the Bash CLI in npm, PyPI, Cargo, Deb/RPM, or Nix without an ecosystem maintainer or demonstrated user need.

Additional resources:
- https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases
- https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/verify-release-integrity
- https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives#stability-of-source-code-archives
- https://cli.github.com/manual/gh_release_create
- https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
- https://docs.brew.sh/Acceptable-Formulae#forks
- https://wiki.archlinux.org/title/PKGBUILD#Package_relations
