# Functional Design Plan

Scope: proration rule, upgrade state transition, Billing page component design, testable properties (PBT-01).
Inputs: epic-brief.md, requirements.md, stories.md, atlas-deep-dive.md.

## Checklist
- [x] Analyze system context
- [x] Draft questions (below)
- [ ] Collect answers
- [ ] Write `spec/plans/functional-design.md` (business logic, rules, frontend components, Testable Properties)
- [ ] Present completion message and wait for approval

## Question 1: Date used for "today"
Days remaining depends on today's date. The backend uses the server's local date; the browser preview uses the browser's local date. Near midnight or across time zones they can differ by one day (REQ-F-03 uses the backend value as the charged amount).

A) Accept it: backend uses the server local date, the preview uses the browser local date, and the success message uses the backend `prorated_charge` (Recommended)

B) Make both use UTC dates

X) Other (please describe after [Answer]: tag below)

[Answer]: 

## Question 2: Charged amount after confirming
The epic's success message ("You're now on Premium! Your next full cycle bills at $40/month.") has no amount, but the response carries `prorated_charge`. Should the page show the amount that was actually charged?

A) No, show only the specified message (Recommended; matches the epic exactly)

B) Yes, append "You were charged $X.XX today." using the backend `prorated_charge`

X) Other (please describe after [Answer]: tag below)

[Answer]: 
