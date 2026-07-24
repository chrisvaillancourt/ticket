# GitHub Actions and branch policy

This document records the security policy and live repository settings for
`chrisvaillancourt/ticket`. The settings below were audited on 2026-07-24.

## Actions policy

GitHub Actions is enabled with these repository settings:

```json
{"enabled":true,"allowed_actions":"selected","sha_pinning_required":true}
```

The selected-action policy is:

```json
{
  "github_owned_allowed": false,
  "verified_allowed": false,
  "patterns_allowed": [
    "actions/checkout@*",
    "astral-sh/setup-uv@*"
  ]
}
```

The wildcard patterns identify only the two reviewed action repositories; they
do not allow all GitHub-owned or verified Marketplace actions. The separate
`sha_pinning_required` setting rejects mutable tags and branches, so an allowed
repository can be used only with a full commit SHA.

### Applying the policy

The selected-actions endpoint is unavailable while `allowed_actions` is `all`.
When moving from that state, set the final main policy first, then immediately
set the complete selected-actions body:

```bash
api_version='X-GitHub-Api-Version: 2026-03-10'
repo_api='repos/chrisvaillancourt/ticket'

jq -n '{
  enabled: true,
  allowed_actions: "selected",
  sha_pinning_required: true
}' |
  gh api --method PUT -H "$api_version" \
    "$repo_api/actions/permissions" --input -

jq -n '{
  github_owned_allowed: false,
  verified_allowed: false,
  patterns_allowed: [
    "actions/checkout@*",
    "astral-sh/setup-uv@*"
  ]
}' |
  gh api --method PUT -H "$api_version" \
    "$repo_api/actions/permissions/selected-actions" --input -
```

Always set or reapply the complete selected-actions body last, and then run the
read-only assertions below. On 2026-07-24, a main-policy PUT made after the
selected-actions PUT reset `github_owned_allowed` to `true` despite the prior
explicit `false`; reapplying the complete selected body after the final main
PUT produced the intended state. The required ordering creates a brief
transition window from `all` in which the selected-action defaults may apply,
so perform the two requests back-to-back and do not run workflows until the
final verification succeeds.

The active `Test` workflow currently uses:

- `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1`
  (`v7.0.1`)
- `astral-sh/setup-uv@c771a70e6277c0a99b617c7a806ffedaca235ff9`
  (`v9.0.0`)

Its explicit workflow permission is `contents: read`, and the repository
default is:

```json
{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}
```

External pull requests require approval for all external contributors
(`all_external_contributors`). There are no Actions secrets, Actions variables,
or environments. The workflow uses `pull_request`, not
`pull_request_target`, does not reference `secrets`, and runs on GitHub-hosted
`ubuntu-latest`.

### Adding or updating an action

1. Review the action repository, ownership, release provenance, and the exact
   source at the intended commit.
2. Change the workflow to reference a verified, full 40-character commit SHA.
   Keep a version comment for maintainers; never use that mutable tag as the
   executable reference.
3. If this is a new repository, deliberately add only its exact
   `owner/repository@*` pattern. Do not enable all GitHub-owned or all verified
   actions.
4. Re-run the audit below, compare the workflow on `master` with the local
   file, dispatch `Test`, and require a successful GitHub-hosted run.

## Reproducible audit

These read-only commands rely on the caller's existing `gh` authentication;
they contain no credentials. Every request explicitly targets
`chrisvaillancourt/ticket` and GitHub REST API version `2026-03-10`.

```bash
api_version='X-GitHub-Api-Version: 2026-03-10'
repo_api='repos/chrisvaillancourt/ticket'

gh api -H "$api_version" "$repo_api/actions/permissions" |
  jq -e '
    .enabled == true and
    .allowed_actions == "selected" and
    .sha_pinning_required == true
  '

gh api -H "$api_version" "$repo_api/actions/permissions/selected-actions" |
  jq -e '
    .github_owned_allowed == false and
    .verified_allowed == false and
    (.patterns_allowed | sort) ==
      (["actions/checkout@*", "astral-sh/setup-uv@*"] | sort) and
    (.patterns_allowed | length) == 2
  '

gh api -H "$api_version" "$repo_api/actions/permissions/workflow" |
  jq -e '. == {
    default_workflow_permissions: "read",
    can_approve_pull_request_reviews: false
  }'

gh api -H "$api_version" \
  "$repo_api/actions/permissions/fork-pr-contributor-approval" |
  jq -e '.approval_policy == "all_external_contributors"'

gh api -H "$api_version" "$repo_api/actions/workflows" |
  jq -e '
    .total_count == 1 and
    ([.workflows[] | select(
      .name == "Test" and
      .path == ".github/workflows/test.yml" and
      .state == "active"
    )] | length == 1)
  '

gh api -H "$api_version" "$repo_api/actions/secrets" |
  jq -e '.total_count == 0'
gh api -H "$api_version" "$repo_api/actions/variables" |
  jq -e '.total_count == 0'
gh api -H "$api_version" "$repo_api/environments" |
  jq -e '.total_count == 0'

# Expected result: HTTP 404, "Branch not protected".
gh api -H "$api_version" "$repo_api/branches/master/protection"

gh api -H "$api_version" "$repo_api/rulesets" |
  jq -e '. == []'
```

Audit the workflow files themselves:

```bash
uses_lines=$(rg -n '^[[:space:]]*-[[:space:]]+uses:' .github/workflows)
printf '%s\n' "$uses_lines"
printf '%s\n' "$uses_lines" |
  awk '
    !/uses: (actions\/checkout|astral-sh\/setup-uv)@[0-9a-f]{40}([[:space:]]|$)/ {
      bad = 1
    }
    END { exit bad }
  '

! rg -n 'pull_request_target|self-hosted|secrets[.]' .github/workflows

remote_workflow=$(mktemp)
gh api -H "$api_version" \
  "$repo_api/contents/.github/workflows/test.yml?ref=master" \
  --jq '.content' |
  tr -d '\n' |
  base64 --decode > "$remote_workflow"
cmp .github/workflows/test.yml "$remote_workflow"
rm "$remote_workflow"
```

To verify behavior after an intentional policy or workflow change:

```bash
gh workflow run test.yml -R chrisvaillancourt/ticket --ref master
gh run list -R chrisvaillancourt/ticket \
  --workflow test.yml --event workflow_dispatch --limit 5
gh run watch RUN_ID -R chrisvaillancourt/ticket --exit-status
gh run view RUN_ID -R chrisvaillancourt/ticket
```

## Deliberate branch policy

There is currently no `master` branch protection and no repository ruleset.
The live audit returns HTTP 404 for branch protection and `[]` for rulesets.
This is deliberate for a solo-maintained fork with direct local ownership, no
production deployment, and no hosted release path.

The accepted risks are that a direct push can bypass pull-request review and
status checks, and that branch history or availability is not protected by a
ruleset. Requiring pull requests today would add recovery and maintenance
friction without protecting a shared deployment boundary.

Reconsider this decision as soon as any of these conditions becomes true:

- another maintainer receives write access;
- hosted releases are introduced; or
- `master` becomes a deployment source.

## References

- [REST API endpoints for GitHub Actions permissions](https://docs.github.com/en/rest/actions/permissions)
- [Managing GitHub Actions settings for a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)
- [Security hardening for GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use)
