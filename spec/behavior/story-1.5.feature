Feature: Confirm upgrade and refresh Billing page

  Background:
    Given "tpg@example.com" is signed in on the "Standard" plan with renewal date "Oct 30, 2026"
    And the upgrade dialog is open

  @AC-1
  Scenario: Confirming upgrades the page without a reload
    When they click "Confirm Upgrade"
    Then exactly one request is sent to "/api/billing/upgrade" with the email "tpg@example.com"
    And the dialog closes
    And the page shows the "Premium" plan at "$40/month" with renewal date "Oct 30, 2026"
    And the usage cards show "4K Ultra HD", "Can watch on 4 devices at once" and "Can download on 6 devices"
    And the "Upgrade to Premium" button is no longer shown
    And the page was not reloaded

  @AC-2
  Scenario: A success message is shown briefly
    When they click "Confirm Upgrade"
    Then the message "You're now on Premium! Your next full cycle bills at $40/month." is shown
    And the message disappears after a few seconds

  @AC-3
  Scenario: A failed request keeps the dialog open
    Given the upgrade request will fail
    When they click "Confirm Upgrade"
    Then an inline error is shown in the dialog
    And the dialog stays open
    And the page still shows "Standard" at "$20/month"
    And "Confirm Upgrade" can be clicked again

  @AC-4
  Scenario: Existing behaviour is not regressed
    When they sign out and sign in again
    Then the Billing page shows the current plan
    And registering a new account still creates a Standard account with its own billing data
    And an invalid login still shows "Invalid credentials"

  @AC-5
  Scenario: Browser tests cover success and failure
    Given the Playwright suite for this story
    When it runs the full upgrade flow against the real backend
    Then it asserts the success outcome of AC-1 and AC-2
    And with the upgrade request forced to fail it asserts the outcome of AC-3
