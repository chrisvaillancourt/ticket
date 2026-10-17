# Fork maintenance and decisions

This repository is a personal fork of [`wedow/ticket`](https://github.com/wedow/ticket).
It keeps upstream's small, Git-native ticket model and fixes correctness and
workflow problems found while agents use `tk` in real repositories.

| Remote | Repository | Branch |
|---|---|---|
| `origin` | `chrisvaillancourt/ticket` | `main` (renamed from `master` on 2026-10-17) |
| `upstream` | `wedow/ticket` | `master` |

Fork baseline: upstream `194b71a` (2026-03-15).

## Upstream integration: deferred until upstream is active

**Decision (2026-10-17):** don't sync from upstream or open upstream pull
requests for now. As of 2026-10-17, upstream's last commit is the fork baseline
(2026-03-15) and its last merged pull request is from 2026-01-28, while
contributed pull requests have stayed open since February. Preparing upstream
pull requests now would cost export and rebase work with no reviewer to
receive it.

**Reconsider when** upstream merges a pull request or pushes a commit after
`194b71a`. Check with:

```bash
git fetch upstream
git log --oneline 194b71a..upstream/master
gh pr list -R wedow/ticket --state merged --limit 5
```

When that happens, sync first, then offer the candidates below one at a time.
Build each upstream branch from `upstream/master` and include only that
change's code, tests and changelog. Leave out `.tickets/`, the fork's docs, and
fork-only automation.

### Upstream candidates

| Change | Fork commits | Upstream overlap |
|---|---|---|
| `create` writes exactly one final newline (also `ticket-migrate-beads`) | `f50f1dc` | none found |
| `link` reports each new pair and rejects duplicate IDs | `186bef8`, `88c69a3` | none found |
| `create --description-file/--design-file/--acceptance-file` and `--dry-run` | `f8bdb67`, `88c69a3` | [PR #55](https://github.com/wedow/ticket/pull/55) adds `-d -` for stdin |
| `<command> --help` and `-h` | `0884cff`, `88c69a3` | none found |
| Plugins report a missing `.tickets` directory instead of `TICKETS_DIR: unbound variable` | `b4e8c3f` | none found |
| Frontmatter fields: portable insertion of missing fields (BSD sed silently skipped it) | `70c896c` | [PR #59](https://github.com/wedow/ticket/pull/59) moves the insert to awk |
| Frontmatter scoped to the opening block, so body lines such as `status: …` or `---` rules are never read or rewritten | `8a9f951` | none found |
| Exact ID matching in `dep`, `undep`, `unlink`, and `link` (`t-1` no longer matches `t-10`; `undep` no longer corrupts lists) | `d80a79c` | none found |
| `closed` no longer exits 141 on large ticket lists | `2a9c38d` | none found |
| Deferred work (`defer`, `undefer`, `deferred`) | `5c0b92b`, `ebc359e` | [issue #39](https://github.com/wedow/ticket/issues/39), [PR #50](https://github.com/wedow/ticket/pull/50) (`pending` status) |

Deferral is the most opinionated of these. Offer it as a design proposal on
issue #39, not as a drop-in pull request.

### Fork-only changes

These stay out of upstream pull requests: the local checkout installer
(`scripts/install-local.sh`), removal of the inherited release publishing
automation, the GitHub Actions hardening in
[docs/github-actions-policy.md](github-actions-policy.md), and agent harness
configuration.

## Design decisions

- **Deferral is a separate property, not a status.** `deferred`,
  `defer_until`, and `defer_reason` sit alongside `open`, `in_progress`, and
  `closed`, so pausing a ticket keeps its lifecycle status. Upstream PR #50's
  `pending` status was not adopted. See README "Deferred work".
- **`link` keeps upstream's link-every-pair semantics.** Changing the default
  to link only the first ticket to the rest would break upstream
  compatibility. Instead, `link` prints every new pair as
  `Added link: A <-> B`, so an unintended pair is visible, and it rejects
  duplicate IDs. There is no option to link only the first ticket to the rest.
  Run `tk link` once per pair for that.
- **Rich text comes from `--*-file PATH`, with `-` for stdin.** One mechanism
  covers files and heredocs. Inline `-d` text keeps its literal meaning, unlike
  PR #55's `-d -`. Only one field can read stdin per call. Giving the inline
  and file form of the same field is an error, not last-wins.
- **`create --dry-run` does not reserve its ID.** It prints the bytes a real
  create would write; a later real create generates a new ID.
- **Per-command help comes from the main help text.** One source keeps
  `tk help` and `tk <command> --help` in step. Only `tk <command> --help`
  (or `-h` as the first argument) is a help request, so option values and note
  text stay data; `create` also accepts `--help` later in its options.
- **Distribution is a local checkout.** `scripts/install-local.sh` links
  `tk` and the curated plugins into `~/.local/bin`; the commit is the version.
  Hosted releases wait until someone needs to install without a checkout (see
  ticket `tic-495c`).
- **No branch protection.** Changes land on `main` directly after local tests
  and review; see [docs/github-actions-policy.md](github-actions-policy.md).
