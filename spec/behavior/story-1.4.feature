Feature: Upgrade confirmation modal with prorated preview

  Background:
    Given "tpg@example.com" is signed in on the "Standard" plan with renewal date "Oct 30, 2026"
    And today is "Oct 15, 2026"
    And they are viewing the Billing page

  @AC-1
  Scenario: The dialog shows the plans and the prorated charge
    When they click "Upgrade to Premium"
    Then a dialog labelled for the upgrade opens and focus moves into it
    And it shows "Standard" at "$20/mo" and "Premium" at "$40/mo"
    And it shows "15" days remaining
    And it says "You'll be charged $10.00 today for the 15 days remaining in your cycle."
    And it has "Confirm Upgrade" and "Cancel" buttons
    And no upgrade request has been sent

  @AC-2
  Scenario Outline: The client preview matches the backend rule
    Given the renewal date is "<renew_at>" and today is "<today>"
    When the preview amount is calculated
    Then the days remaining are <days> and the amount is <amount>

    Examples:
      | renew_at     | today        | days | amount |
      | Oct 30, 2026 | Oct 30, 2026 | 0    | 0.00   |
      | Oct 30, 2026 | Oct 15, 2026 | 15   | 10.00  |
      | Oct 30, 2026 | Oct 01, 2026 | 29   | 19.33  |
      | Oct 30, 2026 | Sep 01, 2026 | 30   | 20.00  |
      | not a date   | Oct 15, 2026 | 0    | 0.00   |

  @AC-3
  Scenario Outline: Dismissing the dialog changes nothing
    Given the upgrade dialog is open
    When they <dismiss>
    Then the dialog closes
    And no upgrade request was sent
    And the Billing page still shows "Standard" at "$20/month"
    And focus returns to the "Upgrade to Premium" button

    Examples:
      | dismiss                |
      | click Cancel           |
      | press Escape           |
      | click the close control |

  @AC-4
  Scenario: Browser test covers the preview and Cancel
    Given the Playwright suite for this story
    When it opens the dialog for the seed user
    Then it asserts the displayed amount for the frozen date
    And it asserts that Cancel sends no request to "/api/billing/upgrade"
