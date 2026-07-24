---
id: tic-1b09
status: closed
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

## Notes

**2026-07-24T22:06:57Z**

Implementation completed: enforced selected GitHub Actions repositories with required action SHA pinning, preserved read-only workflow-token and external-contributor controls, documented the live Actions policy, audit/apply procedures, reusable-workflow exception, and deliberate solo-maintainer no-protection decision.

Implementation commits: 85e52651d8dc31ed66a7d77f28c094b6cb54fa52 and b200bd4130c3aefab9c635ecfddbb0cdc2206961.

Exact before state: Actions {"enabled":true,"allowed_actions":"all","sha_pinning_required":false}; selected-actions GET returned HTTP 409; workflow token {"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}; fork approval {"approval_policy":"all_external_contributors"}; Actions secrets 0, variables 0, environments 0; master protection HTTP 404; rulesets [].

Exact final main state: {"enabled":true,"allowed_actions":"selected","selected_actions_url":"https://api.github.com/repositories/1303185523/actions/permissions/selected-actions","sha_pinning_required":true}.
Exact final selected state: {"github_owned_allowed":false,"patterns_allowed":["actions/checkout@*","astral-sh/setup-uv@*"],"verified_allowed":false}.

Observed API ordering quirk and correction: the final main-policy PUT reset github_owned_allowed to true despite a prior explicit false. After authorization, the complete selected-actions body was reapplied last, restoring the intended narrow false/false/exact-pattern state. The documented safe ordering is final main policy first, complete selected-actions body last, then exact verification before running workflows.

Focused static evidence: exactly two approved action references, actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 and astral-sh/setup-uv@c771a70e6277c0a99b617c7a806ffedaca235ff9, both full 40-character SHAs; no job-level reusable-workflow uses, pull_request_target, self-hosted label, or secrets reference; local and remote master Test YAML matched byte-for-byte; git diff --check passed.

Local full suite: 14 features passed, 169 scenarios passed, 1200 steps passed; 0 failed and 0 skipped.

Hosted Test: https://github.com/chrisvaillancourt/ticket/actions/runs/30129140387; run 30129140387; job 89599528441; head 0867cafafe18b263106166104ff37b2962290a1d; event workflow_dispatch; conclusion success; GitHub-hosted runner group GitHub Actions with ubuntu-latest label.

Unchanged live controls after implementation: workflow token remained read with can_approve_pull_request_reviews false; fork approval remained all_external_contributors; exactly one active Test workflow; Actions secrets 0, variables 0, environments 0; master protection still HTTP 404; rulesets still [].

Review history: the first independent review raised a low-severity finding that the documentation overstated SHA enforcement for reusable workflows and that the static audit could miss job-level reusable-workflow uses. Commit b200bd4130c3aefab9c635ecfddbb0cdc2206961 corrected the guarantee, documented the GitHub reusable-workflow exception and deliberate full-SHA procedure, prohibited job-level reusable workflows, and required the exact two current step action references. Final xhigh independent re-review outcome: “No meaningful issues.” No deferred ticket is needed.
