"""Step definitions for ticket CLI BDD tests."""

import json
import os
import re
import shlex
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from behave import given, when, then, register_type, use_step_matcher
import parse


PUNCTUATION_REASON = '# Waiting on "API" \\ docs: owner\'s [draft] & review!'
QUERY_ESCAPE_SCALAR = 'quote " slash \\ hash # colon: bracket [ indicator ! tab\tend'
QUERY_ESCAPE_ARRAY = [
    'quote"element',
    'back\\slash',
    'bracket[value]',
    'hash#value',
    'colon:value',
    'tab\tvalue',
    "apostrophe's",
]


# Use regex matcher for more flexible step definitions
use_step_matcher("re")


# ============================================================================
# Helper Functions
# ============================================================================

def get_ticket_script(context):
    """Get the ticket script path, defaulting to ./ticket or using TICKET_SCRIPT env var."""
    ticket_script = os.environ.get('TICKET_SCRIPT')
    if ticket_script:
        return ticket_script
    return str(Path(context.project_dir) / 'ticket')


def create_ticket(context, ticket_id, title, priority=2, parent=None):
    """Helper to create a ticket file."""
    tickets_dir = Path(context.test_dir) / '.tickets'
    tickets_dir.mkdir(parents=True, exist_ok=True)

    ticket_path = tickets_dir / f'{ticket_id}.md'
    content = f'''---
id: {ticket_id}
status: open
deps: []
links: []
created: 2024-01-01T00:00:00Z
type: task
priority: {priority}
'''
    if parent:
        content += f'parent: {parent}\n'
    content += f'''---
# {title}

Description
'''
    ticket_path.write_text(content)

    if not hasattr(context, 'tickets'):
        context.tickets = {}
    context.tickets[ticket_id] = ticket_path
    return ticket_path


def set_ticket_field(context, ticket_id, field, value):
    """Set or insert a scalar frontmatter field in a fixture ticket."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    pattern = rf'^{re.escape(field)}:.*$'
    replacement = f'{field}: {value}'
    if re.search(pattern, content, re.MULTILINE):
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    else:
        content = content.replace('---\n', f'---\n{replacement}\n', 1)
    ticket_path.write_text(content)


def encode_yaml_single_quoted_scalar(value):
    """Encode one-line text as the YAML single-quoted subset used by tickets."""
    return "'" + value.replace("'", "''") + "'"


def decode_yaml_single_quoted_scalar(value):
    """Decode and validate the YAML single-quoted subset used by tickets."""
    assert len(value) >= 2 and value[0] == "'" and value[-1] == "'", \
        f"Expected a single-quoted YAML scalar, got: {value!r}"
    inner = value[1:-1]
    decoded = []
    index = 0
    while index < len(inner):
        if inner[index] == "'":
            assert index + 1 < len(inner) and inner[index + 1] == "'", \
                f"Unescaped apostrophe in YAML scalar: {value!r}"
            decoded.append("'")
            index += 2
        else:
            decoded.append(inner[index])
            index += 1
    return ''.join(decoded)


def frontmatter_field_value(content, field):
    """Return the raw value for a frontmatter field."""
    match = re.search(rf'^{re.escape(field)}:\s*(.*)$', content, re.MULTILINE)
    assert match, f"Field '{field}' not found\nContent: {content}"
    return match.group(1)


def assert_normalized_trailing_whitespace(ticket_path):
    """Assert a ticket ends in one LF and has no line-end whitespace."""
    content = ticket_path.read_bytes()
    assert content.endswith(b'\n'), f"Ticket does not end with a newline: {ticket_path}"
    assert not content.endswith(b'\n\n'), f"Ticket ends with more than one newline: {ticket_path}"

    lines_with_trailing_whitespace = [
        line_number
        for line_number, line in enumerate(content.split(b'\n')[:-1], start=1)
        if line.endswith((b' ', b'\t', b'\r'))
    ]
    assert not lines_with_trailing_whitespace, \
        f"Ticket has trailing whitespace on lines {lines_with_trailing_whitespace}: {ticket_path}"


# ============================================================================
# Given Steps
# ============================================================================

@given(r'a clean tickets directory')
def step_clean_tickets_directory(context):
    """Ensure we start with a clean .tickets directory."""
    tickets_dir = Path(context.test_dir) / '.tickets'
    if tickets_dir.exists():
        import shutil
        shutil.rmtree(tickets_dir)
    tickets_dir.mkdir(parents=True, exist_ok=True)


@given(r'the tickets directory does not exist')
def step_tickets_dir_not_exist(context):
    """Ensure .tickets directory does not exist."""
    tickets_dir = Path(context.test_dir) / '.tickets'
    if tickets_dir.exists():
        import shutil
        shutil.rmtree(tickets_dir)


@given(r'a Beads issues file containing:')
def step_beads_issues_file(context):
    """Write the scenario JSONL to the location expected by migrate-beads."""
    beads_dir = Path(context.test_dir) / '.beads'
    beads_dir.mkdir(parents=True, exist_ok=True)
    (beads_dir / 'issues.jsonl').write_text(context.text.strip() + '\n')


@given(r'a ticket exists with ID "(?P<ticket_id>[^"]+)" and title "(?P<title>[^"]+)" with priority (?P<priority>\d+)')
def step_ticket_exists_with_priority(context, ticket_id, title, priority):
    """Create a ticket with given ID, title, and priority."""
    create_ticket(context, ticket_id, title, priority=int(priority))


@given(r'a ticket exists with ID "(?P<ticket_id>[^"]+)" and title "(?P<title>[^"]+)" with parent "(?P<parent_id>[^"]+)"')
def step_ticket_exists_with_parent(context, ticket_id, title, parent_id):
    """Create a ticket with given ID, title, and parent."""
    create_ticket(context, ticket_id, title, parent=parent_id)


@given(r'a ticket exists with ID "(?P<ticket_id>[^"]+)" and title "(?P<title>[^"]+)"')
def step_ticket_exists(context, ticket_id, title):
    """Create a ticket with given ID and title (basic, no extra params)."""
    # This is the most generic form - the more specific ones should be defined first
    create_ticket(context, ticket_id, title)


@given(r'ticket "(?P<ticket_id>[^"]+)" has status "(?P<status>[^"]+)"')
def step_ticket_has_status(context, ticket_id, status):
    """Set ticket status."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    content = re.sub(r'^status: \w+', f'status: {status}', content, flags=re.MULTILINE)
    ticket_path.write_text(content)


@given(r'ticket "(?P<ticket_id>[^"]+)" has field "(?P<field>[^"]+)" with value "(?P<value>[^"]+)"')
def step_ticket_fixture_has_field(context, ticket_id, field, value):
    """Set an arbitrary frontmatter field on a fixture ticket."""
    set_ticket_field(context, ticket_id, field, value)


@given(r'ticket "(?P<ticket_id>[^"]+)" has defer_until set to today in UTC')
def step_ticket_defer_until_today(context, ticket_id):
    """Set defer_until to the current UTC calendar date."""
    today = datetime.now(timezone.utc).date().isoformat()
    set_ticket_field(context, ticket_id, 'defer_until', today)


@given(r'I remember the content of ticket "(?P<ticket_id>[^"]+)"')
def step_remember_ticket_content(context, ticket_id):
    """Remember a ticket byte-for-byte for no-mutation assertions."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    if not hasattr(context, 'remembered_ticket_content'):
        context.remembered_ticket_content = {}
    context.remembered_ticket_content[ticket_id] = ticket_path.read_bytes()


@given(r'ticket "(?P<ticket_id>[^"]+)" has query escaping fixture fields')
def step_ticket_has_query_escaping_fields(context, ticket_id):
    """Add YAML-subset fixture fields containing JSON-sensitive characters."""
    set_ticket_field(
        context,
        ticket_id,
        'special"key',
        encode_yaml_single_quoted_scalar(QUERY_ESCAPE_SCALAR)
    )
    encoded_items = ', '.join(
        encode_yaml_single_quoted_scalar(item) for item in QUERY_ESCAPE_ARRAY
    )
    set_ticket_field(context, ticket_id, 'special_list', f'[{encoded_items}]')


@given(r'ticket "(?P<ticket_id>[^"]+)" depends on "(?P<dep_id>[^"]+)"')
def step_ticket_depends_on(context, ticket_id, dep_id):
    """Add dependency to ticket."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    # Parse current deps
    deps_match = re.search(r'^deps: \[(.*?)\]', content, re.MULTILINE)
    if deps_match:
        current_deps = deps_match.group(1)
        if current_deps:
            deps_list = [d.strip() for d in current_deps.split(',')]
            if dep_id not in deps_list:
                deps_list.append(dep_id)
        else:
            deps_list = [dep_id]
        new_deps = ', '.join(deps_list)
        content = re.sub(r'^deps: \[.*?\]', f'deps: [{new_deps}]', content, flags=re.MULTILINE)

    ticket_path.write_text(content)


@given(r'ticket "(?P<ticket_id>[^"]+)" is linked to "(?P<link_id>[^"]+)"')
def step_ticket_linked_to(context, ticket_id, link_id):
    """Create bidirectional link between tickets."""
    # Update first ticket
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    links_match = re.search(r'^links: \[(.*?)\]', content, re.MULTILINE)
    if links_match:
        current_links = links_match.group(1)
        if current_links:
            links_list = [l.strip() for l in current_links.split(',')]
            if link_id not in links_list:
                links_list.append(link_id)
        else:
            links_list = [link_id]
        new_links = ', '.join(links_list)
        content = re.sub(r'^links: \[.*?\]', f'links: [{new_links}]', content, flags=re.MULTILINE)
    ticket_path.write_text(content)

    # Update second ticket
    link_path = Path(context.test_dir) / '.tickets' / f'{link_id}.md'
    content = link_path.read_text()
    links_match = re.search(r'^links: \[(.*?)\]', content, re.MULTILINE)
    if links_match:
        current_links = links_match.group(1)
        if current_links:
            links_list = [l.strip() for l in current_links.split(',')]
            if ticket_id not in links_list:
                links_list.append(ticket_id)
        else:
            links_list = [ticket_id]
        new_links = ', '.join(links_list)
        content = re.sub(r'^links: \[.*?\]', f'links: [{new_links}]', content, flags=re.MULTILINE)
    link_path.write_text(content)


@given(r'ticket "(?P<ticket_id>[^"]+)" has a notes section')
def step_ticket_has_notes(context, ticket_id):
    """Ensure ticket has a notes section."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    if '## Notes' not in content:
        content += '\n## Notes\n'
        ticket_path.write_text(content)


@given(r'I am in subdirectory "(?P<subdir>[^"]+)"')
def step_in_subdirectory(context, subdir):
    """Change to a subdirectory (creating it if needed)."""
    subdir_path = Path(context.test_dir) / subdir
    subdir_path.mkdir(parents=True, exist_ok=True)
    context.working_dir = str(subdir_path)


@given(r'a separate tickets directory exists at "(?P<dir_path>[^"]+)" with ticket "(?P<ticket_id>[^"]+)" titled "(?P<title>[^"]+)"')
def step_separate_tickets_dir(context, dir_path, ticket_id, title):
    """Create a separate tickets directory with a ticket."""
    tickets_dir = Path(context.test_dir) / dir_path
    tickets_dir.mkdir(parents=True, exist_ok=True)

    ticket_path = tickets_dir / f'{ticket_id}.md'
    content = f'''---
id: {ticket_id}
status: open
deps: []
links: []
created: 2024-01-01T00:00:00Z
type: task
priority: 2
---
# {title}

Description
'''
    ticket_path.write_text(content)


# ============================================================================
# When Steps
# ============================================================================

@when(r'I run "(?P<command>(?:[^"\\]|\\.)+)" in non-TTY mode')
def step_run_command_non_tty(context, command):
    """Run a command simulating non-TTY mode."""
    # Unescape \" to " in the command string
    command = command.replace('\\"', '"')

    ticket_script = get_ticket_script(context)
    cmd = command.replace('ticket ', f'{ticket_script} ', 1)

    result = subprocess.run(
        cmd,
        shell=True,
        cwd=context.test_dir,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL  # Simulate non-TTY
    )

    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode


@when(r'I run "(?P<command>(?:[^"\\]|\\.)+)" with no stdin')
def step_run_command_no_stdin(context, command):
    """Run a command with stdin closed."""
    ticket_script = get_ticket_script(context)
    cmd = command.replace('ticket ', f'{ticket_script} ', 1)

    result = subprocess.run(
        cmd,
        shell=True,
        cwd=context.test_dir,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL
    )

    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode


@when(r'I run "(?P<command>(?:[^"\\]|\\.)+)" with TICKETS_DIR set to "(?P<tickets_dir>[^"]+)"')
def step_run_command_with_env(context, command, tickets_dir):
    """Run a ticket CLI command with custom TICKETS_DIR."""
    command = command.replace('\\"', '"')
    ticket_script = get_ticket_script(context)
    cmd = command.replace('ticket ', f'{ticket_script} ', 1)

    # Use working_dir if set (from subdirectory step), otherwise test_dir
    cwd = getattr(context, 'working_dir', context.test_dir)

    # Resolve tickets_dir relative to test_dir
    env = os.environ.copy()
    env['TICKETS_DIR'] = str(Path(context.test_dir) / tickets_dir)

    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=env
    )

    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode
    context.last_command = command


@when(r'I run "(?P<command>(?:[^"\\]|\\.)+)"')
def step_run_command(context, command):
    """Run a ticket CLI command."""
    # Unescape \" to " in the command string
    command = command.replace('\\"', '"')

    ticket_script = get_ticket_script(context)
    cmd = command.replace('ticket ', f'{ticket_script} ', 1)

    # Use working_dir if set (from subdirectory step), otherwise test_dir
    cwd = getattr(context, 'working_dir', context.test_dir)

    # Include plugin directory in PATH if plugins were created
    env = os.environ.copy()
    if hasattr(context, 'plugin_dir'):
        env['PATH'] = context.plugin_dir + ':' + env.get('PATH', '')

    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,  # Non-interactive tests
        env=env
    )

    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode
    context.last_command = command

    # If this was a create command, track the created ticket ID
    if 'ticket create' in command and result.returncode == 0:
        context.last_created_id = result.stdout.strip()


@when(r'I defer ticket "(?P<ticket_id>[^"]+)" with a reason containing (?P<control>a line feed|a carriage return)')
def step_defer_with_multiline_reason(context, ticket_id, control):
    """Pass a literal line break in a defer reason without shell quoting."""
    ticket_script = get_ticket_script(context)
    cwd = getattr(context, 'working_dir', context.test_dir)
    separator = '\n' if control == 'a line feed' else '\r'
    result = subprocess.run(
        [ticket_script, 'defer', ticket_id, '--reason', f'first line{separator}second line'],
        cwd=cwd,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=os.environ.copy()
    )
    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode


@when(r'I defer ticket "(?P<ticket_id>[^"]+)" with the punctuation regression reason')
def step_defer_with_punctuation_reason(context, ticket_id):
    """Defer with YAML- and JSON-sensitive punctuation using direct argv."""
    ticket_script = get_ticket_script(context)
    cwd = getattr(context, 'working_dir', context.test_dir)
    result = subprocess.run(
        [ticket_script, 'defer', ticket_id, '--reason', PUNCTUATION_REASON],
        cwd=cwd,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=os.environ.copy()
    )
    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode


# ============================================================================
# Then Steps
# ============================================================================

@then(r'the command should succeed')
def step_command_succeed(context):
    """Assert command returned exit code 0."""
    assert context.returncode == 0, \
        f"Command failed with exit code {context.returncode}\nstdout: {context.stdout}\nstderr: {context.stderr}"


@then(r'the command should fail')
def step_command_fail(context):
    """Assert command returned non-zero exit code."""
    assert context.returncode != 0, \
        f"Command succeeded but was expected to fail\nstdout: {context.stdout}"


@then(r'the output should be "(?P<expected>[^"]*)"')
def step_output_equals(context, expected):
    """Assert output exactly matches expected string."""
    actual = context.stdout
    assert actual == expected, f"Expected '{expected}' but got '{actual}'"


@then(r'the output should be empty')
def step_output_empty(context):
    """Assert output is empty."""
    assert context.stdout == '', f"Expected empty output but got: {context.stdout}"


@then(r'the output should contain "(?P<text>[^"]+)"')
def step_output_contains(context, text):
    """Assert output contains text."""
    output = context.stdout + context.stderr
    assert text in output, f"Expected output to contain '{text}'\nActual output: {output}"


@then(r'the output should not contain "(?P<text>[^"]+)"')
def step_output_not_contains(context, text):
    """Assert output does not contain text."""
    output = context.stdout + context.stderr
    assert text not in output, f"Expected output to NOT contain '{text}'\nActual output: {output}"


@then(r'the output should expose the punctuation regression reason')
def step_output_exposes_punctuation_reason(context):
    """Assert a human-readable command displays the decoded reason exactly."""
    output = context.stdout + context.stderr
    assert PUNCTUATION_REASON in output, \
        f"Expected exact punctuation reason in output\nActual output: {output}"


@then(r'the shown defer reason should have YAML value "(?P<value>[^"]+)"')
def step_show_has_yaml_defer_reason(context, value):
    """Assert show emits a semantically exact single-quoted YAML scalar."""
    raw = frontmatter_field_value(context.stdout, 'defer_reason')
    assert decode_yaml_single_quoted_scalar(raw) == value


@then(r'the shown defer reason should decode to the punctuation regression reason')
def step_show_decodes_punctuation_reason(context):
    """Assert show preserves exact punctuation through YAML encoding."""
    raw = frontmatter_field_value(context.stdout, 'defer_reason')
    assert decode_yaml_single_quoted_scalar(raw) == PUNCTUATION_REASON


@then(r'the output should match a ticket ID pattern')
def step_output_matches_id_pattern(context):
    """Assert output matches ticket ID pattern (prefix-hash)."""
    # Prefix can be alphanumeric (from directory name), hash is 4 hex chars
    pattern = r'^[a-z0-9]+-[a-z0-9]{4}$'
    assert re.match(pattern, context.stdout), \
        f"Output '{context.stdout}' does not match ticket ID pattern"


@then(r'the output should match pattern "(?P<pattern>[^"]+)"')
def step_output_matches_pattern(context, pattern):
    """Assert output matches regex pattern."""
    assert re.search(pattern, context.stdout), \
        f"Output does not match pattern '{pattern}'\nActual output: {context.stdout}"


@then(r'the output should match box-drawing tree format')
def step_output_matches_tree_format(context):
    """Assert output contains box-drawing characters for tree."""
    output = context.stdout
    has_tree_chars = any(c in output for c in ['├', '└', '│', '─'])
    assert has_tree_chars, f"Output does not contain box-drawing characters:\n{output}"


@then(r'a ticket file should exist with title "(?P<title>[^"]+)"')
def step_ticket_file_exists_with_title(context, title):
    """Assert a ticket file exists with given title."""
    tickets_dir = Path(context.test_dir) / '.tickets'
    ticket_id = context.last_created_id
    ticket_path = tickets_dir / f'{ticket_id}.md'

    assert ticket_path.exists(), f"Ticket file {ticket_path} does not exist"
    content = ticket_path.read_text()
    assert f'# {title}' in content, f"Ticket does not have title '{title}'\nContent: {content}"


@then(r'the tickets directory should exist')
def step_tickets_dir_exists(context):
    """Assert .tickets directory exists."""
    tickets_dir = Path(context.test_dir) / '.tickets'
    assert tickets_dir.exists(), f".tickets directory does not exist"


@then(r'tickets directory should exist in current subdirectory')
def step_tickets_dir_exists_in_subdir(context):
    """Assert .tickets directory exists in the current working subdirectory."""
    cwd = getattr(context, 'working_dir', context.test_dir)
    tickets_dir = Path(cwd) / '.tickets'
    assert tickets_dir.exists(), f".tickets directory does not exist in {cwd}"


@then(r'the created ticket should contain "(?P<text>[^"]+)"')
def step_created_ticket_contains(context, text):
    """Assert the most recently created ticket contains text."""
    ticket_id = context.last_created_id
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    assert text in content, f"Ticket does not contain '{text}'\nContent: {content}"


@then(r'the created ticket should have field "(?P<field>[^"]+)" with value "(?P<value>[^"]+)"')
def step_created_ticket_has_field(context, field, value):
    """Assert the most recently created ticket has a field with value."""
    ticket_id = context.last_created_id
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    pattern = rf'^{re.escape(field)}:\s*(.+)$'
    match = re.search(pattern, content, re.MULTILINE)
    assert match, f"Field '{field}' not found in ticket\nContent: {content}"
    actual = match.group(1).strip()
    assert actual == value, f"Field '{field}' has value '{actual}', expected '{value}'"


@then(r'the created ticket should have a valid created timestamp')
def step_created_ticket_has_timestamp(context):
    """Assert the created ticket has a valid timestamp."""
    ticket_id = context.last_created_id
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    pattern = r'^created:\s*\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z'
    assert re.search(pattern, content, re.MULTILINE), \
        f"No valid created timestamp found\nContent: {content}"


@then(r'the created ticket file should end with exactly one newline and have no trailing whitespace')
def step_created_ticket_has_normalized_whitespace(context):
    """Assert the most recently created ticket has normalized line endings."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{context.last_created_id}.md'
    assert_normalized_trailing_whitespace(ticket_path)


@then(r'ticket "(?P<ticket_id>[^"]+)" should end with exactly one newline and have no trailing whitespace')
def step_ticket_has_normalized_whitespace(context, ticket_id):
    """Assert the specified ticket has normalized line endings."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    assert ticket_path.exists(), f"Ticket file {ticket_path} does not exist"
    assert_normalized_trailing_whitespace(ticket_path)


@then(r'ticket "(?P<ticket_id>[^"]+)" should not have field "(?P<field>[^"]+)"')
def step_ticket_does_not_have_field(context, ticket_id, field):
    """Assert a YAML frontmatter field is absent."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    assert not re.search(rf'^{re.escape(field)}:', content, re.MULTILINE), \
        f"Field '{field}' unexpectedly found in ticket\nContent: {content}"


@then(r'ticket "(?P<ticket_id>[^"]+)" should be unchanged')
def step_ticket_unchanged(context, ticket_id):
    """Assert a failed command did not modify the ticket."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    expected = context.remembered_ticket_content[ticket_id]
    actual = ticket_path.read_bytes()
    assert actual == expected, f"Ticket '{ticket_id}' changed unexpectedly"


@then(r'ticket "(?P<ticket_id>[^"]+)" should have YAML defer reason with value "(?P<value>[^"]+)"')
def step_ticket_has_yaml_defer_reason(context, ticket_id, value):
    """Assert defer_reason is valid single-quoted YAML with an exact value."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    raw = frontmatter_field_value(ticket_path.read_text(), 'defer_reason')
    assert decode_yaml_single_quoted_scalar(raw) == value


@then(r'ticket "(?P<ticket_id>[^"]+)" should store the punctuation regression reason as valid YAML')
def step_ticket_has_punctuation_yaml_reason(context, ticket_id):
    """Assert punctuation round-trips through the stored YAML scalar."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    raw = frontmatter_field_value(ticket_path.read_text(), 'defer_reason')
    assert decode_yaml_single_quoted_scalar(raw) == PUNCTUATION_REASON


@then(r'ticket "(?P<ticket_id>[^"]+)" should have field "(?P<field>[^"]+)" with value "(?P<value>[^"]+)"')
def step_ticket_has_field_value(context, ticket_id, field, value):
    """Assert ticket has a field with specific value."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    pattern = rf'^{re.escape(field)}:\s*(.+)$'
    match = re.search(pattern, content, re.MULTILINE)
    assert match, f"Field '{field}' not found in ticket\nContent: {content}"
    actual = match.group(1).strip()
    assert actual == value, f"Field '{field}' has value '{actual}', expected '{value}'"


@then(r'ticket "(?P<ticket_id>[^"]+)" should have "(?P<dep_id>[^"]+)" in deps')
def step_ticket_has_dep(context, ticket_id, dep_id):
    """Assert ticket has a dependency."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    deps_match = re.search(r'^deps:\s*\[([^\]]*)\]', content, re.MULTILINE)
    assert deps_match, f"deps field not found\nContent: {content}"
    deps = deps_match.group(1)
    assert dep_id in deps, f"Dependency '{dep_id}' not in deps: [{deps}]"


@then(r'ticket "(?P<ticket_id>[^"]+)" should not have "(?P<dep_id>[^"]+)" in deps')
def step_ticket_not_has_dep(context, ticket_id, dep_id):
    """Assert ticket does not have a dependency."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    deps_match = re.search(r'^deps:\s*\[([^\]]*)\]', content, re.MULTILINE)
    assert deps_match, f"deps field not found\nContent: {content}"
    deps = deps_match.group(1)
    assert dep_id not in deps, f"Dependency '{dep_id}' should not be in deps: [{deps}]"


@then(r'ticket "(?P<ticket_id>[^"]+)" should have "(?P<link_id>[^"]+)" in links')
def step_ticket_has_link(context, ticket_id, link_id):
    """Assert ticket has a link."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    links_match = re.search(r'^links:\s*\[([^\]]*)\]', content, re.MULTILINE)
    assert links_match, f"links field not found\nContent: {content}"
    links = links_match.group(1)
    assert link_id in links, f"Link '{link_id}' not in links: [{links}]"


@then(r'ticket "(?P<ticket_id>[^"]+)" should not have "(?P<link_id>[^"]+)" in links')
def step_ticket_not_has_link(context, ticket_id, link_id):
    """Assert ticket does not have a link."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    links_match = re.search(r'^links:\s*\[([^\]]*)\]', content, re.MULTILINE)
    assert links_match, f"links field not found\nContent: {content}"
    links = links_match.group(1)
    assert link_id not in links, f"Link '{link_id}' should not be in links: [{links}]"


@then(r'ticket "(?P<ticket_id>[^"]+)" should contain "(?P<text>[^"]+)"')
def step_ticket_contains(context, ticket_id, text):
    """Assert ticket file contains text."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()
    assert text in content, f"Ticket does not contain '{text}'\nContent: {content}"


@then(r'ticket "(?P<ticket_id>[^"]+)" should contain a timestamp in notes')
def step_ticket_has_timestamp_in_notes(context, ticket_id):
    """Assert ticket has a timestamp in notes section."""
    ticket_path = Path(context.test_dir) / '.tickets' / f'{ticket_id}.md'
    content = ticket_path.read_text()

    pattern = r'\*\*\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\*\*'
    assert re.search(pattern, content), \
        f"No timestamp found in notes\nContent: {content}"


@then(r'the output line (?P<line_num>\d+) should contain "(?P<text>[^"]+)"')
def step_output_line_contains(context, line_num, text):
    """Assert specific line of output contains text."""
    line_num = int(line_num)
    lines = context.stdout.split('\n')
    assert len(lines) >= line_num, \
        f"Output has only {len(lines)} lines, expected at least {line_num}"
    line = lines[line_num - 1]
    assert text in line, f"Line {line_num} does not contain '{text}'\nLine: {line}"


@then(r'the output line count should be (?P<count>\d+)')
def step_output_line_count(context, count):
    """Assert output has specific number of lines."""
    count = int(count)
    lines = [l for l in context.stdout.split('\n') if l.strip()]
    assert len(lines) == count, \
        f"Expected {count} lines but got {len(lines)}\nOutput: {context.stdout}"


@then(r'the output should be valid JSONL')
def step_output_valid_jsonl(context):
    """Assert output is valid JSON Lines format."""
    lines = context.stdout.strip().split('\n')
    for line in lines:
        if line.strip():
            try:
                json.loads(line)
            except json.JSONDecodeError as e:
                raise AssertionError(f"Invalid JSONL line: {line}\nError: {e}")


@then(r'the JSONL output should have field "(?P<field>[^"]+)"')
def step_jsonl_has_field(context, field):
    """Assert JSONL output has a specific field."""
    lines = context.stdout.strip().split('\n')
    assert lines, "No JSONL output"

    for line in lines:
        if line.strip():
            data = json.loads(line)
            assert field in data, f"Field '{field}' not found in JSONL\nData: {data}"
            break


@then(r'the JSONL output should have field "(?P<field>[^"]+)" with value "(?P<value>[^"]+)"')
def step_jsonl_has_field_value(context, field, value):
    """Assert the first JSONL object has a field with a string value."""
    lines = [line for line in context.stdout.splitlines() if line.strip()]
    assert lines, "No JSONL output"
    data = json.loads(lines[0])
    assert data.get(field) == value, \
        f"Field '{field}' has value {data.get(field)!r}, expected {value!r}"


@then(r'the JSONL output should not have field "(?P<field>[^"]+)"')
def step_jsonl_does_not_have_field(context, field):
    """Assert the first JSONL object does not have a field."""
    lines = [line for line in context.stdout.splitlines() if line.strip()]
    assert lines, "No JSONL output"
    data = json.loads(lines[0])
    assert field not in data, f"Field '{field}' unexpectedly found in JSONL"


@then(r'the JSONL defer reason should equal the punctuation regression reason')
def step_jsonl_has_punctuation_reason(context):
    """Assert query returns the decoded punctuation reason exactly."""
    lines = [line for line in context.stdout.splitlines() if line.strip()]
    assert lines, "No JSONL output"
    data = json.loads(lines[0])
    assert data.get('defer_reason') == PUNCTUATION_REASON


@then(r'the JSONL output should preserve the query escaping fixture fields')
def step_jsonl_preserves_query_escaping_fields(context):
    """Assert JSON-sensitive fixture keys and values round-trip exactly."""
    lines = [line for line in context.stdout.splitlines() if line.strip()]
    assert lines, "No JSONL output"
    data = json.loads(lines[0])
    assert data.get('special"key') == QUERY_ESCAPE_SCALAR
    assert data.get('special_list') == QUERY_ESCAPE_ARRAY


@then(r'the JSONL deps field should be a JSON array')
def step_jsonl_deps_is_array(context):
    """Assert deps field in JSONL is an array."""
    lines = context.stdout.strip().split('\n')
    assert lines, "No JSONL output"

    for line in lines:
        if line.strip():
            data = json.loads(line)
            if 'deps' in data:
                assert isinstance(data['deps'], list), \
                    f"deps field is not an array: {type(data['deps'])}"
                return
    raise AssertionError("No JSONL line with deps field found")


@then(r'the dep tree output should have (?P<first_id>[^\s]+) before (?P<second_id>[^\s]+)')
def step_dep_tree_order(context, first_id, second_id):
    """Assert that first_id appears before second_id in dep tree output."""
    output = context.stdout
    lines = output.split('\n')

    first_line = -1
    second_line = -1

    for i, line in enumerate(lines):
        if first_id in line:
            first_line = i
        if second_id in line:
            second_line = i

    assert first_line != -1, f"'{first_id}' not found in output:\n{output}"
    assert second_line != -1, f"'{second_id}' not found in output:\n{output}"
    assert first_line < second_line, \
        f"Expected '{first_id}' (line {first_line + 1}) before '{second_id}' (line {second_line + 1})\nOutput:\n{output}"


# ============================================================================
# Plugin Steps
# ============================================================================

def create_plugin(context, name, content):
    """Helper to create a plugin script in a temporary bin directory."""
    if not hasattr(context, 'plugin_dir'):
        context.plugin_dir = tempfile.mkdtemp(prefix='ticket_plugins_')

    plugin_path = Path(context.plugin_dir) / name
    plugin_path.write_text(content)
    plugin_path.chmod(0o755)
    return plugin_path


def run_with_plugin_path(context, command):
    """Run a command with the plugin directory in PATH."""
    command = command.replace('\\"', '"')
    ticket_script = get_ticket_script(context)
    cmd = command.replace('ticket ', f'{ticket_script} ', 1)

    cwd = getattr(context, 'working_dir', context.test_dir)

    env = os.environ.copy()
    if hasattr(context, 'plugin_dir'):
        env['PATH'] = context.plugin_dir + ':' + env.get('PATH', '')

    result = subprocess.run(
        cmd,
        shell=True,
        cwd=cwd,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=env
    )

    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode
    context.last_command = command

    if 'ticket create' in command and result.returncode == 0:
        context.last_created_id = result.stdout.strip()


@given(r'a plugin "(?P<name>[^"]+)" that outputs "(?P<output>[^"]+)"')
def step_plugin_outputs(context, name, output):
    """Create a plugin that outputs a fixed string."""
    content = f'''#!/usr/bin/env bash
# tk-plugin: Test plugin
echo "{output}"
'''
    create_plugin(context, name, content)


@given(r'a plugin "(?P<name>[^"]+)" that outputs its arguments')
def step_plugin_echo_args(context, name):
    """Create a plugin that echoes its arguments."""
    content = '''#!/usr/bin/env bash
# tk-plugin: Echo arguments
echo "$@"
'''
    create_plugin(context, name, content)


@given(r'a plugin "(?P<name>[^"]+)" that outputs TICKETS_DIR')
def step_plugin_outputs_tickets_dir(context, name):
    """Create a plugin that outputs the TICKETS_DIR env var."""
    content = '''#!/usr/bin/env bash
# tk-plugin: Output TICKETS_DIR
echo "$TICKETS_DIR"
'''
    create_plugin(context, name, content)


@given(r'a plugin "(?P<name>[^"]+)" that outputs TK_SCRIPT')
def step_plugin_outputs_tk_script(context, name):
    """Create a plugin that outputs the TK_SCRIPT env var."""
    content = '''#!/usr/bin/env bash
# tk-plugin: Output TK_SCRIPT
echo "$TK_SCRIPT"
'''
    create_plugin(context, name, content)


@given(r'a plugin "(?P<name>[^"]+)" with description "(?P<desc>[^"]+)"')
def step_plugin_with_description(context, name, desc):
    """Create a plugin with a specific description."""
    content = f'''#!/usr/bin/env bash
# tk-plugin: {desc}
echo "plugin executed"
'''
    create_plugin(context, name, content)


@given(r'a plugin "(?P<name>[^"]+)" that outputs "(?P<output>[^"]+)" without metadata')
def step_plugin_no_metadata(context, name, output):
    """Create a plugin without tk-plugin metadata comment."""
    content = f'''#!/usr/bin/env bash
echo "{output}"
'''
    create_plugin(context, name, content)


@given(r'a plugin "(?P<name>[^"]+)" that calls super create')
def step_plugin_calls_super(context, name):
    """Create a plugin that calls the built-in create via super."""
    content = '''#!/usr/bin/env bash
# tk-plugin: Wrapper that calls super
exec "$TK_SCRIPT" super create "$@"
'''
    create_plugin(context, name, content)


# Override the run step for plugin scenarios to include plugin PATH
@when(r'I run "(?P<command>(?:[^"\\]|\\.)+)" with plugins')
def step_run_with_plugins(context, command):
    """Run a command with plugins in PATH."""
    run_with_plugin_path(context, command)


# ============================================================================
# Local Installer Steps
# ============================================================================

INSTALL_LINKS = {
    'tk': 'ticket',
    'ticket-edit': 'plugins/ticket-edit',
    'ticket-ls': 'plugins/ticket-ls',
    'ticket-list': 'plugins/ticket-list',
    'ticket-query': 'plugins/ticket-query',
    'ticket-migrate-beads': 'plugins/ticket-migrate-beads',
}


def run_local_installer(context, action):
    """Run the checkout-local installer against the scenario prefix."""
    installer = context.local_checkout / 'scripts' / 'install-local.sh'
    env = os.environ.copy()
    env['PREFIX'] = str(context.local_prefix)
    result = subprocess.run(
        [str(installer), action],
        cwd=context.local_checkout,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=env,
    )
    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode
    return result


def installed_entry_snapshot(entry):
    """Describe a prefix entry without following symlinks."""
    if entry.is_symlink():
        return ('link', os.readlink(entry))
    if entry.is_dir():
        return ('directory',)
    if entry.is_file():
        return ('file', entry.read_bytes())
    return ('missing',)


@given(r'a temporary local checkout and user prefix')
def step_temporary_local_checkout(context):
    """Copy only local-install runtime files into a writable checkout fixture."""
    source = Path(context.project_dir)
    test_root = Path(context.test_dir).resolve()
    checkout = test_root / 'checkout'
    checkout.mkdir()
    shutil.copy2(source / 'ticket', checkout / 'ticket')
    shutil.copytree(source / 'plugins', checkout / 'plugins', symlinks=True)
    (checkout / 'pkg').mkdir()
    shutil.copy2(source / 'pkg' / 'extras.txt', checkout / 'pkg' / 'extras.txt')
    (checkout / 'scripts').mkdir()
    shutil.copy2(
        source / 'scripts' / 'install-local.sh',
        checkout / 'scripts' / 'install-local.sh',
    )

    context.local_checkout = checkout
    context.local_prefix = test_root / 'prefix'


@given(r'a stub editor for installed commands')
def step_stub_editor(context):
    """Configure an editor that records any unexpected invocation."""
    marker = Path(context.test_dir) / 'editor-invoked'
    editor = Path(context.test_dir) / 'stub-editor'
    editor.write_text(
        '#!/usr/bin/env bash\n'
        'printf invoked > "$STUB_EDITOR_MARKER"\n'
    )
    editor.chmod(0o755)
    context.stub_editor = editor
    context.stub_editor_marker = marker


@when(r'I install the local checkout')
def step_install_local_checkout(context):
    run_local_installer(context, 'install')


@when(r'I install the local checkout through a relative path with CDPATH set')
def step_install_local_checkout_with_cdpath(context):
    """Run the relative installer path with a CDPATH entry that emits cd output."""
    env = os.environ.copy()
    env['PREFIX'] = str(context.local_prefix)
    env['CDPATH'] = '.:' + str(Path(context.test_dir) / 'cdpath-fallback')
    result = subprocess.run(
        ['scripts/install-local.sh', 'install'],
        cwd=context.local_checkout,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=env,
    )
    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode


@when(r'I uninstall the local checkout')
def step_uninstall_local_checkout(context):
    run_local_installer(context, 'uninstall')


@given(r'the local checkout is installed')
def step_local_checkout_installed(context):
    result = run_local_installer(context, 'install')
    assert result.returncode == 0, \
        f"Install failed\nstdout: {result.stdout}\nstderr: {result.stderr}"


@when(r'I run installed "(?P<command>[^"]+)"')
def step_run_installed(context, command):
    """Run only the explicitly installed temporary-prefix tk link."""
    env = os.environ.copy()
    env['PATH'] = str(context.local_prefix / 'bin') + ':' + env.get('PATH', '')
    if hasattr(context, 'stub_editor'):
        env['EDITOR'] = str(context.stub_editor)
        env['STUB_EDITOR_MARKER'] = str(context.stub_editor_marker)

    result = subprocess.run(
        [str(context.local_prefix / 'bin' / 'tk'), *shlex.split(command)],
        cwd=context.test_dir,
        capture_output=True,
        text=True,
        stdin=subprocess.DEVNULL,
        env=env,
    )
    context.result = result
    context.stdout = result.stdout.strip()
    context.stderr = result.stderr.strip()
    context.returncode = result.returncode


@then(r'the local prefix should contain checkout links:')
def step_prefix_contains_checkout_links(context):
    expected_names = context.text.splitlines()
    assert expected_names == list(INSTALL_LINKS), \
        f"Scenario link list does not match installer contract: {expected_names}"
    for name, relative_target in INSTALL_LINKS.items():
        entry = context.local_prefix / 'bin' / name
        expected = context.local_checkout / relative_target
        assert entry.is_symlink(), f"Expected symlink: {entry}"
        assert os.readlink(entry) == str(expected), \
            f"Expected {entry} -> {expected}, got {os.readlink(entry)}"


@then(r'the stub editor should not have been invoked')
def step_stub_editor_not_invoked(context):
    assert not context.stub_editor_marker.exists(), \
        f"Noninteractive edit invoked editor: {context.stub_editor_marker}"


@given(r'prefix entry "(?P<name>[^"]+)" is a (?P<kind>regular file|directory|broken link|foreign link)')
def step_conflicting_prefix_entry(context, name, kind):
    bin_dir = context.local_prefix / 'bin'
    bin_dir.mkdir(parents=True)
    entry = bin_dir / name

    if kind == 'regular file':
        entry.write_text('unrelated command\n')
    elif kind == 'directory':
        entry.mkdir()
    elif kind == 'broken link':
        entry.symlink_to(Path(context.test_dir) / 'missing-command')
    else:
        foreign = Path(context.test_dir) / 'foreign-command'
        foreign.write_text('foreign command\n')
        entry.symlink_to(foreign)

    context.conflicting_entry = entry
    context.conflicting_entry_snapshot = installed_entry_snapshot(entry)


@then(r'prefix entry "(?P<name>[^"]+)" should be unchanged')
def step_prefix_entry_unchanged(context, name):
    entry = context.local_prefix / 'bin' / name
    assert entry == context.conflicting_entry
    assert installed_entry_snapshot(entry) == context.conflicting_entry_snapshot


@then(r'no checkout links should have been installed')
def step_no_checkout_links_installed(context):
    for name in INSTALL_LINKS:
        entry = context.local_prefix / 'bin' / name
        if entry == context.conflicting_entry:
            continue
        assert not entry.exists() and not entry.is_symlink(), \
            f"Unexpected partial installation: {entry}"


@when(r'the checkout core is changed to output "(?P<output>[^"]+)"')
def step_change_checkout_core(context, output):
    core = context.local_checkout / 'ticket'
    core.write_text(f'#!/usr/bin/env bash\nprintf "%s\\n" "{output}"\n')
    core.chmod(0o755)


@given(r'unrelated prefix entry "(?P<name>[^"]+)" contains "(?P<content>[^"]+)"')
def step_unrelated_prefix_entry(context, name, content):
    entry = context.local_prefix / 'bin' / name
    entry.write_text(content)
    context.unrelated_entry = entry


@given(r'installed entry "(?P<name>[^"]+)" is retargeted outside the checkout')
def step_retarget_installed_entry(context, name):
    foreign = Path(context.test_dir) / f'foreign-{name}'
    foreign.write_text('foreign target\n')
    entry = context.local_prefix / 'bin' / name
    entry.unlink()
    entry.symlink_to(foreign)
    context.retargeted_entry = entry
    context.retargeted_entry_snapshot = installed_entry_snapshot(entry)


@then(r'owned checkout links should be absent')
def step_owned_checkout_links_absent(context):
    for name in INSTALL_LINKS:
        entry = context.local_prefix / 'bin' / name
        if hasattr(context, 'retargeted_entry') and entry == context.retargeted_entry:
            continue
        assert not entry.exists() and not entry.is_symlink(), \
            f"Checkout-owned link remains: {entry}"


@then(r'unrelated prefix entry "(?P<name>[^"]+)" should contain "(?P<content>[^"]+)"')
def step_unrelated_prefix_entry_preserved(context, name, content):
    entry = context.local_prefix / 'bin' / name
    assert entry.read_text() == content


@then(r'retargeted installed entry "(?P<name>[^"]+)" should be unchanged')
def step_retargeted_entry_unchanged(context, name):
    entry = context.local_prefix / 'bin' / name
    assert entry == context.retargeted_entry
    assert installed_entry_snapshot(entry) == context.retargeted_entry_snapshot
