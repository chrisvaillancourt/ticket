Feature: Ticket Dependencies
  As a user
  I want to manage ticket dependencies
  So that I can track blocking relationships

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "task-0001" and title "Main task"
    And a ticket exists with ID "task-0002" and title "Dependency task"
    And a ticket exists with ID "task-0003" and title "Another task"

  Scenario: Add a dependency
    When I run "ticket dep task-0001 task-0002"
    Then the command should succeed
    And the output should be "Added dependency: task-0001 -> task-0002"
    And ticket "task-0001" should have "task-0002" in deps

  Scenario: Add dependency is idempotent
    Given ticket "task-0001" depends on "task-0002"
    When I run "ticket dep task-0001 task-0002"
    Then the command should succeed
    And the output should be "Dependency already exists"

  Scenario: Add a dependency to a ticket without a deps field
    Given ticket "task-0001" has no field "deps"
    When I run "ticket dep task-0001 task-0002"
    Then the command should succeed
    And the output should be "Added dependency: task-0001 -> task-0002"
    And ticket "task-0001" should have frontmatter field "deps" with value "[task-0002]"
    And ticket "task-0001" should end with exactly one newline and have no trailing whitespace

  Scenario: Add a second dependency after inserting the deps field
    Given ticket "task-0001" has no field "deps"
    When I run "ticket dep task-0001 task-0002"
    And I run "ticket dep task-0001 task-0003"
    Then the command should succeed
    And ticket "task-0001" should have frontmatter field "deps" with value "[task-0002, task-0003]"

  Scenario: Remove a dependency
    Given ticket "task-0001" depends on "task-0002"
    When I run "ticket undep task-0001 task-0002"
    Then the command should succeed
    And the output should be "Removed dependency: task-0001 -/-> task-0002"
    And ticket "task-0001" should not have "task-0002" in deps

  Scenario: Remove non-existent dependency
    When I run "ticket undep task-0001 task-0002"
    Then the command should fail
    And the output should be "Dependency not found"

  Scenario: Remove a dependency from a ticket without a deps field
    Given ticket "task-0001" has no field "deps"
    And I remember the content of ticket "task-0001"
    When I run "ticket undep task-0001 task-0002"
    Then the command should fail
    And the output should be "Dependency not found"
    And ticket "task-0001" should be unchanged

  Scenario: Undep reports a CRLF ticket instead of a missing dependency
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0001" uses CRLF line endings
    And I remember the content of ticket "task-0001"
    When I run "ticket undep task-0001 task-0002"
    Then the command should fail
    And the output should contain "CRLF line endings"
    And the output should not contain "Dependency not found"
    And ticket "task-0001" should be unchanged

  Scenario: Dep reports a CRLF ticket instead of an existing dependency
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0001" uses CRLF line endings
    And I remember the content of ticket "task-0001"
    When I run "ticket dep task-0001 task-0002"
    Then the command should fail
    And the output should contain "CRLF line endings"
    And ticket "task-0001" should be unchanged

  Scenario: Add a dependency leaves a deps line in the body alone
    Given ticket "task-0001" has no field "deps"
    And ticket "task-0001" body ends with:
      """

      deps: [task-0003]
      """
    When I run "ticket dep task-0001 task-0002"
    Then the command should succeed
    And the output should be "Added dependency: task-0001 -> task-0002"
    And ticket "task-0001" should have frontmatter field "deps" with value "[task-0002]"
    And the body of ticket "task-0001" should contain the line "deps: [task-0003]"

  Scenario: Dependency commands ignore deps inside a body --- block
    Given ticket "task-0001" body ends with:
      """

      ---
      deps: [task-0002]
      ---
      """
    And I remember the content of ticket "task-0001"
    When I run "ticket undep task-0001 task-0002"
    Then the command should fail
    And the output should be "Dependency not found"
    And ticket "task-0001" should be unchanged

  Scenario: Add a dependency whose ID is a prefix of an existing one
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    And ticket "task-0001" has field "deps" with value "[t-10]"
    When I run "ticket dep task-0001 t-1"
    Then the command should succeed
    And the output should be "Added dependency: task-0001 -> t-1"
    And ticket "task-0001" should have frontmatter field "deps" with value "[t-10, t-1]"

  Scenario: Remove a dependency whose ID is a prefix of another dependency
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    And ticket "task-0001" has field "deps" with value "[t-10, t-1]"
    When I run "ticket undep task-0001 t-1"
    Then the command should succeed
    And ticket "task-0001" should have frontmatter field "deps" with value "[t-10]"

  Scenario: Removing a missing dependency does not touch a longer ID
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    And ticket "task-0001" has field "deps" with value "[t-10]"
    And I remember the content of ticket "task-0001"
    When I run "ticket undep task-0001 t-1"
    Then the command should fail
    And the output should be "Dependency not found"
    And ticket "task-0001" should be unchanged

  Scenario: Dependency IDs containing regex metacharacters match literally
    Given a ticket exists with ID "a.1" and title "Dotted ID"
    And a ticket exists with ID "ab1" and title "Plain ID"
    And ticket "task-0001" has field "deps" with value "[ab1]"
    And I remember the content of ticket "task-0001"
    When I run "ticket undep task-0001 a.1"
    Then the command should fail
    And the output should be "Dependency not found"
    And ticket "task-0001" should be unchanged

  Scenario: Remove a dependency whose ID contains a dot
    Given a ticket exists with ID "a.1" and title "Dotted ID"
    And a ticket exists with ID "ab1" and title "Plain ID"
    And ticket "task-0001" has field "deps" with value "[ab1, a.1]"
    When I run "ticket undep task-0001 a.1"
    Then the command should succeed
    And ticket "task-0001" should have frontmatter field "deps" with value "[ab1]"

  Scenario: Dependency values are written literally
    Given a ticket exists with ID "t&1" and title "Ampersand ID"
    When I run "ticket dep task-0001 't&1'"
    Then the command should succeed
    And ticket "task-0001" should have frontmatter field "deps" with value "[t&1]"

  Scenario: Dependency tree prefers an exact ID over a longer match
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    When I run "ticket dep tree t-1"
    Then the command should succeed
    And the output should be "t-1 [open] Short ID"

  Scenario: Add dependency with non-existent ticket
    When I run "ticket dep task-0001 nonexistent"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Add dependency to non-existent ticket
    When I run "ticket dep nonexistent task-0001"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: View dependency tree
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0002" depends on "task-0003"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the output should contain "task-0001"
    And the output should contain "task-0002"
    And the output should contain "task-0003"

  Scenario: Dependency tree shows status and title
    Given ticket "task-0001" depends on "task-0002"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the output should contain "[open]"
    And the output should contain "Main task"
    And the output should contain "Dependency task"

  Scenario: Dependency tree uses box-drawing characters
    Given ticket "task-0001" depends on "task-0002"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the output should match box-drawing tree format

  Scenario: Dependency tree with multiple children
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0001" depends on "task-0003"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the output should contain "task-0002"
    And the output should contain "task-0003"

  Scenario: Dependency tree handles cycles gracefully
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0002" depends on "task-0001"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the output should contain "task-0001"
    And the output should contain "task-0002"

  Scenario: Full dependency tree shows all occurrences
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0001" depends on "task-0003"
    And ticket "task-0002" depends on "task-0003"
    When I run "ticket dep tree --full task-0001"
    Then the command should succeed

  Scenario: Dependency tree children sorted by subtree depth then ID
    Given a ticket exists with ID "task-0001" and title "Root"
    And a ticket exists with ID "task-0002" and title "Child B shallow"
    And a ticket exists with ID "task-0003" and title "Child A shallow"
    And a ticket exists with ID "task-0004" and title "Child C deep"
    And a ticket exists with ID "task-0005" and title "Grandchild"
    And ticket "task-0001" depends on "task-0002"
    And ticket "task-0001" depends on "task-0003"
    And ticket "task-0001" depends on "task-0004"
    And ticket "task-0004" depends on "task-0005"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the dep tree output should have task-0002 before task-0003
    And the dep tree output should have task-0003 before task-0004
    And the dep tree output should have task-0002 before task-0004

  Scenario: Dependency tree children sorted by ID when same depth
    Given a ticket exists with ID "task-0001" and title "Root"
    And a ticket exists with ID "task-0005" and title "Child E"
    And a ticket exists with ID "task-0002" and title "Child B"
    And a ticket exists with ID "task-0004" and title "Child D"
    And a ticket exists with ID "task-0003" and title "Child C"
    And ticket "task-0001" depends on "task-0005"
    And ticket "task-0001" depends on "task-0002"
    And ticket "task-0001" depends on "task-0004"
    And ticket "task-0001" depends on "task-0003"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the dep tree output should have task-0002 before task-0003
    And the dep tree output should have task-0003 before task-0004
    And the dep tree output should have task-0004 before task-0005

  Scenario: Dependency tree complex multi-level sorting
    Given a ticket exists with ID "task-0001" and title "Root"
    And a ticket exists with ID "task-0010" and title "Shallow C"
    And a ticket exists with ID "task-0005" and title "Shallow A"
    And a ticket exists with ID "task-0008" and title "Shallow B"
    And a ticket exists with ID "task-0020" and title "Deep B"
    And a ticket exists with ID "task-0015" and title "Deep A"
    And a ticket exists with ID "task-0025" and title "Deepest"
    And ticket "task-0001" depends on "task-0010"
    And ticket "task-0001" depends on "task-0005"
    And ticket "task-0001" depends on "task-0008"
    And ticket "task-0001" depends on "task-0020"
    And ticket "task-0001" depends on "task-0015"
    And ticket "task-0020" depends on "task-0025"
    And ticket "task-0015" depends on "task-0025"
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the dep tree output should have task-0005 before task-0008
    And the dep tree output should have task-0008 before task-0010
    And the dep tree output should have task-0010 before task-0015
    And the dep tree output should have task-0010 before task-0020
    And the dep tree output should have task-0015 before task-0020

  Scenario: Dependency tree ignores deps inside a body --- block
    Given ticket "task-0001" body ends with:
      """

      ---
      deps: [task-0002]
      ---
      """
    When I run "ticket dep tree task-0001"
    Then the command should succeed
    And the output should be "task-0001 [open] Main task"

  Scenario: Dependency cycle ignores deps inside a body --- block
    Given ticket "task-0001" depends on "task-0002"
    And ticket "task-0002" body ends with:
      """

      ---
      deps: [task-0001]
      ---
      """
    When I run "ticket dep cycle"
    Then the command should succeed
    And the output should be "No dependency cycles found"
