---
id: tic-1b09
status: open
deps: []
links: []
created: 2026-07-22T18:37:59Z
type: chore
priority: 2
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [actions, security, settings]
---
# Strengthen public-fork Actions and branch controls

Repository settings are part of the security boundary even when workflow YAML is safe. On 2026-07-22 the fork defaults GITHUB_TOKEN to read, cannot approve pull requests, allows all actions, does not require full-SHA pinning, requires workflow approval only for first-time contributors, and has no master branch protection. Public pull-request workflows can execute repository-controlled Behave steps and shell code on GitHub-hosted runners. They cannot reach local machines, and fork PRs receive no repository secrets and a read-only token, but malicious code can use outbound network access and consume runner resources.

Resources:
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#controlling-changes-from-forks-to-workflows-in-public-repositories
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/approve-runs-from-forks
- https://docs.github.com/en/actions/reference/security/secure-use

## Design

Set approval to all external contributors before allowing public PR workflows. After workflow action references are pinned, consider enforcing full-SHA pinning and restricting allowed actions to the exact reviewed set. Keep default GITHUB_TOKEN read-only and prevent Actions from creating or approving pull requests. Evaluate a minimal master ruleset or branch protection that requires the Test check without making solo maintenance impractical.

Document settings that cannot be represented in git so a future owner can reproduce or audit them.

## Acceptance Criteria

All external contributors require approval before workflows run, read-only default token permissions remain in force, and the allowed-action/SHA policy is explicitly decided. Any branch protection or ruleset choice is documented with its solo-maintainer tradeoff. Current settings are captured in reproducible commands or public documentation without exposing credentials. A malicious external PR cannot receive fork secrets or bypass the chosen approval policy through pull_request_target.
