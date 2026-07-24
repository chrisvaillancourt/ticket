# ticket

The git-backed issue tracker for AI agents. Rooted in the Unix Philosophy, `tk` is inspired by Joe Armstrong's [Minimal Viable Program](https://joearms.github.io/published/2014-06-25-minimal-viable-program.html) with additional quality of life features for managing and querying against complex issue dependency graphs.

`tk` was written as a full replacement for [beads](https://github.com/steveyegge/beads). It shares many similar commands but without the need for keeping a SQLite file in sync or a rogue background daemon mangling your changes. It ships with a `migrate-beads` command to make this a smooth transition.

Tickets are markdown files with YAML frontmatter in `.tickets/`. This allows AI agents to easily search them for relevant content without dumping ten thousand character JSONL lines into their context window.

Using ticket IDs as file names also allows IDEs to quickly navigate to the ticket for you. For example, you might run `git log` in your terminal and see something like:

```
nw-5c46: add SSE connection management 
```

VS Code allows you to Ctrl+Click or Cmd+Click the ID and jump directly to the file to read the details.

## Local checkout

Clone this repository and record the exact commit you are installing:

```bash
git clone https://github.com/chrisvaillancourt/ticket.git
cd ticket
git rev-parse HEAD
```

You can run the checkout without installing it:

```bash
env PATH="$PWD/plugins:$PATH" ./ticket help
```

Adding the checkout's `plugins/` directory to `PATH` makes the bundled plugins
available to that invocation without installing them.

For regular use, install checkout-owned symlinks into a user prefix:

```bash
./scripts/install-local.sh install
```

The default prefix is `$HOME/.local`, so this creates `$HOME/.local/bin/tk`
plus `ticket-edit`, `ticket-ls`, `ticket-list`, `ticket-query`, and
`ticket-migrate-beads`. The curated plugin list comes from `pkg/extras.txt`.
To use another user-owned prefix:

```bash
PREFIX="$HOME/tools/ticket" ./scripts/install-local.sh install
```

The installer never uses `sudo`, edits shell profiles, or replaces an existing
entry in the selected prefix. It preflights every destination and aborts
without creating any command links if a regular file, directory, broken link,
or link to another checkout would be replaced. Repeating installation for
exact links to this checkout is safe.

### PATH and existing installations

Add the selected bin directory before other command directories. For the
default prefix, add this to `~/.zshrc` on macOS or `~/.bashrc` on Linux:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Open a new shell or run `hash -r`. Putting the local prefix first switches
command precedence without uninstalling an existing Homebrew, AUR, or other
`tk`; removing or reordering that PATH entry switches back.

Inspect every core/plugin name that can affect the installed commands:

```bash
for command_name in \
  tk \
  tk-edit ticket-edit \
  tk-ls ticket-ls \
  tk-list ticket-list \
  tk-query ticket-query \
  tk-migrate-beads ticket-migrate-beads
do
  command_path=$(command -v "$command_name" 2>/dev/null) || continue
  printf '%s: %s\n' "$command_name" "$command_path"
  if [ -L "$command_path" ]; then
    printf '  -> %s\n' "$(readlink "$command_path")"
  fi
done
type -a tk
```

The core checks `tk-<command>` before `ticket-<command>`. Consequently, an
active `tk-query`, for example, overrides the installed `ticket-query`; inspect
both names before relying on PATH order alone.

### Update and rollback

The commands are symlinks into the checkout, so a normal fast-forward update
is immediately active without reinstalling:

```bash
git status --short
git pull --ff-only
git rev-parse HEAD
./scripts/install-local.sh install  # optional idempotence check
```

Rollback the local installation from the same checkout:

```bash
./scripts/install-local.sh uninstall
hash -r
command -v tk
```

With a custom prefix, pass the same `PREFIX` to uninstall. Uninstall removes
only exact links owned by this checkout; it preserves unrelated or retargeted
entries. It does not remove the checkout or change PATH, so remove/reorder the
PATH line separately if desired.

## Requirements

The core and local installer require Bash and standard command-line utilities
available on macOS and Linux. The `query` and `migrate-beads` plugins require
`jq`. `tk` uses `rg` (ripgrep) when available and otherwise falls back to
`grep`.

## Agent Setup

Add this line to your `CLAUDE.md` or `AGENTS.md`:

```
This project uses a CLI ticket system for task management. Run `tk help` when you need to use it.
```

Claude Opus picks it up naturally from there. Other models may need additional guidance.

## Usage

```bash
tk - minimal ticket system with dependency tracking

Usage: tk <command> [args]

Commands:
  create [title] [options] Create ticket, prints ID
    -d, --description      Description text
    --design               Design notes
    --acceptance           Acceptance criteria
    -t, --type             Type (bug|feature|task|epic|chore) [default: task]
    -p, --priority         Priority 0-4, 0=highest [default: 2]
    -a, --assignee         Assignee [default: git user.name]
    --external-ref         External reference (e.g., gh-123, JIRA-456)
    --parent               Parent ticket ID
    --tags                 Comma-separated tags (e.g., --tags ui,backend,urgent)
  start <id>               Set status to in_progress
  close <id>               Set status to closed
  reopen <id>              Set status to open
  status <id> <status>     Update status (open|in_progress|closed)
  dep <id> <dep-id>        Add dependency (id depends on dep-id)
  dep tree [--full] <id>   Show dependency tree (--full disables dedup)
  dep cycle                Find dependency cycles in open tickets
  undep <id> <dep-id>      Remove dependency
  link <id> <id> [id...]   Link tickets together (symmetric)
  unlink <id> <target-id>  Remove link between tickets
  ls|list [--status=X] [-a X] [-T X]   List tickets
  ready [-a X] [-T X]      List open/in-progress tickets with deps resolved
  blocked [-a X] [-T X]    List open/in-progress tickets with unresolved deps
  closed [--limit=N] [-a X] [-T X] List recently closed tickets (default 20, by mtime)
  show <id>                Display ticket
  add-note <id> [text]     Append timestamped note (or pipe via stdin)
  super <cmd> [args]       Bypass plugins, run built-in command directly

Checkout plugins:
  edit <id>                Open ticket in $EDITOR
  ls|list [--status=X] [-a X] [-T X]   List tickets
  query [jq-filter]        Output tickets as JSON, optionally filtered (requires jq)
  migrate-beads            Import tickets from .beads/issues.jsonl (requires jq)

Searches parent directories for .tickets/ (override with TICKETS_DIR env var)
Supports partial ID matching (e.g., 'tk show 5c4' matches 'nw-5c46')
```

## Plugins

Executables named `tk-<cmd>` or `ticket-<cmd>` in your PATH are invoked automatically. This allows you to add custom commands or override built-in ones.

```bash
# Create a simple plugin
cat > ~/.local/bin/tk-hello <<'EOF'
#!/bin/bash
# tk-plugin: Say hello
echo "Hello from plugin!"
EOF
chmod +x ~/.local/bin/tk-hello

# Now it's available
tk hello        # runs tk-hello
tk help         # lists it under "Plugins"
```

**Plugin descriptions** (shown in `tk help`):
- Scripts: comment `# tk-plugin: description` in first 10 lines
- Binaries: `--tk-describe` flag outputs `tk-plugin: description`

**Plugin environment variables:**
- `TICKETS_DIR` - path to the .tickets directory (may be empty)
- `TK_SCRIPT` - absolute path to the tk script

**Calling built-ins from plugins:**
```bash
#!/bin/bash
# tk-plugin: Custom create with extras
id=$("$TK_SCRIPT" super create "$@")
echo "Created $id, doing extra stuff..."
```

Use `tk super <cmd>` to bypass plugins and run the built-in directly.

## Testing

The tests are written in the Behavior-Driven Development library [behave](https://behave.readthedocs.io/en/latest/) and require Python.

If you have `uv` [installed](https://docs.astral.sh/uv/getting-started/installation/) simply:

```sh
make test
```

## Migrating from Beads

```bash
tk migrate-beads

# review new files if you like
git status

# check state matches expectations
tk ready
tk blocked

# compare against
bd ready
bd blocked

# all good, let's go
git rm -rf .beads
git add .tickets
git commit -am "ditch beads"
```

For a thorough system-wide Beads cleanup, see [banteg's uninstall script](https://gist.github.com/banteg/1a539b88b3c8945cd71e4b958f319d8d).

## License

MIT
