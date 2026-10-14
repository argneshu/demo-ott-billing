# Requirements Clarification Questions

Epic: Self-Serve Premium Upgrade (Atlas epic 6225 / story 6226). The Epic is already detailed, so only the
genuine gaps and the mandatory extension opt-ins are asked. Fill in each `[Answer]:` tag, then tell me "done".

## Question 1
`POST /api/billing/upgrade` takes the user's `email` in the request body, with no credential check (the POC "token" is just the email). Anyone who knows an email could upgrade that account. The Security Baseline is a blocking constraint, so how should this be handled?

A) Follow the Epic as written (email in body, POC auth model) and record the gap as an accepted, documented POC deviation in requirements.md and the security review

B) Follow the Epic's request shape, but also require the caller's token (the same `email` query param the other endpoints use) and return 401/403 when it does not match the body email

C) Take identity only from the token and ignore any body email (body kept for compatibility)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
Proration uses a fixed 30-day cycle. If `days_remaining` is greater than 30 (a `renew_at` more than 30 days away), AC-3 says "days_remaining >= 30 -> $20.00". Should the days be capped at 30 for the formula?

A) Yes - cap `days_remaining` at 30, so the maximum charge is $20.00 (matches AC-3)

B) No - let it exceed 30 (charge above $20.00)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3
The modal preview computes the prorated amount client-side, while the backend recomputes it on confirm. If they differ (e.g. the day rolls over between preview and confirm), what does the user see?

A) Show the backend's amount in the success message; accept the small possible difference (simplest)

B) Add a read-only preview, `GET /api/billing/upgrade-preview`, so the modal shows the backend-computed amount (single source of truth); this is an addition beyond the Epic

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 4
Error handling is not specified for: unknown user, an unparseable `renew_at`, or a network/server failure on Confirm. Proposed: unknown user -> 401 "Not authenticated"; bad `renew_at` -> 500 is avoided by treating it as 0 days remaining; on a failed Confirm the modal stays open and shows an inline error with no state change. Accept this?

A) Yes, as proposed

B) Yes, but an unparseable `renew_at` should return HTTP 422/400 instead of silently charging $0.00

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 5
Automated tests. The repo has no tests yet. The Playwright extension and unit-test gates are mandatory. What should the story's test scope be?

A) Backend unit tests (pytest + FastAPI TestClient) for the endpoint and proration (days 0, 15, 29, 30+, already-Premium, unknown user) plus a Playwright E2E for the UI flow (Recommended)

B) Backend unit tests only; UI covered by the manual test plan

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 6: Resiliency Extensions
Should the resiliency baseline be applied to this project?

**What this extension is.** Enabling it applies a set of **directional, design-time best practices** for building resilient systems, derived from the **AWS Well-Architected Framework (Reliability Pillar)** and resilience-review guidance. It steers requirements, design, and code toward fault tolerance, high availability, observability, and recoverability - covering 15 practice areas across business goals, change management, observability, high availability, disaster recovery, and continuous improvement.

**What this extension is NOT.** Enabling it does **not** make your workload production-ready, nor does it certify or guarantee any availability, RTO, or RPO target. It is a **starting point** that scaffolds good resiliency decisions early - it is not a substitute for a formal **AWS Well-Architected Review** of the built system.

Treat the output as a well-grounded **first draft of your resiliency posture** to build on and validate - not a finished, production-certified result.

A) Yes - apply the resiliency baseline as directional best practices and design-time guidance (recommended for business-critical workloads, as an informed starting point that you can validate and harden before go-live)

B) No - skip the resiliency baseline (suitable for PoCs, prototypes, and experimental projects where rapid iteration matters more than reliability)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

## Question 7: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes - enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial - enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No - skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: A
