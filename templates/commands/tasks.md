---
description: Generate an actionable, dependency-ordered tasks.md for the feature based on available design artifacts.
scripts:
  sh: scripts/bash/check-prerequisites.sh --json
  ps: scripts/powershell/check-prerequisites.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load design documents**: Read from FEATURE_DIR:
   - **Required**: plan.md (tech stack, libraries, structure), spec.md (user stories with priorities)
   - **Optional**: data-model.md (entities), contracts/ (API endpoints), research.md (decisions), quickstart.md (test scenarios)
   - Note: Not all projects have all documents. Generate tasks based on what's available.

3. **Pre-flight Definition of Ready check**:
   - Ensure plan.md satisfies every Plan DOR item (pinned library/version, full design tokens, 100% component map coverage, interaction contracts, Evidence-to-Decision RT-IDs). If any item is missing, **STOP** and instruct the user to rerun `/speckit.plan` rather than guessing.
   - Ensure spec.md contains prioritized user stories with acceptance scenarios, measurable success criteria, edge cases, and no unresolved `[NEEDS CLARIFICATION]`. If gaps remain, **STOP** and direct the user to `/speckit.specify` or `/speckit.clarify`.
   - If plan.md references data-model.md, contracts/, or quickstart.md but those files are absent, halt with explicit guidance to generate them first.

4. **Branch Map & question budget**:
   - Build a Branch Map of implementation forks that materially change task structure (e.g., backend-first vs vertical slices, test depth per story, deployment workflow, sequencing of integrations).
   - Rank forks by **Impact × Uncertainty** and spend up to four clarification questions on the highest-ranked forks, capturing answers verbatim.
   - If high-impact forks remain unresolved after the question budget, pause and surface them to the user; do **not** proceed until the user responds or explicitly defers them.

5. **Execute task generation workflow** (run only after clarifications are answered/deferred):
   - Load plan.md and extract tech stack, libraries, project structure, design tokens, component map, interaction contracts, and RT-IDs to reference inside tasks.
   - Load spec.md and extract user stories, priorities, acceptance scenarios, success criteria, and edge cases so each task can restate the relevant context.
   - If data-model.md exists: Pull entities, relationships, and validation rules; cite them in the tasks that touch those models.
   - If contracts/ exists: Map endpoints (method, path, payloads, response expectations) to the appropriate tasks and include that detail inline.
   - If research.md exists: Capture performance/security constraints and RT-IDs to cite in tasks.
   - Generate tasks organized by user story (see Task Generation Rules below), guaranteeing that each task includes enough contextual detail (purpose, inputs/outputs, referenced requirements) for an implementor agent working in isolation.
   - Generate dependency graph showing user story completion order with rationale.
   - Create parallel execution examples per user story, specifying file path separations to avoid conflicts.
   - Validate task completeness (each story independently testable, all acceptance criteria represented, explicit verification steps recorded).

6. **Checkpoint C (User approval before writing)**:
   - Summarize planned phases, task counts per story, critical dependencies, validation coverage, and any outstanding assumptions.
   - Present the summary + unresolved assumptions to the user and wait for explicit approval (`continue`) before writing/updating tasks.md.
   - Abort the command if approval is withheld or new clarifications are requested.

7. **Generate tasks.md**: Use `.specify/templates/tasks-template.md` as structure, fill with:
   - Correct feature name from plan.md
   - Phase 1: Setup tasks (project initialization)
   - Phase 2: Foundational tasks (blocking prerequisites for all user stories)
   - Phase 3+: One phase per user story (in priority order from spec.md)
   - Each phase includes: story goal, independent test criteria, tests (if requested), implementation tasks
   - Final Phase: Polish & cross-cutting concerns
   - Prepend an "Agent Execution Contract" section: Allowed libraries/versions; Forbidden actions (no custom components if library exists; no stack changes; no invented defaults); Escalation triggers; Verification and AC/Test plan requirements.
   - Add a "Traceability Summary" table (US/FR/SC → T### mapping)
   - All tasks must follow the strict checklist format (see Task Generation Rules below)
   - Clear file paths for each task
   - Dependencies section showing story completion order
   - Parallel execution examples per story
   - Implementation strategy section (MVP first, incremental delivery)

8. **Report**: Output path to generated tasks.md and summary:
   - Total task count
   - Task count per user story
   - Parallel opportunities identified
   - Independent test criteria for each story
   - Suggested MVP scope (typically just User Story 1)
   - Format validation: Confirm ALL tasks follow the checklist format (checkbox, ID, labels, file paths)
   - Outstanding assumptions or deferred decisions + next command recommendations

Context for task generation: {ARGS}

The tasks.md should be immediately executable - each task must be specific enough that an LLM can complete it without additional context.

## Task Generation Rules

**CRITICAL**: Tasks MUST be organized by user story to enable independent implementation and testing, and each task must stand on its own because different implementor agents (with no extra context) will execute them.

**Tests are OPTIONAL**: Only generate test tasks if explicitly requested in the feature specification or if user requests TDD approach; when tests are included, specify the framework, files, and expected signals (pass/fail) directly in the task.

### Checklist Format (REQUIRED)

Every task MUST strictly follow this format:

```text
- [ ] [TaskID] [P?] [Story?] Description with file path
```

**Format Components**:

1. **Checkbox**: ALWAYS start with `- [ ]` (markdown checkbox)
2. **Task ID**: Sequential number (T001, T002, T003...) in execution order
3. **[P] marker**: Include ONLY if task is parallelizable (different files, no dependencies on incomplete tasks)
4. **[Story] label**: REQUIRED for user story phase tasks only
   - Format: [US1], [US2], [US3], etc. (maps to user stories from spec.md)
   - Setup phase: NO story label
   - Foundational phase: NO story label  
   - User Story phases: MUST have story label
   - Polish phase: NO story label
5. **Description**: Clear action with exact file path plus the relevant context (purpose, inputs/outputs, referenced requirements/RT-IDs, acceptance criteria)

**Examples**:

- ✅ CORRECT: `- [ ] T001 Create project structure per implementation plan`
- ✅ CORRECT: `- [ ] T005 [P] Implement authentication middleware in src/middleware/auth.py`
- ✅ CORRECT: `- [ ] T012 [P] [US1] Create User model in src/models/user.py`
- ✅ CORRECT: `- [ ] T014 [US1] Implement UserService in src/services/user_service.py`
- ❌ WRONG: `- [ ] Create User model` (missing ID and Story label)
- ❌ WRONG: `T001 [US1] Create model` (missing checkbox)
- ❌ WRONG: `- [ ] [US1] Create User model` (missing Task ID)
- ❌ WRONG: `- [ ] T001 [US1] Create model` (missing file path)

### Task Organization

1. **From User Stories (spec.md)** - PRIMARY ORGANIZATION:
   - Each user story (P1, P2, P3...) gets its own phase
   - Map all related components to their story:
     - Models needed for that story
     - Services needed for that story
     - Endpoints/UI needed for that story
     - If tests requested: Tests specific to that story
   - Mark story dependencies (most stories should be independent)
   
2. **From Contracts**:
   - Map each contract/endpoint → to the user story it serves
   - Include HTTP verb, route, payload schema, response requirements, and error handling expectations within the task description
   - If tests requested: Each contract → contract test task [P] before implementation in that story's phase
   
3. **From Data Model**:
   - Map each entity to the user story(ies) that need it
   - Reference field names, validation rules, and relationships explicitly inside the relevant tasks
   - If an entity serves multiple stories: Put creation tasks in the earliest story or Setup phase and reference that originating task ID from later stories
   - Relationships → service layer tasks must mention associated entities and constraints
   
4. **From Setup/Infrastructure**:
   - Shared infrastructure → Setup phase (Phase 1)
   - Foundational/blocking tasks → Foundational phase (Phase 2)
   - Story-specific setup → within that story's phase

### Phase Structure

- **Phase 1**: Setup (project initialization)
- **Phase 2**: Foundational (blocking prerequisites - MUST complete before user stories)
- **Phase 3+**: User Stories in priority order (P1, P2, P3...)
  - Within each story: Tests (if requested) → Models → Services → Endpoints → Integration
  - Each phase should be a complete, independently testable increment
- **Final Phase**: Polish & Cross-Cutting Concerns
