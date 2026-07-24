---
id: tic-pont
status: closed
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

## Notes

**2026-07-24T17:46:46Z**

Completed and independently reviewed the local fork installation path.

Implementation: ea39631 added the reversible checkout-local installer, documentation, and Behave coverage. The initial TDD red run had 8 scenarios errored with 48 undefined steps. Review finding F-01 identified CDPATH output contaminating checkout root discovery; 14b4337 added the focused duplicate-path regression and made discovery independent of CDPATH. The regression first failed with the duplicated checkout/scripts newline path, then passed after remediation.

Deferred hardening: 397537c added P3 deferred child chores tic-08b3 for ownership across manifest and alias evolution and tic-gji1 for transactional rollback-safe link creation.

Final validation: installer feature 9 scenarios and 80 steps passed; related plugin/edit/query coverage 3 features, 23 scenarios, and 132 steps passed; full suite 14 features, 166 scenarios, and 1173 steps passed. bash -n, Bash 3.2 compatibility, ShellCheck, and git diff --check passed.

Temporary-prefix smoke covered install, idempotence, explicit temporary command execution, expected safe migrate-beads failure, and ownership-safe uninstall. The parent PATH was unchanged; command -v tk remained /opt/homebrew/bin/tk, its link target remained ../Cellar/ticket/0.3.2/bin/tk, SHA-256 remained 408f2c113ecc3bc071507593a78386f1b4cc743be6491c9e9f2627efd4d9902b, and inode remained 16777233:24791280. The real Homebrew installation was not modified.

Independent review status: initial F-01 was remediated; final re-review reported no meaningful issues.
