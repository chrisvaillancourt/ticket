Feature: Deferred Work
  As a user
  I want to defer work independently of its lifecycle status
  So that temporarily ineligible work remains visible without appearing ready

  Background:
    Given a clean tickets directory

  Scenario: Defer a ticket with a partial ID, date, and reason
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    When I run "ticket defer 0001 --reason 'Waiting on API/docs & UX: phase 2!' --until 2099-12-31"
    Then the command should succeed
    And the output should be "Deferred defer-0001"
    And ticket "defer-0001" should have field "deferred" with value "true"
    And ticket "defer-0001" should have field "defer_reason" with value "Waiting on API/docs & UX: phase 2!"
    And ticket "defer-0001" should have field "defer_until" with value "2099-12-31"

  Scenario: Re-deferring replaces metadata and clears omitted options
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    When I run "ticket defer defer-0001 --until 2099-12-31 --reason 'First reason'"
    And I run "ticket defer defer-0001"
    Then the command should succeed
    And ticket "defer-0001" should have field "deferred" with value "true"
    And ticket "defer-0001" should not have field "defer_reason"
    And ticket "defer-0001" should not have field "defer_until"
    And ticket "defer-0001" should end with exactly one newline and have no trailing whitespace

  Scenario: Undefer removes all metadata and is idempotent with a partial ID
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    When I run "ticket defer defer-0001 --until 2099-12-31 --reason 'Waiting'"
    And I run "ticket undefer 0001"
    Then the command should succeed
    And the output should be "Undeferred defer-0001"
    And ticket "defer-0001" should not have field "deferred"
    And ticket "defer-0001" should not have field "defer_reason"
    And ticket "defer-0001" should not have field "defer_until"
    And ticket "defer-0001" should end with exactly one newline and have no trailing whitespace
    When I run "ticket undefer defer-0001"
    Then the command should succeed
    And the output should be "Undeferred defer-0001"

  Scenario Outline: Defer accepts valid calendar dates
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    When I run "ticket defer defer-0001 --until <date>"
    Then the command should succeed
    And ticket "defer-0001" should have field "defer_until" with value "<date>"

    Examples:
      | date       |
      | 2024-02-29 |
      | 2026-04-30 |
      | 9999-12-31 |

  Scenario Outline: Defer rejects invalid calendar dates without mutation
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    And I remember the content of ticket "defer-0001"
    When I run "ticket defer defer-0001 --until <date>"
    Then the command should fail
    And the output should contain "Error: invalid defer date '<date>'"
    And ticket "defer-0001" should be unchanged

    Examples:
      | date       |
      | 2026-2-03  |
      | 2026-02-29 |
      | 2026-04-31 |
      | 2026-13-01 |
      | 0000-01-01 |

  Scenario Outline: Defer rejects invalid options without mutation
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    And I remember the content of ticket "defer-0001"
    When I run "ticket defer defer-0001 <options>"
    Then the command should fail
    And ticket "defer-0001" should be unchanged

    Examples:
      | options         |
      | --until         |
      | --reason        |
      | --unknown value |

  Scenario Outline: Defer rejects multiline reasons without mutation
    Given a ticket exists with ID "defer-0001" and title "Needs input"
    And I remember the content of ticket "defer-0001"
    When I defer ticket "defer-0001" with a reason containing <control>
    Then the command should fail
    And the output should contain "Error: defer reason must be one line"
    And ticket "defer-0001" should be unchanged

    Examples:
      | control         |
      | a line feed     |
      | a carriage return |

  Scenario: Ready and deferred honor dates, false metadata, lifecycle, and legacy tickets
    Given a ticket exists with ID "view-forever" and title "Deferred forever"
    And a ticket exists with ID "view-future" and title "Deferred until later"
    And a ticket exists with ID "view-elapsed" and title "Elapsed deferral"
    And a ticket exists with ID "view-today" and title "Eligible today"
    And a ticket exists with ID "view-false" and title "Explicitly not deferred"
    And a ticket exists with ID "view-closed" and title "Closed deferred"
    And a ticket exists with ID "view-legacy" and title "Legacy ticket"
    And ticket "view-today" has field "deferred" with value "true"
    And ticket "view-today" has defer_until set to today in UTC
    And ticket "view-false" has field "deferred" with value "false"
    When I run "ticket defer view-forever"
    And I run "ticket defer view-future --until 9999-12-31"
    And I run "ticket defer view-elapsed --until 2000-01-01"
    And I run "ticket defer view-closed"
    And I run "ticket close view-closed"
    And I run "ticket ready"
    Then the output should not contain "view-forever"
    And the output should not contain "view-future"
    And the output should not contain "view-closed"
    And the output should contain "view-elapsed"
    And the output should contain "view-today"
    And the output should contain "view-false"
    And the output should contain "view-legacy"
    When I run "ticket deferred"
    Then the command should succeed
    And the output should contain "view-forever"
    And the output should contain "[deferred=true]"
    And the output should contain "view-future"
    And the output should contain "defer_until=9999-12-31"
    And the output should not contain "view-elapsed"
    And the output should not contain "view-today"
    And the output should not contain "view-false"
    And the output should not contain "view-closed"
    And the output should not contain "view-legacy"

  Scenario: A deferred blocked ticket remains visible in both structural views
    Given a ticket exists with ID "block-main" and title "Blocked and deferred"
    And a ticket exists with ID "block-dep" and title "Open dependency"
    And ticket "block-main" depends on "block-dep"
    When I run "ticket defer block-main --reason 'Waiting for dependency'"
    And I run "ticket blocked"
    Then the output should contain "block-main"
    When I run "ticket deferred"
    Then the output should contain "block-main"
    And the output should contain "defer_reason=Waiting for dependency"
    When I run "ticket ready"
    Then the output should not contain "block-main"

  Scenario: Deferring a dependency does not unblock its dependent
    Given a ticket exists with ID "dependent" and title "Dependent work"
    And a ticket exists with ID "dependency" and title "Deferred dependency"
    And ticket "dependent" depends on "dependency"
    When I run "ticket defer dependency"
    And I run "ticket blocked"
    Then the output should contain "dependent"
    When I run "ticket close dependency"
    And I run "ticket blocked"
    Then the output should not contain "dependent"
    When I run "ticket ready"
    Then the output should contain "dependent"
    When I run "ticket deferred"
    Then the output should not contain "dependency"

  Scenario: Lifecycle commands preserve deferral metadata
    Given a ticket exists with ID "life-0001" and title "Lifecycle ticket"
    When I run "ticket defer life-0001 --until 9999-12-31 --reason 'Waiting on review'"
    And I run "ticket start life-0001"
    And I run "ticket status life-0001 open"
    And I run "ticket close life-0001"
    And I run "ticket reopen life-0001"
    Then ticket "life-0001" should have field "status" with value "open"
    And ticket "life-0001" should have field "deferred" with value "true"
    And ticket "life-0001" should have field "defer_reason" with value "Waiting on review"
    And ticket "life-0001" should have field "defer_until" with value "9999-12-31"
    When I run "ticket deferred"
    Then the output should contain "life-0001"

  Scenario: Plugin list, show, and query retain elapsed deferral metadata
    Given a ticket exists with ID "visible-0001" and title "Visible metadata"
    When I run "ticket defer visible-0001 --until 2000-01-01 --reason 'Waiting on API/docs & UX: phase 2!'"
    And I run "ticket ls"
    Then the output should contain "visible-0001"
    And the output should contain "[deferred=true; defer_until=2000-01-01; defer_reason=Waiting on API/docs & UX: phase 2!]"
    When I run "ticket list"
    Then the output should contain "[deferred=true; defer_until=2000-01-01; defer_reason=Waiting on API/docs & UX: phase 2!]"
    When I run "ticket show visible-0001"
    Then the output should contain "deferred: true"
    And the output should contain "defer_until: 2000-01-01"
    And the output should contain "defer_reason: Waiting on API/docs & UX: phase 2!"
    When I run "ticket query '.id == \"visible-0001\"'"
    Then the command should succeed
    And the output should be valid JSONL
    And the JSONL output should have field "deferred" with value "true"
    And the JSONL output should have field "defer_until" with value "2000-01-01"
    And the JSONL output should have field "defer_reason" with value "Waiting on API/docs & UX: phase 2!"

  Scenario: Legacy list and query output remain free of deferral metadata
    Given a ticket exists with ID "legacy-0001" and title "Legacy ticket"
    When I run "ticket ls"
    Then the output should contain "legacy-0001"
    And the output should not contain "deferred="
    When I run "ticket query '.id == \"legacy-0001\"'"
    Then the command should succeed
    And the JSONL output should not have field "deferred"
