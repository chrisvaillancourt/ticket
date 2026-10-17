Feature: Ticket Listing
  As a user
  I want to list tickets in various ways
  So that I can see what work needs to be done

  Background:
    Given a clean tickets directory

  Scenario: List all tickets
    Given a ticket exists with ID "list-0001" and title "First ticket"
    And a ticket exists with ID "list-0002" and title "Second ticket"
    When I run "ticket ls"
    Then the command should succeed
    And the output should contain "list-0001"
    And the output should contain "list-0002"

  Scenario: List command alias works
    Given a ticket exists with ID "list-0001" and title "First ticket"
    When I run "ticket list"
    Then the command should succeed
    And the output should contain "list-0001"

  Scenario: List shows ticket format correctly
    Given a ticket exists with ID "list-0001" and title "My ticket"
    When I run "ticket ls"
    Then the command should succeed
    And the output should match pattern "list-0001\s+\[open\]\s+-\s+My ticket"

  Scenario: List with status filter
    Given a ticket exists with ID "list-0001" and title "Open ticket"
    And a ticket exists with ID "list-0002" and title "Closed ticket"
    And ticket "list-0002" has status "closed"
    When I run "ticket ls --status=open"
    Then the command should succeed
    And the output should contain "list-0001"
    And the output should not contain "list-0002"

  Scenario: List shows dependencies
    Given a ticket exists with ID "list-0001" and title "Main ticket"
    And a ticket exists with ID "list-0002" and title "Dep ticket"
    And ticket "list-0001" depends on "list-0002"
    When I run "ticket ls"
    Then the command should succeed
    And the output should contain "<- [list-0002]"

  Scenario: List with no tickets returns nothing
    When I run "ticket ls"
    Then the output should be empty

  Scenario: Ready shows tickets with no deps and with closed deps
    Given a ticket exists with ID "ready-001" and title "Ready ticket"
    And a ticket exists with ID "ready-002" and title "Unblocked ticket"
    And a ticket exists with ID "ready-003" and title "Dependency"
    And ticket "ready-002" depends on "ready-003"
    And ticket "ready-003" has status "closed"
    When I run "ticket ready"
    Then the command should succeed
    And the output should contain "ready-001"
    And the output should contain "ready-002"

  Scenario: Ready excludes tickets with unclosed deps
    Given a ticket exists with ID "ready-001" and title "Blocked ticket"
    And a ticket exists with ID "ready-002" and title "Open dependency"
    And ticket "ready-001" depends on "ready-002"
    When I run "ticket ready"
    Then the command should succeed
    And the output should not contain "ready-001"
    And the output should contain "ready-002"

  Scenario: Ready shows tickets when deps are closed
    Given a ticket exists with ID "ready-001" and title "Main ticket"
    And a ticket exists with ID "ready-002" and title "Closed dependency"
    And ticket "ready-001" depends on "ready-002"
    And ticket "ready-002" has status "closed"
    When I run "ticket ready"
    Then the command should succeed
    And the output should contain "ready-001"

  Scenario: Ready excludes closed tickets
    Given a ticket exists with ID "ready-001" and title "Closed ticket"
    And ticket "ready-001" has status "closed"
    When I run "ticket ready"
    Then the command should succeed
    And the output should not contain "ready-001"

  Scenario: Ready shows priority in output
    Given a ticket exists with ID "ready-001" and title "Priority ticket"
    When I run "ticket ready"
    Then the command should succeed
    And the output should match pattern "ready-001\s+\[P2\]\[open\]\s+-\s+Priority ticket"

  Scenario: Ready sorts by priority then ID
    Given a ticket exists with ID "ready-003" and title "Low priority" with priority 3
    And a ticket exists with ID "ready-001" and title "High priority" with priority 1
    And a ticket exists with ID "ready-002" and title "Also high priority" with priority 1
    When I run "ticket ready"
    Then the command should succeed
    And the output line 1 should contain "ready-001"
    And the output line 2 should contain "ready-002"
    And the output line 3 should contain "ready-003"

  Scenario: Blocked shows tickets with unclosed deps
    Given a ticket exists with ID "block-001" and title "Blocked ticket"
    And a ticket exists with ID "block-002" and title "Blocker ticket"
    And ticket "block-001" depends on "block-002"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should contain "block-001"
    And the output should contain "<- [block-002]"

  Scenario: Blocked excludes tickets with all deps closed
    Given a ticket exists with ID "block-001" and title "Unblocked ticket"
    And a ticket exists with ID "block-002" and title "Closed blocker"
    And ticket "block-001" depends on "block-002"
    And ticket "block-002" has status "closed"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should not contain "block-001"

  Scenario: Blocked excludes closed tickets
    Given a ticket exists with ID "block-001" and title "Closed blocked"
    And a ticket exists with ID "block-002" and title "Blocker"
    And ticket "block-001" depends on "block-002"
    And ticket "block-001" has status "closed"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should not contain "block-001"

  Scenario: Blocked shows only unclosed blockers
    Given a ticket exists with ID "block-001" and title "Blocked ticket"
    And a ticket exists with ID "block-002" and title "Open blocker"
    And a ticket exists with ID "block-003" and title "Closed blocker"
    And ticket "block-001" depends on "block-002"
    And ticket "block-001" depends on "block-003"
    And ticket "block-003" has status "closed"
    When I run "ticket blocked"
    Then the command should succeed
    And the output should contain "<- [block-002]"
    And the output should not contain "block-003"

  Scenario: Closed shows recently closed tickets
    Given a ticket exists with ID "done-0001" and title "Done ticket"
    And ticket "done-0001" has status "closed"
    When I run "ticket closed"
    Then the command should succeed
    And the output should contain "done-0001"
    And the output should contain "[closed]"
    And the output should contain "Done ticket"

  Scenario: Closed respects limit
    Given a ticket exists with ID "done-0001" and title "First done"
    And a ticket exists with ID "done-0002" and title "Second done"
    And ticket "done-0001" has status "closed"
    And ticket "done-0002" has status "closed"
    When I run "ticket closed --limit=1"
    Then the command should succeed
    And the output line count should be 1

  Scenario Outline: Closed rejects an invalid limit
    Given a ticket exists with ID "done-0001" and title "Done ticket"
    And ticket "done-0001" has status "closed"
    When I run "ticket closed --limit=<limit>"
    Then the command should fail
    And the output should contain "Error: --limit must be a whole number"
    And the output should not contain "done-0001"

    Examples:
      | limit   |
      | garbage |
      | -1      |
      | 5x      |
      |         |

  Scenario: Closed works when the tickets path contains a space
    Given a separate tickets directory exists at "with space/.tickets" with ticket "done-0001" titled "Done ticket"
    When I run "ticket close done-0001" with TICKETS_DIR set to "with space/.tickets"
    And I run "ticket closed" with TICKETS_DIR set to "with space/.tickets"
    Then the command should succeed
    And the output should contain "done-0001"

  Scenario: Closed with a zero limit prints nothing
    Given a ticket exists with ID "done-0001" and title "Done ticket"
    And ticket "done-0001" has status "closed"
    When I run "ticket closed --limit=0"
    Then the command should succeed
    And the output should be empty

  Scenario Outline: Listing commands with no tickets succeed and print nothing
    When I run "ticket <command>"
    Then the command should succeed
    And the output should be empty

    Examples:
      | command  |
      | closed   |
      | ready    |
      | blocked  |
      | deferred |
      | ls       |

  Scenario: Dependency cycle check with no tickets finds none
    When I run "ticket dep cycle"
    Then the command should succeed
    And the output should be "No dependency cycles found"

  Scenario: Listing commands find tickets under a directory name with brackets
    Given a separate tickets directory exists at "project[1]/.tickets" with ticket "br-0001" titled "First"
    And a separate tickets directory exists at "project[1]/.tickets" with ticket "br-0002" titled "Second"
    When I run "ticket dep br-0001 br-0002" with TICKETS_DIR set to "project[1]/.tickets"
    And I run "ticket dep br-0002 br-0001" with TICKETS_DIR set to "project[1]/.tickets"
    And I run "ticket blocked" with TICKETS_DIR set to "project[1]/.tickets"
    Then the output should contain "br-0001"
    When I run "ticket dep cycle" with TICKETS_DIR set to "project[1]/.tickets"
    Then the output should contain "Cycle 1"
    When I run "ticket dep tree br-0001" with TICKETS_DIR set to "project[1]/.tickets"
    Then the command should succeed
    And the output should contain "br-0002"
    When I run "ticket defer br-0001" with TICKETS_DIR set to "project[1]/.tickets"
    And I run "ticket deferred" with TICKETS_DIR set to "project[1]/.tickets"
    Then the output should contain "br-0001"
    When I run "ticket close br-0002" with TICKETS_DIR set to "project[1]/.tickets"
    And I run "ticket closed" with TICKETS_DIR set to "project[1]/.tickets"
    Then the output should contain "br-0002"
    When I run "ticket undefer br-0001" with TICKETS_DIR set to "project[1]/.tickets"
    And I run "ticket ready" with TICKETS_DIR set to "project[1]/.tickets"
    Then the output should contain "br-0001"

  Scenario: Closed accepts a space-separated limit
    Given a ticket exists with ID "done-0001" and title "First done"
    And a ticket exists with ID "done-0002" and title "Second done"
    And ticket "done-0001" has status "closed"
    And ticket "done-0002" has status "closed"
    When I run "ticket closed --limit 1"
    Then the command should succeed
    And the output line count should be 1

  Scenario: Closed can return more than 100 tickets
    Given 150 closed tickets with long IDs exist
    When I run "ticket closed --limit=120"
    Then the command should succeed
    And the output line count should be 120

  Scenario: Closed reports a failed file listing
    Given a ticket exists with ID "done-0001" and title "Done ticket"
    And ticket "done-0001" has status "closed"
    And an "ls" command on PATH that fails
    When I run "ticket closed"
    Then the command should fail
    And the output should contain "Argument list too long"
    And the output should contain "Error: could not list tickets"

  Scenario Outline: Listing options without a value fail clearly
    When I run "ticket <command> <option>"
    Then the command should fail
    And the output should contain "Error: <option> requires a value"
    And the output should not contain "unbound variable"

    Examples:
      | command | option  |
      | closed  | --limit |
      | closed  | -a      |
      | closed  | -T      |
      | ready   | -a      |
      | ready   | -T      |
      | blocked | -a      |
      | blocked | -T      |
      | ls      | -a      |
      | ls      | -T      |

  Scenario: Closed excludes open tickets
    Given a ticket exists with ID "done-0001" and title "Open ticket"
    When I run "ticket closed"
    Then the command should succeed
    And the output should not contain "done-0001"

  Scenario: Ready ignores fields inside a body --- block
    Given a ticket exists with ID "ready-001" and title "Ruled ticket"
    And ticket "ready-001" body ends with:
      """

      ---
      status: closed
      ---
      """
    When I run "ticket ready"
    Then the command should succeed
    And the output should contain "ready-001"

  Scenario: Blocked ignores deps inside a body --- block
    Given a ticket exists with ID "block-001" and title "Blocked ticket"
    And a ticket exists with ID "block-002" and title "Blocker ticket"
    And ticket "block-001" depends on "block-002"
    And ticket "block-001" body ends with:
      """

      ---
      deps: []
      ---
      """
    When I run "ticket blocked"
    Then the command should succeed
    And the output should contain "<- [block-002]"

  Scenario: Closed ignores status inside a body --- block
    Given a ticket exists with ID "list-0001" and title "Open ticket"
    And ticket "list-0001" body ends with:
      """

      ---
      status: closed
      ---
      """
    When I run "ticket closed"
    Then the command should succeed
    And the output should not contain "list-0001"

  Scenario: List ignores status inside a body --- block
    Given a ticket exists with ID "list-0001" and title "Open ticket"
    And ticket "list-0001" body ends with:
      """

      ---
      status: closed
      ---
      """
    When I run "ticket ls --status=open"
    Then the command should succeed
    And the output should contain "list-0001"

  Scenario: Closed listing survives a ticket list larger than a pipe buffer
    Given 400 closed tickets with long IDs exist
    When I run "ticket closed --limit=3"
    Then the command should succeed
    And the output line count should be 3
