---
id: tic-jppr
status: closed
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

## Notes

**2026-07-24T22:23:16Z**

2026-07-24 final acceptance audit: PASS.

Required child evidence: tic-pzkp is closed (release/publisher removal abb734f7; closure 459d1ce0); tic-pont is closed (installer ea396310, CDPATH fix 14b4337d, closure aa3c2797); tic-495c and intentionally-not-selected hosted-release child tic-9nfk are closed by 33e7a896; tic-xp3y is closed with the external-approval evidence in 008b53b6; tic-mgwu is closed with hardened/locked Test eea14875, closure ab738ff8, and hosted-run clarification 0867cafa; tic-1b09 is closed with policy documentation 85e52651, reusable-workflow clarification b200bd41, and closure 6fb7f513. All six required dependencies are closed, the dependency graph has no cycles, and the epic is ready.

Fresh-clone acceptance: a new GitHub clone of chrisvaillancourt/ticket resolved exactly to 6fb7f5135720ca9138b49df29b220ba5a21c60cd and installed into a separate temporary user prefix. Installation created exactly six checkout-owned links: tk, ticket-edit, ticket-ls, ticket-list, ticket-query, and ticket-migrate-beads. Reinstall was idempotent with six Already installed results; command resolution selected only the temporary-prefix tk; help, ls, list, query, and noninteractive edit smoke passed; migrate-beads produced the expected safe missing-input failure. Committed collision coverage verifies refusal for regular files, directories, broken links, and foreign links without partial installation. Ownership-safe uninstall removed owned links while preserving an unrelated sentinel unchanged and a retargeted foreign link. All audit-owned temporary paths were removed.

Test and workflow acceptance: the locked exact-master suite passed 14 features, 169 scenarios, and 1200 steps with zero failures/skips. Current-master hosted Test run https://github.com/chrisvaillancourt/ticket/actions/runs/30129994378 passed at 6fb7f5135720ca9138b49df29b220ba5a21c60cd on GitHub-hosted ubuntu-24.04. Policy-focused hosted run https://github.com/chrisvaillancourt/ticket/actions/runs/30129140387 passed at 0867cafafe18b263106166104ff37b2962290a1d on the GitHub Actions runner group.

Live Actions acceptance: Actions is enabled with allowed_actions=selected and sha_pinning_required=true. Selected actions are github_owned_allowed=false, verified_allowed=false, and exactly actions/checkout@* plus astral-sh/setup-uv@*. Default workflow token permissions are read and cannot approve pull-request reviews; fork approval is all_external_contributors. Secrets, variables, environments, and self-hosted runners are each zero. Exactly one active workflow remains, Test; remote Test matches the committed full-SHA-pinned workflow. There is no pull_request_target, self-hosted label, secrets reference, or publishing credential. Repository action restrictions and their reproducible read-only audit are recorded in docs/github-actions-policy.md.

Release/distribution acceptance: the inherited Release workflow and Homebrew/AUR publisher assets are absent locally and remotely; the remote Release path returns 404; all workflow runs are Test; GitHub Releases are zero. Six existing v0.1.0-v0.3.2 tags are all pre-fork ancestors of upstream start 194b71a, so no fork-era release tag was created. tic-495c records local checkout installation for the trusted-machine audience and concrete triggers for a future manual fork-owned release, Homebrew, or AUR work; tic-9nfk records the minimum future release design. No credential, release workflow, release, or tag was created for this epic.

Branch/residual acceptance: docs/github-actions-policy.md records the deliberate solo-maintainer choice of no branch protection/ruleset and reconsideration triggers (another writer, hosted releases, or master becoming a deployment source). Deferred P3 children tic-08b3 (manifest-evolution ownership) and tic-gji1 (transactional/concurrent link creation) are explicit trigger-based, nonblocking residuals and do not defeat the supervised stable-manifest installer acceptance. No new deferred ticket is justified.

Final independent xhigh review outcome: “No meaningful issues.” It independently passed child evidence, the fresh-clone six-link lifecycle, live settings/runs/tags/releases, the current suite, and the system tk non-interference fingerprint. Every epic acceptance criterion is satisfied.
