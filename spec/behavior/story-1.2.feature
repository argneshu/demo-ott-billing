Feature: Upgrade request rejection paths

  Background:
    Given the demo account "tpg@example.com" exists on the "Standard" plan at $20/month

  @AC-1
  Scenario: A Premium account cannot upgrade again
    Given "tpg@example.com" is on the "Premium" plan
    When "tpg@example.com" requests an upgrade
    Then the response is 400 with detail "Already on Premium plan"
    And the account and billing data are unchanged

  @AC-2
  Scenario: An unknown email is rejected
    When "ghost@example.com" requests an upgrade
    Then the response is 401 with detail "Not authenticated"
    And no account "ghost@example.com" exists

  @AC-3
  Scenario Outline: A malformed request body is rejected
    When an upgrade is requested with the body <body>
    Then the response is 422
    And the account and billing data are unchanged

    Examples:
      | body             |
      | {}               |
      | {"email": ""}    |
      | {"email": 123}   |
      | {"email": null}  |

  @AC-4
  Scenario: An unexpected failure returns a safe response
    Given the upgrade calculation fails unexpectedly
    When "tpg@example.com" requests an upgrade
    Then the response is 500 with a generic error body
    And the body contains no stack trace, password or token
    And "tpg@example.com" is still on the "Standard" plan

  @AC-5
  Scenario: A second upgrade of any upgraded account always fails
    Given "tpg@example.com" has upgraded to Premium
    When "tpg@example.com" requests an upgrade again
    Then the response is 400 with detail "Already on Premium plan"
    And the account is still "Premium" with an unchanged renewal date
