# CR-<n> — Requirements Delta

Epic: <EPIC-ID> · Written: <ISO timestamp> · AIRE v[N]
Entry mode: <A | B | C | D>

> **Entry Mode C note** — when the operator edited `spec/plans/requirements.md` themselves, this file is
> an **audit record of a change that already exists in their working tree**, not a forward patch. The
> workflow does not rewrite their prose; it records the delta and applies only the version annotations
> (`common/change-request-rules.md` Section 4 bucket (b)).

> 🔴 Versioning follows `common/requirement-versioning.md`: AMENDED → `@v<N+1>` with prior text retained;
> ADDED → new **unversioned** ID (never `@v1`); SUPERSEDED → retained and marked, **never deleted**;
> UNCHANGED → byte-identical.

---

## Summary

| Class | Count | REQ-IDs |
|---|---|---|
| AMENDED | <n> | |
| ADDED | <n> | |
| SUPERSEDED | <n> | |
| UNCHANGED | <n> | *(count only — not enumerated)* |

---

## AMENDED

### REQ-F-03 → REQ-F-03@v2

**Before (v1)**
```
<verbatim prior text>
```

**After (v2)**
```
<verbatim new text>
```

**What changed**: <one factual sentence — the clause, value or condition that differs>
**Covering stories re-pointed**: <story → Covers now names @v2 | routed as blocked>
**As written into `requirements.md`**:

```markdown
### REQ-F-03@v2 — <title>

<new text>

> **Amended by CR-<n> on <YYYY-MM-DD>** (was REQ-F-03, <what differed>).
> Prior text (v1), retained for traceability:
> ~~<prior text>~~
```

---

## ADDED

### REQ-F-<next> — <title>

```
<verbatim new text>
```

**Why it is new**: <the change introduced behaviour no existing requirement expressed>
**Covered by**: <new or CR-born story>
🔴 Unversioned — a newly added requirement never carries `@v1` (RV-3).

---

## SUPERSEDED

### REQ-F-07 — <title>  *(SUPERSEDED)*

**Withdrawn text (retained)**
```
<verbatim text>
```

**As written into `requirements.md`**:

```markdown
### REQ-F-07 — <title>  *(SUPERSEDED)*

> **Superseded by CR-<n> on <YYYY-MM-DD>.** Withdrawn; the behaviour it described no longer applies.
> Retained because Rule 1 forbids reusing a removed requirement ID.
> ~~<prior text>~~
```

**Covering stories**: <story → AC marked superseded; scenario and test case retired>
**Coverage-matrix treatment**: excluded from the gap-A check, recorded `N/A` with this CR
(`common/requirement-versioning.md` Section 5 rule 3).

---

## Coverage matrix after this CR

| REQ-ID | Current version | Covering stories | Status |
|---|---|---|---|

Matrix keyed on **bare REQ-ID** with `@vN` normalised away before matching.

## Version self-check (RV-1 … RV-7)

| # | Predicate | Computed result |
|---|---|---|
| RV-1 | AMENDED heading carries `@v<N+1>` | |
| RV-2 | Prior text retained + annotated | |
| RV-3 | No ADDED requirement carries `@v1` | |
| RV-4 | No SUPERSEDED requirement deleted | |
| RV-5 | UNCHANGED requirements byte-identical | |
| RV-6 | Every covering story re-pointed or routed | |
| RV-7 | Matrix normalises suffixes; superseded excluded | |
