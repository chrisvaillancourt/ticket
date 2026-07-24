---
id: tic-xp3y
status: closed
deps: []
links: []
created: 2026-07-23T23:37:58Z
type: chore
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [actions, security, settings]
---
# Require approval for all external pull-request workflows

Before enabling fork pull-request workflows, require approval for every external contributor while preserving read-only token defaults and ensuring no pull_request_target trigger is present.

## Design

Make this narrow live-settings change independently of later action allowlisting, SHA enforcement, and branch policy so Test hardening has a non-circular prerequisite.

## Acceptance Criteria

The fork approval policy is all_external_contributors; default GITHUB_TOKEN permissions remain read-only and cannot approve pull requests; no pull_request_target trigger or Actions secret is introduced; before/after settings and reproducible read-only verification commands are recorded.

## Notes

**2026-07-24T17:14:02Z**

Independent review finding: the live approval policy was changed successfully, but the ticket lacked durable verification evidence. Remediation: record the exact before/change/after evidence and reproducible audit commands here before closing.

Before snapshot at 2026-07-24T17:00:02Z:
- approval_policy: first_time_contributors
- default_workflow_permissions: read
- can_approve_pull_request_reviews: false
- Actions secrets / variables / environments: 0 / 0 / 0
- allowed_actions: all
- sha_pinning_required: false
- Release: disabled_manually; Test: active
- no pull_request_target in .github/workflows (rg exit 1)

Applied command:
    gh api --method PUT -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/permissions/fork-pr-contributor-approval -f approval_policy=all_external_contributors
Result: HTTP/2.0 204 No Content.

After snapshot at 2026-07-24T17:00:25Z:
- approval_policy: all_external_contributors
- default_workflow_permissions remained read
- can_approve_pull_request_reviews remained false
- Actions secrets / variables / environments remained 0 / 0 / 0
- allowed_actions remained all
- sha_pinning_required remained false
- Release remained disabled_manually; Test remained active
- no pull_request_target in .github/workflows (rg exit 1)

Reproducible read-only verification commands:
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/permissions/fork-pr-contributor-approval --jq "{approval_policy}"
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/permissions/workflow --jq "{default_workflow_permissions,can_approve_pull_request_reviews}"
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/permissions --jq "{enabled,allowed_actions,sha_pinning_required}"
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/secrets --jq "{total_count}"
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/variables --jq "{total_count}"
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/environments --jq "{total_count}"
    gh api -H "X-GitHub-Api-Version: 2022-11-28" repos/chrisvaillancourt/ticket/actions/workflows --jq "{total_count,workflows:[.workflows[]|{id,name,path,state}]}"
    rg -n --hidden -S "pull_request_target" .github/workflows

Rollback value: first_time_contributors. If rollback is deliberately authorized, use the same PUT endpoint with -f approval_policy=first_time_contributors. No rollback was performed.
