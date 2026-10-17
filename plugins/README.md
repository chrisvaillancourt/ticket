# Ticket Plugins

Official plugins that extend `tk` with additional commands.

## Writing Plugins

Plugins are executables named `tk-<cmd>` or `ticket-<cmd>` in `$PATH`. This repo uses the `ticket-` prefix for consistency.

Required metadata in the first 10 lines:

```bash
#!/usr/bin/env bash
# tk-plugin: sync tickets with GitHub issues
# tk-plugin-version: 1.0.0

set -euo pipefail
# implementation here
```

## Environment Variables

Plugins receive:
- `TICKETS_DIR` — path to the `.tickets/` directory, or unset when none is found
- `TK_SCRIPT` — absolute path to the `tk` script

A plugin that reads tickets should fail clearly when `TICKETS_DIR` is unset, with the same message as the core:

```bash
if [[ -z "${TICKETS_DIR:-}" ]]; then
    echo "Error: no .tickets directory found (searched parent directories)" >&2
    echo "Run 'tk create' to initialize, or set TICKETS_DIR env var" >&2
    exit 1
fi
```

Use `$TK_SCRIPT super <cmd>` to call built-ins without recursing into plugins:

```bash
#!/usr/bin/env bash
# tk-plugin: wrapper that creates tickets with defaults
# tk-plugin-version: 1.0.0

"$TK_SCRIPT" super create "$@" --type task --priority 1
```

## Adding a Plugin

1. Create `plugins/ticket-<name>` with metadata comments
2. `chmod +x plugins/ticket-<name>`
3. Add to `pkg/extras.txt` if it belongs in the curated checkout plugin list
4. Update the plugin documentation and changelog
