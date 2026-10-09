# Session Continuity Templates

## Welcome Back Prompt Template
When a user returns to continue work on an existing aire project, present this prompt:

```markdown
**Welcome back! I can see you have an existing aire project in progress.**

Based on your runtime-artifacts/aire-state.md, here's your current status:
- **Project**: [project-name]
- **Current Phase**: [PLANNING/IMPLEMENTATION]
- **Current Stage**: [Stage Name]
- **Last Completed**: [Last completed step]
- **Next Step**: [Next step to work on]
- **Recording approvals as**: [current session email — read live from the session context; email only, no name]

**What would you like to work on today?**

A) Continue where you left off ([Next step description])

B) Review a previous stage ([Show available stages])

[Answer]: 
```

## MANDATORY: Session Continuity Instructions
1. **Always read runtime-artifacts/aire-state.md first** when detecting existing project — **as the resolved view**: the shared file plus every work-unit fragment `runtime-artifacts/stories/*/state.md` present (`common/parallel-work-state.md` Section 4). **Resuming a work-unit workflow** (`dev-implement`, `epic-enhance`, `epic-bugfix`, `pr-fix`, `bug-fix-implement`, `enhancement-implement` Phase B) reads that unit's own `state.md` `## Progress` and `## Self-Healing Counters` and its `audit.md` first, and continues writing only those fragment files
2. **Resolve the Session Identity** (silent, email-only, tool-free — per the Session Identity Capture rules in the root workflow file): read the current session email LIVE from the environment context. NO confirmation question and NO stored state — the email is recorded ONLY in runtime-artifacts/audit.md, NEVER in runtime-artifacts/aire-state.md (do not create or update a `## Session Identity` section; if an older run left one, ignore it).
   All runtime-artifacts/audit.md entries in this session carry `**User Email**:` with the current session email — at every approval flow this field records who approved. A different developer resuming the project automatically logs under their own email. Email only; never record a name.
3. **Parse current status** from the workflow file to populate the prompt
4. **MANDATORY: Load Previous Stage Artifacts** - Before resuming any stage, automatically read all relevant artifacts from previous stages:
   - **Reverse Engineering**: Read atlas-deep-dive.md, code-structure.md, api-documentation.md
   - **Requirements Analysis**: Read requirements.md, spec/spec-generation/requirement-verification-questions.md
   - **User Stories**: Read stories.md, personas.md, spec/spec-generation/story-generation.md, the `## Story Tracker` in runtime-artifacts/aire-state.md (statuses, requires, Tracker IDs), AND the `## Tracker` section in runtime-artifacts/aire-state.md (Type, Parent Epic ID/URL, Project Key / Repo / Org) — required so a resumed session can still link pushed stories to the Parent Epic provided at workflow start, and knows which tracker to dispatch to without re-asking
   - **Dependency Graph**: Read `spec/plans/dependency-graph.yml` (`requires`/`enables`) and the `## Dependency Graph` section in runtime-artifacts/aire-state.md
   - **Application Design**: Read `spec/plans/application-design.md` (components, methods, services and dependencies, merged)
   - **Implementation Design**: Read the flat system-level design docs in `spec/plans/` —
     `functional-design.md`, `nfr.md` (NFR Requirements + NFR Design sections),
     `infrastructure-design.md` and, once the STOP CHECKPOINT has run, `architecture.md`. A stage that
     was skipped has no file; load whichever exist (`common/directory-structure.md`).
   - **At the STOP CHECKPOINT / Code Generation (`dev-implement`)**: If runtime-artifacts/aire-state.md shows `Design complete — awaiting dev-implement`, remind the user to type `dev-implement` to build a story. On resuming a `dev-implement` session, read the resolved Story Tracker (shared table + `runtime-artifacts/stories/*/state.md` fragments, `common/parallel-work-state.md`) + dependency-graph.yml to recompute the currently ready stories, and re-check the Doability Gate before continuing any in-progress story.
   - **Code Stages**: Read all code files, plans, the Story Tracker, dependency-graph.yml, AND all previous artifacts
5. **Smart Context Loading by Stage**:
   - **Early Stages (Workspace Detection, Reverse Engineering)**: Load workspace analysis
   - **Requirements/Stories**: Load reverse engineering + requirements artifacts
   - **Design Stages**: Load requirements + stories + architecture + design artifacts
   - **Code Stages**: Load ALL artifacts + existing code files
6. **Adapt options** based on architectural choice and current phase
7. **Show specific next steps** rather than generic descriptions
8. **Log the continuity prompt** in runtime-artifacts/audit.md with timestamp
9. **Context Summary**: After loading artifacts, provide brief summary of what was loaded for user awareness
10. **Asking questions**: ALWAYS ask clarification or user feedback questions by placing them in .md files. DO NOT place the multiple-choice questions in-line in the chat session.

## Error Handling
If artifacts are missing or corrupted during session resumption, see [error-handling.md](error-handling.md) for guidance on recovery procedures. 