---
id: tic-1b09
status: open
deps: [tic-mgwu]
links: []
created: 2026-07-22T18:37:59Z
type: chore
priority: 2
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [actions, security, settings]
---
# Enforce pinned Actions and document the solo-maintainer branch policy

Repository settings are part of the security boundary even when workflow YAML is safe. The immediate external-contributor approval prerequisite is tracked separately so this ticket can follow Test workflow pinning without creating a circular dependency.

Resources:
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#controlling-changes-from-forks-to-workflows-in-public-repositories
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/approve-runs-from-forks
- https://docs.github.com/en/actions/reference/security/secure-use

## Design

After Test references are pinned, require full-SHA action references and restrict allowed actions to the reviewed repositories currently needed by the workflow (`actions/checkout` and `astral-sh/setup-uv`). Keep default GITHUB_TOKEN read-only and unable to create or approve pull requests. Record exact API settings and the procedure for adding another action deliberately.

Do not add master branch protection yet. This is a solo-maintained fork with direct local ownership, no production deployment, and no hosted release path; mandatory PR-only changes would add recovery and maintenance friction without protecting a shared deployment boundary. Reconsider a ruleset when another maintainer receives write access, hosted releases are introduced, or master becomes a deployment source. Document settings that cannot be represented in git.

## Acceptance Criteria

Full-SHA pinning is required and allowed actions are restricted to the reviewed repositories used by Test. Read-only default token permissions remain in force and Actions cannot approve pull requests. The deliberate no-branch-protection decision and its reconsideration triggers are documented. Current settings and reproducible audit commands are recorded without credentials. No workflow uses pull_request_target or exposes secrets to external pull requests.
