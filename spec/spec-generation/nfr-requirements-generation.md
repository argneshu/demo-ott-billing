# NFR Requirements Plan

Depth: minimal. Scalability, availability and performance are N/A for an in-memory single-process POC (resiliency extension off, no load targets in the epic). Security, testability and usability are in scope.

## Checklist
- [x] Analyze functional design
- [x] Draft questions (below)
- [x] Collect answers (Q1 A, Q2 A, Q3 A)
- [x] Write `spec/plans/nfr.md` (`## NFR Requirements`)
- [ ] Present completion message and wait for approval

## Question 1: Frontend unit-test runner
The frontend has no test tooling. Story 1.4 needs unit tests for `daysRemaining` and `proratedCharge`.

A) Vitest as a devDependency (fits the existing Vite setup; no runtime dependency change) (Recommended)

B) Node's built-in `node --test` with no new packages (helpers kept in a plain `.js` module)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2: Test locations and Playwright scope
Backend tests go in `tests/unit/` (pytest, Hypothesis, httpx for TestClient), Playwright in `tests/e2e/<story-slug>/`, with Playwright as a dev dependency at the repo root `package.json`, not in `src/frontend`. E2E runs Chromium only against the Vite dev server and a locally started backend.

A) Accept as stated (Recommended)

B) Put Playwright under `src/frontend` (devDependency of the frontend package)

X) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 3: Unit-test coverage threshold
The eval framework default `unitTestCoverageMin` is 90.0, applied to the changed files only.

A) Keep the 90.0 default (Recommended; the changed code is small and pure)

B) Lower it for this POC (give the value after the tag)

X) Other (please describe after [Answer]: tag below)

[Answer]: A
