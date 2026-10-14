Feature: Backend prorated upgrade to Premium

  Background:
    Given the demo account "tpg@example.com" exists on the "Standard" plan at $20/month
    And its renewal date is "Oct 30, 2026"

  @AC-1
  Scenario Outline: Prorated charge for the days remaining
    Given today is "<today>"
    When the days remaining and prorated charge are calculated
    Then the days remaining are <days>
    And the prorated charge is <charge>

    Examples:
      | today        | days | charge |
      | Oct 30, 2026 | 0    | 0.00   |
      | Nov 05, 2026 | 0    | 0.00   |
      | Oct 15, 2026 | 15   | 10.00  |
      | Oct 01, 2026 | 29   | 19.33  |
      | Sep 01, 2026 | 30   | 20.00  |

  @AC-2
  Scenario: Unparseable renewal date is treated as no days remaining
    Given the renewal date of "tpg@example.com" is "not a date"
    When "tpg@example.com" requests an upgrade
    Then the response is 200 with prorated_charge 0.0
    And "tpg@example.com" is on the "Premium" plan

  @AC-3
  Scenario: Successful upgrade applies the Premium plan
    Given today is "Oct 15, 2026"
    When "tpg@example.com" requests an upgrade
    Then the response is 200 with plan_name "Premium", price "$40/month" and prorated_charge 10.0
    And the account's plan is "Premium" and its price is "$40/month"
    And the usages are "4K Ultra HD", "Can watch on 4 devices at once" and "Can download on 6 devices"
    And the plan perks are "Ad-free streaming", "Spatial audio (select titles)" and "Dolby Vision (select titles)" at 100 percent
    And the perks help text is "Perks included in your Premium plan."

  @AC-4
  Scenario: Renewal date is unchanged by the upgrade
    Given today is "Oct 15, 2026"
    When "tpg@example.com" requests an upgrade
    Then the response renew_at is "Oct 30, 2026"
    And the account renewal date is "Oct 30, 2026"
    And the billing renewal date is "Oct 30, 2026"

  @AC-5
  Scenario: Premium data is not shared between accounts
    Given a second Standard account "other@example.com" exists
    When "tpg@example.com" requests an upgrade
    And the Premium usages of "tpg@example.com" are modified in memory
    Then the billing usages of "other@example.com" are unchanged
