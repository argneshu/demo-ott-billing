Feature: Self-serve Premium upgrade - end to end

  Background:
    Given the demo account "tpg@example.com" exists on the "Standard" plan at $20/month
    And its renewal date is "Oct 30, 2026"
    And today is "Oct 15, 2026"

  @REQ-F-01 @REQ-F-02 @REQ-F-03 @REQ-F-04 @REQ-F-06 @REQ-F-07 @REQ-F-09
  Scenario: A Standard subscriber previews, confirms and sees Premium without a reload
    Given "tpg@example.com" is signed in and viewing the Billing page
    When they open the upgrade dialog
    Then the dialog says "You'll be charged $10.00 today for the 15 days remaining in your cycle."
    When they confirm the upgrade
    Then the Billing page shows the "Premium" plan at "$40/month" with renewal date "Oct 30, 2026"
    And the usage cards show "4K Ultra HD", "Can watch on 4 devices at once" and "Can download on 6 devices"
    And the "Upgrade to Premium" button is no longer shown
    And the page was not reloaded

  @REQ-F-05 @REQ-F-01
  Scenario: After upgrading, a repeat upgrade is refused and the account stays Premium
    Given "tpg@example.com" has upgraded to Premium
    When an upgrade is requested again for "tpg@example.com"
    Then the response is 400 with detail "Already on Premium plan"
    And reloading the Billing page still shows "Premium" at "$40/month" with no upgrade button

  @REQ-F-10 @REQ-F-04 @REQ-NF-05
  Scenario: A failed upgrade leaves the subscriber on Standard everywhere
    Given "tpg@example.com" is signed in and has the upgrade dialog open
    And the upgrade request will fail with a server error
    When they confirm the upgrade
    Then an inline error is shown and the dialog stays open
    And reloading the Billing page still shows "Standard" at "$20/month" with the upgrade button

  @REQ-F-04 @REQ-F-03 @REQ-NF-05
  Scenario: A newly registered subscriber can upgrade from their own account
    Given a new user "new@example.com" registers and lands on the Standard plan
    When "new@example.com" upgrades to Premium
    Then "new@example.com" sees "Premium" at "$40/month"
    And "tpg@example.com" still sees "Standard" at "$20/month"
