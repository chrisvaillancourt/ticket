Feature: Ticket Notes
  As a user
  I want to add notes to tickets
  So that I can track progress and updates

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "note-0001" and title "Test ticket"

  Scenario: Add a note to ticket
    When I run "ticket add-note note-0001 'This is my note'"
    Then the command should succeed
    And the output should be "Note added to note-0001"
    And ticket "note-0001" should contain "## Notes"
    And ticket "note-0001" should contain "This is my note"

  Scenario: Note has timestamp
    When I run "ticket add-note note-0001 'Timestamped note'"
    Then the command should succeed
    And ticket "note-0001" should contain a timestamp in notes

  Scenario: Add multiple notes
    When I run "ticket add-note note-0001 'First note'"
    And I run "ticket add-note note-0001 'Second note'"
    Then ticket "note-0001" should contain "First note"
    And ticket "note-0001" should contain "Second note"

  Scenario: Add note to ticket that already has notes section
    Given ticket "note-0001" has a notes section
    When I run "ticket add-note note-0001 'Additional note'"
    Then the command should succeed
    And ticket "note-0001" should contain "Additional note"

  Scenario: Add note with empty string adds timestamp-only note
    When I run "ticket add-note note-0001 ''"
    Then the command should succeed
    And the output should be "Note added to note-0001"
    And ticket "note-0001" should contain "## Notes"

  Scenario Outline: Note input never leaves a blank line at end of file
    When I add a note to ticket "note-0001" <source> "<input>"
    Then the command should succeed
    And the output should be "Note added to note-0001"
    And the last note in ticket "note-0001" should be "<note>"
    And ticket "note-0001" should end with exactly one newline and have no trailing whitespace

    Examples:
      | source        | input          | note       |
      | with argument | note           | note       |
      | with argument | l1\nl2         | l1\nl2     |
      | with argument | note\n         | note       |
      | with argument | note\n\n       | note       |
      | with argument | l1\nl2\n       | l1\nl2     |
      | with argument | \n\nl1\n\nl2\n | \n\nl1\n\nl2 |
      | with argument |                |            |
      | with argument | \n\n           |            |
      | from stdin    | note           | note       |
      | from stdin    | note\n         | note       |
      | from stdin    | l1\nl2\n\n     | l1\nl2     |
      | from stdin    |                |            |
      | from stdin    | \n\n           |            |

  Scenario Outline: Note input never leaves a blank line when a notes section exists
    Given ticket "note-0001" has a notes section
    When I add a note to ticket "note-0001" <source> "<input>"
    Then the command should succeed
    And the last note in ticket "note-0001" should be "<note>"
    And ticket "note-0001" should end with exactly one newline and have no trailing whitespace

    Examples:
      | source        | input  | note |
      | with argument | note\n | note |
      | with argument |        |      |
      | from stdin    | note\n | note |
      | from stdin    |        |      |

  Scenario: Multiple arguments are joined into one note ending in one newline
    When I run "ticket add-note note-0001 two words"
    Then the command should succeed
    And the last note in ticket "note-0001" should be "two words"
    And ticket "note-0001" should end with exactly one newline and have no trailing whitespace

  Scenario: Notes added after empty and trailing-newline notes stay separated
    When I add a note to ticket "note-0001" with argument ""
    And I add a note to ticket "note-0001" with argument "first\n"
    And I add a note to ticket "note-0001" with argument "second"
    Then the last note in ticket "note-0001" should be "second"
    And ticket "note-0001" should contain "Z**\n\n**"
    And ticket "note-0001" should contain "first\n\n**"
    And ticket "note-0001" should end with exactly one newline and have no trailing whitespace

  Scenario: Add note to non-existent ticket
    When I run "ticket add-note nonexistent 'My note'"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Add note with partial ID
    When I run "ticket add-note 0001 'Partial ID note'"
    Then the command should succeed
    And the output should be "Note added to note-0001"
