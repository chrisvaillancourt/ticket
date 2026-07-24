---
id: tic-jppr
status: open
deps: [tic-pzkp, tic-pont, tic-495c, tic-xp3y, tic-mgwu, tic-1b09]
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

This repository is the public chrisvaillancourt/ticket fork of wedow/ticket. Fork work began from upstream commit 194b71a. The fork is free to diverge substantially and is optimized first for its maintainer and trusted development machines while remaining a small Git-native ticket CLI.

GitHub Actions state on 2026-07-22: repository Actions reports enabled; Test and Release report active; no workflow runs exist; default GITHUB_TOKEN permissions are read-only; all public actions are allowed; full-SHA pinning is not required; external PR approval is required only for first-time contributors; and the fork has no Actions secrets, variables, or environments.

The imported Test workflow runs on master pushes and pull requests. The imported Release workflow runs on v* tags, grants contents: write, creates a GitHub release, and invokes Homebrew/AUR publishing scripts that target upstream wedow resources. The release flow must not receive upstream publishing credentials.

## Design

Split the work into two horizons.

Immediate usability: provide a documented local installation path, remove the imported release/publishing system, require approval for all external pull-request workflows, harden Test, and clear the fork-specific Actions gate only after the workflow is safe.

Distribution decision: use local checkout installation now. Hosted releases and package-manager channels are demand-triggered future work, not required epic outcomes.

Security principles: no upstream publishing secrets in the fork; explicit least-privilege permissions; immutable action references; reproducible tool versions; review before external PR code runs; GitHub-hosted runners only; and no pull_request_target execution of untrusted code.

Primary resources:
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflows-in-forked-repositories
- https://docs.github.com/en/actions/reference/security/secure-use
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows

## Acceptance Criteria

All required child tickets are closed with decisions and verification evidence in ticket notes, repository documentation, or hosted-run URLs as appropriate. A fresh clone can install core plus curated plugins into a temporary user prefix, run the smoke suite, and uninstall safely. The inherited release/publishing system is absent. External pull-request workflows require approval, Test has a successful GitHub-hosted run with its URL/SHA recorded, and repository action restrictions are reproducibly documented. The local-only distribution decision and future reconsideration triggers are recorded. No release tag or publishing credential is created.
