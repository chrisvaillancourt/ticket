Feature: Plugin System
  As a user
  I want to extend tk with custom commands
  So that I can add domain-specific functionality

  Scenario: Plugin in PATH is executed for unknown command
    Given a plugin "tk-hello" that outputs "Hello from plugin!"
    When I run "ticket hello"
    Then the command should succeed
    And the output should be "Hello from plugin!"

  Scenario: Plugin receives command arguments
    Given a plugin "tk-echo" that outputs its arguments
    When I run "ticket echo foo bar baz"
    Then the command should succeed
    And the output should be "foo bar baz"

  Scenario: ticket- prefix plugins are also discovered
    Given a plugin "ticket-greet" that outputs "Greetings!"
    When I run "ticket greet"
    Then the command should succeed
    And the output should be "Greetings!"

  Scenario: tk- prefix takes precedence over ticket- prefix
    Given a plugin "tk-test" that outputs "tk-prefix"
    And a plugin "ticket-test" that outputs "ticket-prefix"
    When I run "ticket test"
    Then the command should succeed
    And the output should be "tk-prefix"

  Scenario: Super command bypasses plugins
    Given a clean tickets directory
    And a plugin "tk-create" that outputs "plugin create"
    When I run "ticket super create \"Test ticket\""
    Then the command should succeed
    And the output should match a ticket ID pattern

  Scenario: Plugin receives TICKETS_DIR environment variable
    Given a clean tickets directory
    And a plugin "tk-checkenv" that outputs TICKETS_DIR
    When I run "ticket checkenv"
    Then the command should succeed
    And the output should contain ".tickets"

  Scenario: Plugin receives TK_SCRIPT environment variable
    Given a plugin "tk-checkscript" that outputs TK_SCRIPT
    When I run "ticket checkscript"
    Then the command should succeed
    And the output should contain "ticket"

  Scenario: Help command lists installed plugins
    Given a plugin "tk-myplugin" with description "My custom plugin"
    When I run "ticket help"
    Then the command should succeed
    And the output should contain "myplugin"
    And the output should contain "My custom plugin"

  Scenario: Help shows plugins without description as no description
    Given a plugin "tk-nodesc" that outputs "test" without metadata
    When I run "ticket help"
    Then the command should succeed
    And the output should contain "nodesc"
    And the output should contain "(no description)"

  Scenario: Plugin can call built-in commands via super
    Given a clean tickets directory
    And a plugin "tk-wrapper" that calls super create
    When I run "ticket wrapper \"Wrapped ticket\""
    Then the command should succeed
    And the output should match a ticket ID pattern

  Scenario: Symlink plugin alias works for list command
    Given a clean tickets directory
    And a ticket exists with ID "sym-0001" and title "Symlink test ticket"
    When I run "ticket list"
    Then the command should succeed
    And the output should contain "sym-0001"
    And the output should contain "Symlink test ticket"

  Scenario: Built-in commands still work with plugins present
    Given a clean tickets directory
    And a plugin "tk-hello" that outputs "Hello!"
    When I run "ticket create \"Normal ticket\""
    Then the command should succeed
    And the output should match a ticket ID pattern

  Scenario: Migrate a minimal Beads record
    Given a clean tickets directory
    And a Beads issues file containing:
      """
      {"id":"beads-min","title":"Minimal","created_at":"2026-07-16T10:00:00Z"}
      """
    When I run "ticket migrate-beads"
    Then the command should succeed
    And ticket "beads-min" should have field "created" with value "2026-07-16T10:00:00Z"
    And ticket "beads-min" should end with exactly one newline and have no trailing whitespace

  Scenario: Migrate a fully populated Beads record
    Given a clean tickets directory
    And a Beads issues file containing:
      """
      {"id":"beads-full","title":"Full record","status":"in_progress","created_at":"2026-07-16T11:00:00Z","issue_type":"feature","priority":1,"assignee":"Ada","external_ref":"gh-123","description":"Description text","design":"Design text","acceptance_criteria":"Acceptance text","notes":"Notes text\n","dependencies":[{"type":"blocks","depends_on_id":"beads-dep"},{"type":"related","depends_on_id":"beads-link"},{"type":"parent-child","depends_on_id":"beads-parent"}]}
      {"id":"beads-companion","title":"Companion","created_at":"2026-07-16T12:00:00Z"}
      """
    When I run "ticket migrate-beads"
    Then the command should succeed
    And ticket "beads-full" should have field "status" with value "in_progress"
    And ticket "beads-full" should have field "parent" with value "beads-parent"
    And ticket "beads-full" should contain "## Design"
    And ticket "beads-full" should contain "## Acceptance Criteria"
    And ticket "beads-full" should contain "## Notes"
    And ticket "beads-full" should end with exactly one newline and have no trailing whitespace
    And ticket "beads-companion" should end with exactly one newline and have no trailing whitespace

  Scenario: Migrate a Beads record without a creation timestamp
    Given a clean tickets directory
    And a Beads issues file containing:
      """
      {"id":"beads-no-created","title":"No timestamp","description":"Body"}
      """
    When I run "ticket migrate-beads"
    Then the command should succeed
    And ticket "beads-no-created" should not have field "created"
    And ticket "beads-no-created" should end with exactly one newline and have no trailing whitespace
