Feature: Local checkout installation
  As a maintainer with an existing tk installation
  I want to install this checkout into a user prefix
  So that core and curated plugins are available without replacing unrelated commands

  Background:
    Given a temporary local checkout and user prefix

  Scenario: Install exposes core, curated plugins, aliases, and safe plugin behavior
    Given a clean tickets directory
    And a ticket exists with ID "install-0001" and title "Installed ticket"
    And a stub editor for installed commands
    When I install the local checkout
    Then the command should succeed
    And the local prefix should contain checkout links:
      """
      tk
      ticket-edit
      ticket-ls
      ticket-list
      ticket-query
      ticket-migrate-beads
      """
    When I run installed "help"
    Then the command should succeed
    And the output should contain "Plugins (tk-<cmd> or ticket-<cmd> in PATH):"
    When I run installed "ls"
    Then the command should succeed
    And the output should contain "install-0001"
    When I run installed "list"
    Then the command should succeed
    And the output should contain "install-0001"
    When I run installed "query"
    Then the command should succeed
    And the output should contain "install-0001"
    When I run installed "edit install-0001"
    Then the command should succeed
    And the output should contain "Edit ticket file:"
    And the stub editor should not have been invoked
    When I run installed "migrate-beads"
    Then the command should fail
    And the output should contain "Error: .beads/issues.jsonl not found"

  Scenario: Reinstalling matching checkout links is idempotent
    When I install the local checkout
    Then the command should succeed
    When I install the local checkout
    Then the command should succeed
    And the output should contain "Already installed:"
    And the local prefix should contain checkout links:
      """
      tk
      ticket-edit
      ticket-ls
      ticket-list
      ticket-query
      ticket-migrate-beads
      """

  Scenario Outline: A conflicting destination aborts installation atomically
    Given prefix entry "ticket-query" is a <kind>
    When I install the local checkout
    Then the command should fail
    And the output should contain "Refusing to replace"
    And prefix entry "ticket-query" should be unchanged
    And no checkout links should have been installed

    Examples:
      | kind            |
      | regular file    |
      | directory       |
      | broken link     |
      | foreign link    |

  Scenario: Installed core follows checkout updates without reinstalling
    Given the local checkout is installed
    When the checkout core is changed to output "updated through symlink"
    And I run installed "help"
    Then the command should succeed
    And the output should be "updated through symlink"

  Scenario: Uninstall removes only links owned by this checkout
    Given the local checkout is installed
    And unrelated prefix entry "keep-me" contains "keep me"
    And installed entry "ticket-query" is retargeted outside the checkout
    When I uninstall the local checkout
    Then the command should succeed
    And owned checkout links should be absent
    And unrelated prefix entry "keep-me" should contain "keep me"
    And retargeted installed entry "ticket-query" should be unchanged
