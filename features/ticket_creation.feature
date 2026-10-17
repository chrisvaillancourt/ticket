Feature: Ticket Creation
  As a user
  I want to create tickets with various options
  So that I can track tasks in my project

  Background:
    Given a clean tickets directory

  Scenario: Create a basic ticket with title
    When I run "ticket create 'My first ticket'"
    Then the command should succeed
    And the output should match a ticket ID pattern
    And a ticket file should exist with title "My first ticket"

  Scenario: Create a ticket with default title
    When I run "ticket create"
    Then the command should succeed
    And the output should match a ticket ID pattern
    And a ticket file should exist with title "Untitled"

  Scenario: Create a ticket with description
    When I run "ticket create 'Test ticket' -d 'This is the description'"
    Then the command should succeed
    And the created ticket should contain "This is the description"

  Scenario: Create a ticket with type
    When I run "ticket create 'Bug ticket' -t bug"
    Then the command should succeed
    And the created ticket should have field "type" with value "bug"

  Scenario: Create a ticket with priority
    When I run "ticket create 'High priority' -p 0"
    Then the command should succeed
    And the created ticket should have field "priority" with value "0"

  Scenario: Create a ticket with assignee
    When I run "ticket create 'Assigned ticket' -a 'John Doe'"
    Then the command should succeed
    And the created ticket should have field "assignee" with value "John Doe"

  Scenario: Create a ticket with external reference
    When I run "ticket create 'External ticket' --external-ref 'JIRA-123'"
    Then the command should succeed
    And the created ticket should have field "external-ref" with value "JIRA-123"

  Scenario: Create a ticket with parent
    Given a ticket exists with ID "parent-001" and title "Parent ticket"
    When I run "ticket create 'Child ticket' --parent parent-001"
    Then the command should succeed
    And the created ticket should have field "parent" with value "parent-001"

  Scenario: Create a ticket with design notes
    When I run "ticket create 'Design ticket' --design 'Use microservices'"
    Then the command should succeed
    And the created ticket should contain "## Design"
    And the created ticket should contain "Use microservices"

  Scenario: Create a ticket with acceptance criteria
    When I run "ticket create 'Story ticket' --acceptance 'Should pass all tests'"
    Then the command should succeed
    And the created ticket should contain "## Acceptance Criteria"
    And the created ticket should contain "Should pass all tests"

  Scenario: Ticket has default status open
    When I run "ticket create 'New ticket'"
    Then the command should succeed
    And the created ticket should have field "status" with value "open"

  Scenario: Ticket has default priority 2
    When I run "ticket create 'Normal priority'"
    Then the command should succeed
    And the created ticket should have field "priority" with value "2"

  Scenario: Ticket has default type task
    When I run "ticket create 'Default type'"
    Then the command should succeed
    And the created ticket should have field "type" with value "task"

  Scenario: Ticket has empty deps by default
    When I run "ticket create 'No deps'"
    Then the command should succeed
    And the created ticket should have field "deps" with value "[]"

  Scenario: Ticket has empty links by default
    When I run "ticket create 'No links'"
    Then the command should succeed
    And the created ticket should have field "links" with value "[]"

  Scenario: Ticket has created timestamp
    When I run "ticket create 'Timestamped'"
    Then the command should succeed
    And the created ticket should have a valid created timestamp

  Scenario: Tickets directory created on demand
    Given the tickets directory does not exist
    When I run "ticket create 'First ticket'"
    Then the command should succeed
    And the tickets directory should exist

  Scenario Outline: Generated ticket files have normalized trailing whitespace
    When I run "ticket create 'Writer <case>' <options>"
    Then the command should succeed
    And the created ticket file should end with exactly one newline and have no trailing whitespace

    Examples:
      | case                   | options                                                    |
      | title only             |                                                            |
      | description            | -d $'Description text\n'                                   |
      | design                 | --design $'Design text\n'                                  |
      | acceptance             | --acceptance $'Acceptance text\n'                          |
      | description and design | -d 'Description text' --design $'Design text\n'            |
      | description and accept | -d 'Description text' --acceptance $'Acceptance text\n'    |
      | design and accept      | --design 'Design text' --acceptance $'Acceptance text\n'   |
      | all sections           | -d 'Description text' --design 'Design text' --acceptance $'Acceptance text\n' |

  Scenario: Create a ticket with description from a file
    Given a file "desc.md" containing:
      """
      Run `make test` with $HOME set.

      ```sh
      echo "it's fine"
      ```
      """
    When I run "ticket create 'From file' --description-file desc.md"
    Then the command should succeed
    And the created ticket body should be:
      """
      # From file

      Run `make test` with $HOME set.

      ```sh
      echo "it's fine"
      ```
      """

  Scenario: Create a ticket with design and acceptance from files
    Given a file "design.md" containing:
      """
      Use `$TICKETS_DIR`.
      """
    And a file "accept.md" containing:
      """
      - [ ] Handles "quotes"
      """
    When I run "ticket create 'Sections' --design-file design.md --acceptance-file accept.md"
    Then the command should succeed
    And the created ticket body should be:
      """
      # Sections

      ## Design

      Use `$TICKETS_DIR`.

      ## Acceptance Criteria

      - [ ] Handles "quotes"
      """

  Scenario: Create a ticket with description from stdin
    When I run "printf 'Line one\nLine `two`\n' | ticket create 'From stdin' --description-file -"
    Then the command should succeed
    And the created ticket body should be:
      """
      # From stdin

      Line one
      Line `two`
      """
    And the created ticket file should end with exactly one newline and have no trailing whitespace

  Scenario: Missing field file fails without creating anything
    Given the tickets directory does not exist
    When I run "ticket create 'Missing' --description-file nope.md"
    Then the command should fail
    And the output should contain "Error: cannot read description file 'nope.md'"
    And the tickets directory should not exist

  Scenario: Inline and file forms of one field conflict
    Given the tickets directory does not exist
    And a file "desc.md" containing:
      """
      From file
      """
    When I run "ticket create 'Both' -d 'Inline' --description-file desc.md"
    Then the command should fail
    And the output should contain "Error: use either --description or --description-file, not both"
    And the tickets directory should not exist

  Scenario: Only one field can read stdin
    Given the tickets directory does not exist
    When I run "printf 'x' | ticket create 'Two' --description-file - --design-file -"
    Then the command should fail
    And the output should contain "Error: only one field can read from stdin"
    And the tickets directory should not exist

  Scenario: Dry run prints the ticket without writing it
    Given the tickets directory does not exist
    When I run "ticket create 'Preview' -t bug --tags api,cli -d 'Body text' --dry-run"
    Then the command should succeed
    And the output should match pattern "^---\nid: [a-z0-9]+-[a-z0-9]{4}\nstatus: open\n"
    And the output should contain "type: bug"
    And the output should contain "tags: [api, cli]"
    And the output should match pattern "\n---\n# Preview\n\nBody text$"
    And the raw output should end with exactly one newline
    And the tickets directory should not exist

  Scenario: Dry run writes no ticket into an existing directory
    When I run "ticket create 'Preview' --dry-run"
    Then the command should succeed
    And no ticket files should exist

  Scenario: Dry run still validates the parent
    When I run "ticket create 'Child' --parent nope --dry-run"
    Then the command should fail
    And the output should contain "Error: ticket 'nope' not found"
    And no ticket files should exist

  Scenario: Field files can be non-regular readable paths
    When I run "printf 'Via dev stdin\n' | ticket create 'Dev stdin' --description-file /dev/stdin"
    Then the command should succeed
    And the created ticket body should be:
      """
      # Dev stdin

      Via dev stdin
      """

  Scenario: Field file option requires a path
    Given the tickets directory does not exist
    When I run "ticket create 'No path' --description-file"
    Then the command should fail
    And the output should contain "Error: --description-file requires a path"
    And the tickets directory should not exist

  Scenario: Option values that look like help flags are data
    When I run "ticket create 'Literal' -d --help"
    Then the command should succeed
    And the created ticket body should be:
      """
      # Literal

      --help
      """

  Scenario: Dry run output appends to redirected output
    When I run "printf 'header\n' > out.txt && ticket create 'Preview' --dry-run >> out.txt"
    Then the command should succeed
    And the file "out.txt" should start with "header\n---\nid: "
