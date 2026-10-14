# NFR

## NFR Requirements

Depth: minimal. Inputs: `functional-design.md`, `requirements.md`, answers in `spec/spec-generation/nfr-requirements-generation.md` (Q1 A, Q2 A, Q3 A).

### Not applicable (recorded, not blocking)
- **Scalability / performance / availability**: in-memory, single-process POC with no load targets in the epic; the endpoint does O(1) work. Resiliency baseline is off (Q6 B).

### Security (Security Baseline, blocking, scoped to this change)
| Rule | Requirement for this epic | Status |
|---|---|---|
| SECURITY-03 Application logging | the global handler logs unhandled exceptions with a timestamp and request path; never logs passwords, tokens or full request bodies | Required |
| SECURITY-05 Input validation | request body validated by the Pydantic model (`email`: non-empty string, bounded length); extra and malformed bodies rejected with 422 | Required |
| SECURITY-08 Access control | endpoint takes `email` from the body with no token check (Q1 A, REQ-NF-01) | ACCEPTED DEVIATION, reported by the security review |
| SECURITY-10 Supply chain | no new runtime dependencies; test-only packages are pinned to exact versions in dev files with lockfile (`package-lock.json`) committed | Required |
| SECURITY-11 Secure design | state is mutated only after all checks pass (BR-5); no secret or password in any response (`users[...]["password"]` is never returned by the new endpoint) | Required |
| SECURITY-15 Exception handling | global exception handler returns a generic 500 body, no stack trace; fail closed (no mutation on error) | Required |
| SECURITY-04, 07, 09 (headers, CORS wildcard), SECURITY-12 (plaintext seed passwords, email-as-token) | pre-existing findings from the Atlas deep dive, outside this epic's scope; recorded as known, not fixed here | OUT OF SCOPE, listed in the security review |
| SECURITY-01, 02, 06, 13, 14, 16 | no data store, network intermediary, IAM, serialized artifacts, alerting or cryptography is added | N/A |

### Testability and tech stack
| Area | Decision |
|---|---|
| Backend tests | pytest, FastAPI `TestClient` (needs `httpx`), Hypothesis for properties; files in `tests/unit/`; deps in a dev requirements file (`src/backend/requirements-dev.txt`), not `requirements.txt` |
| Frontend unit tests | Vitest as a devDependency of `src/frontend` (Q1 A), for `daysRemaining` / `proratedCharge` and component behaviour |
| E2E | Playwright (Chromium only) as a root-level dev dependency, specs in `tests/e2e/<story-slug>/`, run against the Vite dev server with a locally started backend (Q2 A) |
| Coverage | `unitTestCoverageMin` stays at the eval-framework default 90.0, applied to changed files only (Q3 A); `tests/.evals/config.json` is created at the STOP checkpoint |
| Date control in tests | backend "today" is injectable (a function parameter or patched `date`); browser tests freeze time; the seed data is never edited |
| Property tests | Hypothesis profile with a fixed example count and deterministic seed in CI; failing examples are saved |

### Usability and accessibility
- Modal is a labelled `dialog` with focus management, Escape to close, keyboard-operable buttons (REQ-NF-07); the inline error uses `role="alert"`; the success message uses `role="status"`.
- Visual styling consistent with the existing Billing page cards in `App.css`.

### Maintainability
- Proration lives in one small pure function per side with the same name (`calculate_days_remaining`, `daysRemaining`), unit-tested against a shared table of values (0, 15, 29, 30, 45 days).
- No new runtime dependencies (REQ-NF-04).
