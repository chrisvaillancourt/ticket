---
id: tic-jppr
status: open
deps: []
links: []
created: 2026-07-22T18:37:59Z
type: epic
priority: 1
assignee: Chris Vaillancourt
external-ref: https://github.com/chrisvaillancourt/ticket
tags: [actions, security, release, fork]
---
# Harden fork automation and establish a release strategy

Context

This repository is the public chrisvaillancourt/ticket fork of wedow/ticket. Fork work began from upstream commit 194b71a. Fork master is currently 70660e3, and the completed writer fix is code commit f50f1dc. The fork is intended to remain usable as a small Git-native ticket CLI while carrying carefully reviewed improvements.

GitHub Actions state on 2026-07-22: repository Actions reports enabled; Test and Release report active; no workflow runs exist; default GITHUB_TOKEN permissions are read-only; all public actions are allowed; full-SHA pinning is not required; external PR approval is required only for first-time contributors; and the fork has no Actions secrets, variables, or environments.

The imported Test workflow runs on master pushes and pull requests. The imported Release workflow runs on v* tags, grants contents: write, creates a GitHub release, and invokes Homebrew/AUR publishing scripts that target upstream wedow resources. The release flow must not receive upstream publishing credentials.

## Design

Split the work into two horizons.

Immediate usability: provide a documented local installation path, contain the imported Release workflow, harden Test, and clear the fork-specific Actions gate only after the workflow is safe.

Long-term distribution: choose fork-owned release and installation channels, implement least-privilege release automation, and explicitly decide which upstream packaging channels should be replaced, renamed, or omitted.

Security principles: no upstream publishing secrets in the fork; explicit least-privilege permissions; immutable action references; reproducible tool versions; review before external PR code runs; GitHub-hosted runners only; and no pull_request_target execution of untrusted code.

Primary resources:
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflows-in-forked-repositories
- https://docs.github.com/en/actions/reference/security/secure-use
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows

## Acceptance Criteria

All child tickets have explicit decisions and verification evidence. A fresh clone can run the fork safely. The imported upstream release path cannot publish or mutate upstream distribution targets. Test has a successful GitHub-hosted run with its URL recorded. The selected long-term release strategy is documented before release automation or credentials are added. No release tag is created merely to test workflow configuration.
