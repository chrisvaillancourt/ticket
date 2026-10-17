Feature: Ticket Status Management
  As a user
  I want to change ticket statuses
  So that I can track progress on tasks

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "test-0001" and title "Test ticket"

  Scenario: Set status to in_progress
    When I run "ticket status test-0001 in_progress"
    Then the command should succeed
    And the output should be "Updated test-0001 -> in_progress"
    And ticket "test-0001" should have field "status" with value "in_progress"

  Scenario: Set status to closed
    When I run "ticket status test-0001 closed"
    Then the command should succeed
    And the output should be "Updated test-0001 -> closed"
    And ticket "test-0001" should have field "status" with value "closed"

  Scenario: Set status to open
    Given ticket "test-0001" has status "closed"
    When I run "ticket status test-0001 open"
    Then the command should succeed
    And the output should be "Updated test-0001 -> open"
    And ticket "test-0001" should have field "status" with value "open"

  Scenario: Start command sets status to in_progress
    When I run "ticket start test-0001"
    Then the command should succeed
    And the output should be "Updated test-0001 -> in_progress"
    And ticket "test-0001" should have field "status" with value "in_progress"

  Scenario: Close command sets status to closed
    When I run "ticket close test-0001"
    Then the command should succeed
    And the output should be "Updated test-0001 -> closed"
    And ticket "test-0001" should have field "status" with value "closed"

  Scenario: Reopen command sets status to open
    Given ticket "test-0001" has status "closed"
    When I run "ticket reopen test-0001"
    Then the command should succeed
    And the output should be "Updated test-0001 -> open"
    And ticket "test-0001" should have field "status" with value "open"

  Scenario: Invalid status value
    When I run "ticket status test-0001 invalid"
    Then the command should fail
    And the output should contain "Error: invalid status 'invalid'"
    And the output should contain "open in_progress closed"

  Scenario: Status of non-existent ticket
    When I run "ticket status nonexistent open"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Status command with partial ID
    When I run "ticket status 0001 in_progress"
    Then the command should succeed
    And ticket "test-0001" should have field "status" with value "in_progress"

  Scenario: Set status on a ticket without a status field
    Given ticket "test-0001" has no field "status"
    When I run "ticket status test-0001 closed"
    Then the command should succeed
    And the output should be "Updated test-0001 -> closed"
    And ticket "test-0001" should have frontmatter field "status" with value "closed"
    And ticket "test-0001" should end with exactly one newline and have no trailing whitespace

  Scenario: Set status on a ticket without frontmatter fails
    Given a file ".tickets/bare-0001.md" containing:
      """
      # Bare ticket

      No frontmatter here.
      """
    And I remember the content of ticket "bare-0001"
    When I run "ticket status bare-0001 closed"
    Then the command should fail
    And the output should contain "no YAML frontmatter"
    And the output should not contain "Updated"
    And ticket "bare-0001" should be unchanged

  Scenario: Set status on a ticket whose only --- is a body rule fails
    Given a file ".tickets/bare-0002.md" containing:
      """
      # Ruled ticket

      text

      ---

      more
      """
    And I remember the content of ticket "bare-0002"
    When I run "ticket status bare-0002 closed"
    Then the command should fail
    And the output should contain "no YAML frontmatter"
    And ticket "bare-0002" should be unchanged

  Scenario: Set status on a ticket with unclosed frontmatter fails
    Given a file ".tickets/open-0001.md" containing:
      """
      ---
      id: open-0001
      status: open
      # Unclosed ticket
      """
    And I remember the content of ticket "open-0001"
    When I run "ticket status open-0001 closed"
    Then the command should fail
    And the output should contain "frontmatter is not closed"
    And ticket "open-0001" should be unchanged

  Scenario: Set status on a CRLF ticket fails with an accurate error
    Given ticket "test-0001" uses CRLF line endings
    And I remember the content of ticket "test-0001"
    When I run "ticket status test-0001 closed"
    Then the command should fail
    And the output should contain "CRLF"
    And the output should not contain "no YAML frontmatter"
    And ticket "test-0001" should be unchanged

  Scenario: Close leaves a status line in the body alone
    Given ticket "test-0001" body ends with:
      """

      status: degraded
      """
    When I run "ticket close test-0001"
    Then the command should succeed
    And ticket "test-0001" should have frontmatter field "status" with value "closed"
    And the body of ticket "test-0001" should contain the line "status: degraded"

  Scenario: Status adds a missing field to the frontmatter, not to a body line
    Given ticket "test-0001" has no field "status"
    And ticket "test-0001" body ends with:
      """

      status: degraded
      """
    When I run "ticket status test-0001 closed"
    Then the command should succeed
    And ticket "test-0001" should have frontmatter field "status" with value "closed"
    And the body of ticket "test-0001" should contain the line "status: degraded"
