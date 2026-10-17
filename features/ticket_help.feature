Feature: Command Help
  As a user
  I want help for a single command
  So that I can check its options without reading the full help

  Background:
    Given the tickets directory does not exist

  Scenario Outline: Built-in commands accept --help and -h
    When I run "ticket <command> <flag>"
    Then the command should succeed
    And the output line 1 should contain "<command> <usage>"
    And the tickets directory should not exist

    Examples:
      | command  | flag   | usage                   |
      | create   | --help | [title] [options]       |
      | create   | -h     | [title] [options]       |
      | start    | --help | <id>                    |
      | close    | -h     | <id>                    |
      | reopen   | --help | <id>                    |
      | status   | --help | <id> <status>           |
      | defer    | --help | <id> [options]          |
      | undefer  | --help | <id>                    |
      | deferred | --help |                         |
      | dep      | --help | <id> <dep-id>           |
      | undep    | --help | <id> <dep-id>           |
      | link     | --help | <id> <id> [id...]       |
      | unlink   | --help | <id> <target-id>        |
      | ready    | --help | [-a X] [-T X]           |
      | blocked  | --help | [-a X] [-T X]           |
      | closed   | --help | [--limit=N]             |
      | show     | --help | <id>                    |
      | add-note | --help | <id> [text]             |

  Scenario: Command help lists the command's options
    When I run "ticket create --help"
    Then the command should succeed
    And the output should contain "--description-file"
    And the output should contain "--dry-run"
    And the output should not contain "add-note"

  Scenario: Help flag after other arguments
    When I run "ticket create 'Not a ticket' --help"
    Then the command should succeed
    And the output line 1 should contain "create [title] [options]"
    And the tickets directory should not exist

  Scenario: Dep help covers its subcommands
    When I run "ticket dep --help"
    Then the command should succeed
    And the output should contain "dep tree [--full] <id>"
    And the output should contain "dep cycle"
    And the output should not contain "undep"

  Scenario: Unknown commands still fail
    Given a clean tickets directory
    When I run "ticket frobnicate --help"
    Then the command should fail
    And the output should contain "Unknown command: frobnicate"
