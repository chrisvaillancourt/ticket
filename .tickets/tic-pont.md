---
id: tic-pont
status: in_progress
deps: []
links: []
created: 2026-07-22T18:37:59Z
type: feature
priority: 1
assignee: Chris Vaillancourt
parent: tic-jppr
tags: [install, docs, fork]
---
# Document and verify a local fork installation path

The fork should be usable immediately without waiting for hosted CI, a GitHub release, Homebrew, or AUR. The current development checkout contains the core ticket executable plus plugins. A machine may already have an upstream tk installed, so installation guidance must make command precedence and rollback explicit.

The local path must install or link both the core tk executable and the desired plugins; pointing only at ticket can leave extracted commands such as query, list, edit, or migrate-beads unavailable. Avoid modifying Git authentication, remotes, or signing configuration.

## Design

Provide a small checkout-local installer that creates user-scoped symlinks in `${PREFIX:-$HOME/.local}/bin` for `tk`, every curated plugin in `pkg/extras.txt`, and maintained aliases such as `list`. Symlinks keep the installation current after `git pull`. The installer must fail safely on any existing non-matching command; it may treat an existing link to the same checkout as an idempotent success. Do not offer a remote curl-pipe-shell path.

Provide a matching uninstall operation that removes only links it can prove belong to this checkout. Document PATH setup, prerequisites, active-command inspection, plugin precedence (`tk-<cmd>` is checked before `ticket-<cmd>`), switching from an upstream installation, update after `git pull`, and rollback. Never require sudo, overwrite or rename an existing command, or change Git/auth/signing configuration.

## Acceptance Criteria

Automated smoke coverage on a temporary user prefix verifies install, idempotent reinstall, collision refusal, `tk help`, `ls` and `list`, `query`, a noninteractive `edit` invocation with a stub editor, safe `migrate-beads` failure/smoke behavior, update-through-symlink behavior, and uninstall without touching unrelated files. Documentation covers macOS and Linux, identifies every active executable with `command -v`/`readlink` or equivalents, states Bash and jq requirements, handles existing upstream core and plugin commands safely, and includes update and rollback steps. No Release workflow or credentials are required.
