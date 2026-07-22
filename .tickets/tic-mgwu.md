---
id: tic-mgwu
status: open
deps: [tic-pzkp]
links: []
created: 2026-07-22T18:37:59Z
type: chore
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [actions, security, test]
---
# Harden and enable the fork Test workflow

The imported Test workflow is small: actions/checkout, astral-sh/setup-uv, then make test on GitHub-hosted ubuntu-latest for master pushes and pull requests. Local verification already passes 12 features, 135 scenarios, and 881 steps for the writer-fix branch, but the fork has never produced a hosted workflow run. GitHub requires workflows in public forks to be enabled from the Actions tab; enabling or re-enabling an individual workflow does not necessarily clear that initial fork acknowledgement, and old pushes are not replayed.

Current gaps: Test has no explicit permissions block; checkout and setup-uv use mutable major tags; uv and Behave dependencies are not locked; allowed_actions is all; SHA pin enforcement is off; and the workflow has no workflow_dispatch trigger.

Resources:
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflows-in-forked-repositories
- https://docs.github.com/en/actions/reference/security/secure-use#using-third-party-actions
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions
- https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow

## Design

Make security intent explicit before clearing the fork gate. Add permissions: contents: read, add workflow_dispatch for deliberate validation, pin actions/checkout and astral-sh/setup-uv to verified full commit SHAs, pin the uv version, and make Behave/transitive resolution reproducible through an appropriate lock or exact dependency set. Continue using an ephemeral GitHub-hosted runner. Do not add secrets and do not use pull_request_target. Set external-contributor approval to the agreed safe policy before allowing PR-triggered runs; broader allowed-action and SHA-enforcement settings can follow after the workflow references are pinned and therefore do not hard-block this ticket.

After code hardening and release containment are in place, enable fork workflows from the signed-in Actions page, manually trigger or push a harmless reviewed commit, and record the successful run URL and commit SHA.

## Acceptance Criteria

Test declares read-only permissions, uses verified immutable action SHAs, uses reproducible uv/test dependencies, supports workflow_dispatch, and still runs on intended master/PR events. Release containment is complete first. The fork-specific Actions gate is cleared, a hosted Test run passes for fork master, and its URL/SHA are recorded. No repository secret is added and no self-hosted runner or pull_request_target trigger is used.
