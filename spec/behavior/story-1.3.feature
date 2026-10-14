Feature: Upgrade button for Standard users

  @AC-1
  Scenario: A Standard subscriber sees the upgrade button
    Given "tpg@example.com" is signed in on the "Standard" plan
    When they open the Billing page
    Then an "Upgrade to Premium" button is visible below the current plan card

  @AC-2
  Scenario: A Premium subscriber does not see the upgrade button
    Given the signed-in subscriber is on the "Premium" plan
    When they open the Billing page
    Then no "Upgrade to Premium" button is shown

  @AC-3
  Scenario: The button is keyboard operable
    Given "tpg@example.com" is signed in on the "Standard" plan
    When they open the Billing page
    Then the "Upgrade to Premium" button is a focusable button
    And pressing Enter or Space on it triggers its action

  @AC-4
  Scenario: Browser tests cover both plans
    Given the Playwright suite for this story
    When it runs against the Billing page
    Then one test asserts the button is visible for the seed Standard user
    And one test with a mocked Premium billing response asserts the button is absent
