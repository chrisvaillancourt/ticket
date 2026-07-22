---
id: tic-pzkp
status: open
deps: []
links: []
created: 2026-07-22T18:37:59Z
type: chore
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [actions, security, release]
---
# Contain the upstream Release workflow in the fork

The inherited .github/workflows/release.yml is designed for wedow/ticket, not this fork. It triggers on any v* tag, grants contents: write, creates a release, then runs scripts that target wedow/homebrew-tools and upstream AUR package names using TAP_GITHUB_TOKEN and AUR_SSH_KEY. The fork currently has no secrets, so upstream publishing cannot succeed today, but an accidental tag can still create a fork release and future credentials could make the workflow dangerous. Existing copied tags do not retro-trigger workflows.

Relevant files: .github/workflows/release.yml, scripts/publish-homebrew.sh, scripts/publish-aur.sh.

Resources:
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows
- https://docs.github.com/en/actions/reference/security/secure-use

## Design

Short-term containment should be simple and reversible: disable Release in the fork and add a durable repository guard that prevents the upstream publishing job from running outside wedow/ticket. Do not add publisher credentials and do not create a v* tag for testing.

The long-term fork-native release workflow should replace this workflow only after the release strategy ticket is decided. Keep upstream exportability in mind: a fork-only guard or separate workflow should be easy to exclude from an upstream contribution branch.

## Acceptance Criteria

Release is disabled in the fork or provably guarded so a fork tag cannot run upstream publishing logic. No upstream publishing secret exists in the fork. A dry inspection documents what a v* tag would do. The containment is verified without creating a release tag, GitHub release, Homebrew update, or AUR update. The decision is recorded in public repository documentation or ticket notes.

## Notes

**2026-07-22T18:40:37Z**

2026-07-22 re-audit: the inherited packaging is also internally inconsistent after plugin extraction. Plugin metadata reports versions 1.0.0/1.0.1, while repository tags stop at v0.3.2. The scripts generate plugin source URLs for those plugin versions but reuse the repository release tarball SHA for every package, so generated formulas/PKGBUILDs can reference missing tags or mismatched hashes. All source URLs, maintainer metadata, tap targets, and AUR package names remain hardcoded to wedow. Do not adapt or invoke this combined flow as the short-term fork release path.
