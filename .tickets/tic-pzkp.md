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
# Remove the inherited release and publishing automation

The inherited release system is designed for wedow/ticket and is not part of this fork's selected distribution strategy. It triggers on any v* tag, grants contents: write, creates a release, and invokes Homebrew/AUR publishing code aimed at upstream-owned targets. Missing secrets prevent the external publishing steps today, but an accidental tag can still create a fork release.

This fork is free to diverge structurally. Do not preserve dormant upstream publishing machinery merely for compatibility.

Resources:
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows
- https://docs.github.com/en/actions/reference/security/secure-use

## Design

Delete `.github/workflows/release.yml` and the Homebrew/AUR publisher scripts and templates that exist only to support it. Disable the currently registered Release workflow in GitHub before or as part of the removal. Do not replace it in this ticket, add publisher credentials, or create a tag for testing.

If hosted distribution is justified later, build a new manual fork-native workflow from first principles under a new ticket. Generally useful product commits can still be exported upstream without retaining upstream-specific release infrastructure in this branch.

## Acceptance Criteria

The inherited Release workflow is disabled in GitHub and removed from the repository. Upstream-targeted Homebrew/AUR publishing scripts and package templates are removed, with remaining references cleaned up. No tag trigger or workflow can create a release or publish a package. No publishing secret is added. Verification uses repository inspection and live workflow/settings queries without creating a tag, release, Homebrew update, or AUR update. README release/installation claims are left accurate or coordinated with `tic-pont`.

## Notes

**2026-07-22T18:40:37Z**

2026-07-22 re-audit: the inherited packaging is internally inconsistent after plugin extraction. Plugin metadata reports versions 1.0.0/1.0.1, while repository tags stop at v0.3.2. Generated plugin packages can reference missing tags or mismatched hashes, and all targets remain hardcoded to wedow. The selected resolution is removal, not adaptation.
