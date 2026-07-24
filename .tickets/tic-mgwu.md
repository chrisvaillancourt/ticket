---
id: tic-mgwu
status: closed
deps: [tic-pzkp, tic-xp3y]
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

Make security intent explicit before clearing the fork gate. Add `permissions: contents: read` and `workflow_dispatch`. Pin actions/checkout and astral-sh/setup-uv to reviewed full commit SHAs with version comments. Pin the uv version in setup-uv. Add a minimal `pyproject.toml` development dependency and committed `uv.lock`, then make `make test` use the locked environment rather than resolving Behave dynamically. Continue using an ephemeral GitHub-hosted runner. Do not add secrets or use `pull_request_target`.

After code hardening and release containment are in place, enable fork workflows from the signed-in Actions page, manually trigger or push a harmless reviewed commit, and record the successful run URL and commit SHA.

## Acceptance Criteria

Test declares read-only permissions, uses reviewed immutable action SHAs with human-readable version comments, pins uv, uses a committed lock for Behave and transitive dependencies, supports workflow_dispatch, and still runs on intended master/PR events. Release removal and all-external-contributor approval are complete first. The fork-specific Actions gate is cleared, a hosted Test run passes for fork master, and its URL/SHA are recorded. No repository secret, self-hosted runner, or pull_request_target trigger is introduced.

## Notes

**2026-07-24T20:30:06Z**

Implementation and verification complete. Implementation commit: eea148750ef7ecd2bb0219291e2759c31171d48d. Before state: no pyproject.toml or uv.lock; Test lacked full action SHA pins, explicit permissions, and workflow_dispatch; the fork had zero workflow runs. Lock evidence: generated with exact uv 0.11.32; Behave 1.3.3 and its transitives are locked; exact-version lock check and locked dependency tree passed. Local validation passed: focused 1 feature, 25 scenarios, 106 steps; full 14 features, 169 scenarios, 1200 steps. Code review reported no meaningful issues. The authorized push delivered Release workflow deletion and the hardened Test workflow. Authorized workflow_dispatch run https://github.com/chrisvaillancourt/ticket/actions/runs/30123980610, job 89582983296, ran on master at head eea148750ef7ecd2bb0219291e2759c31171d48d and completed successfully with the hosted full suite passing 14 features, 169 scenarios, and 1200 steps. No browser gate mutation was needed. Final remote state: .github/workflows/release.yml absent, only Test present, and no Release runs. Repository safeguards remain unchanged: read token permissions, no PR approval requirement, all_external fork-PR approval policy, zero secrets/variables/environments; allowed_actions remains all and SHA enforcement remains false, explicitly deferred to tic-1b09. Final external-state review reported no meaningful issues.
