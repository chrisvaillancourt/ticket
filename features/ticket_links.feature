Feature: Ticket Links
  As a user
  I want to create symmetric links between tickets
  So that I can track related tickets

  Background:
    Given a clean tickets directory
    And a ticket exists with ID "link-0001" and title "First ticket"
    And a ticket exists with ID "link-0002" and title "Second ticket"
    And a ticket exists with ID "link-0003" and title "Third ticket"

  Scenario: Link two tickets
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should be "Added link: link-0001 <-> link-0002"
    And ticket "link-0001" should have "link-0002" in links
    And ticket "link-0002" should have "link-0001" in links

  Scenario: Link three tickets
    When I run "ticket link link-0001 link-0002 link-0003"
    Then the command should succeed
    And the output should be:
      """
      Added link: link-0001 <-> link-0002
      Added link: link-0001 <-> link-0003
      Added link: link-0002 <-> link-0003
      """
    And ticket "link-0001" should have "link-0002" in links
    And ticket "link-0001" should have "link-0003" in links
    And ticket "link-0002" should have "link-0001" in links
    And ticket "link-0002" should have "link-0003" in links
    And ticket "link-0003" should have "link-0001" in links
    And ticket "link-0003" should have "link-0002" in links

  Scenario: Link is idempotent
    Given ticket "link-0001" is linked to "link-0002"
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should be "All links already exist"

  Scenario: Unlink two tickets
    Given ticket "link-0001" is linked to "link-0002"
    When I run "ticket unlink link-0001 link-0002"
    Then the command should succeed
    And the output should be "Removed link: link-0001 <-> link-0002"
    And ticket "link-0001" should not have "link-0002" in links
    And ticket "link-0002" should not have "link-0001" in links

  Scenario: Unlink non-existent link
    When I run "ticket unlink link-0001 link-0002"
    Then the command should fail
    And the output should be "Link not found"

  Scenario: Link with non-existent ticket
    When I run "ticket link link-0001 nonexistent"
    Then the command should fail
    And the output should contain "Error: ticket 'nonexistent' not found"

  Scenario: Partial linking adds only new links
    Given ticket "link-0001" is linked to "link-0002"
    When I run "ticket link link-0001 link-0002 link-0003"
    Then the command should succeed
    And the output should be:
      """
      Added link: link-0001 <-> link-0003
      Added link: link-0002 <-> link-0003
      """

  Scenario: Duplicate IDs are rejected
    When I run "ticket link link-0001 link-0001 link-0002"
    Then the command should fail
    And the output should contain "Error: duplicate ticket 'link-0001'"
    And ticket "link-0001" should not have "link-0001" in links
    And ticket "link-0001" should not have "link-0002" in links

  Scenario: Link adds a missing links field
    Given ticket "link-0001" has no field "links"
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should be "Added link: link-0001 <-> link-0002"
    And ticket "link-0001" should have frontmatter field "links" with value "[link-0002]"
    And ticket "link-0002" should have frontmatter field "links" with value "[link-0001]"
    And ticket "link-0001" should end with exactly one newline and have no trailing whitespace

  Scenario: Link leaves a links line in the body alone
    Given ticket "link-0001" has no field "links"
    And ticket "link-0001" body ends with:
      """

      links: [link-0003]
      """
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should be "Added link: link-0001 <-> link-0002"
    And ticket "link-0001" should have frontmatter field "links" with value "[link-0002]"
    And the body of ticket "link-0001" should contain the line "links: [link-0003]"

  Scenario: Link checks every ticket before writing any
    Given a file ".tickets/bare-0001.md" containing:
      """
      # Bare ticket

      No frontmatter here.
      """
    And ticket "link-0001" has no field "links"
    And I remember the content of ticket "link-0001"
    And I remember the content of ticket "bare-0001"
    When I run "ticket link link-0001 bare-0001"
    Then the command should fail
    And the output should contain "no YAML frontmatter"
    And ticket "link-0001" should be unchanged
    And ticket "bare-0001" should be unchanged

  Scenario: Link adds an ID that is a prefix of an existing link
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    And ticket "link-0001" has field "links" with value "[t-10]"
    When I run "ticket link link-0001 t-1"
    Then the command should succeed
    And the output should be "Added link: link-0001 <-> t-1"
    And ticket "link-0001" should have frontmatter field "links" with value "[t-10, t-1]"

  Scenario: Unlink an ID that is a prefix of another link
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    And ticket "link-0001" has field "links" with value "[t-10, t-1]"
    And ticket "t-1" has field "links" with value "[link-0001]"
    When I run "ticket unlink link-0001 t-1"
    Then the command should succeed
    And the output should be "Removed link: link-0001 <-> t-1"
    And ticket "link-0001" should have frontmatter field "links" with value "[t-10]"
    And ticket "t-1" should have frontmatter field "links" with value "[]"

  Scenario: Unlinking a missing link does not touch a longer ID
    Given a ticket exists with ID "t-1" and title "Short ID"
    And a ticket exists with ID "t-10" and title "Long ID"
    And ticket "link-0001" has field "links" with value "[t-10]"
    And I remember the content of ticket "link-0001"
    When I run "ticket unlink link-0001 t-1"
    Then the command should fail
    And the output should be "Link not found"
    And ticket "link-0001" should be unchanged

  Scenario: Unlink IDs containing regex metacharacters literally
    Given a ticket exists with ID "a.1" and title "Dotted ID"
    And a ticket exists with ID "ab1" and title "Plain ID"
    And ticket "link-0001" has field "links" with value "[ab1, a.1]"
    And ticket "a.1" has field "links" with value "[link-0001]"
    When I run "ticket unlink link-0001 a.1"
    Then the command should succeed
    And ticket "link-0001" should have frontmatter field "links" with value "[ab1]"

  Scenario: Link reports pairs when no ticket has a links field
    Given ticket "link-0001" has no field "links"
    And ticket "link-0002" has no field "links"
    When I run "ticket link link-0001 link-0002"
    Then the command should succeed
    And the output should be "Added link: link-0001 <-> link-0002"
    And ticket "link-0001" should have frontmatter field "links" with value "[link-0002]"
    And ticket "link-0002" should have frontmatter field "links" with value "[link-0001]"
