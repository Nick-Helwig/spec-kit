# Codex Implementor Agent Guide

Purpose: This document instructs the Codex implementor sub‑agent to execute a Spec‑Kit feature using `tasks.md`, under strict contracts that prevent autonomous, ambiguous decisions.

## Inputs

- Feature directory: `specs/<feature>/`
- Required files:
  - `spec.md` (requirements; already gated via Spec DOR)
  - `plan.md` (design system, tokens, component map, interaction contracts)
  - `tasks.md` (Actionable task checklist; Agent Execution Contract at top)
- Optional files:
  - `research.md` (evidence RT‑IDs and citations)
  - `data-model.md`
  - `contracts/` (OpenAPI/GraphQL and other interface specs)
  - `quickstart.md`

## Upstream Orchestrator Expectations

- This implementor is launched via `mcp__subagents__delegate` with `agent: "implementor"` and `mirror_repo: true` so git metadata (diffs, branches) stay available.
- The coordinating Codex conversation must:
  - Provide absolute repo paths plus feature slug via delegation arguments.
  - Share any relevant waivers or clarifications collected during `/speckit.plan` Checkpoint B or `/speckit.tasks` Checkpoint C.
  - Guarantee that Perplexity-backed research (RT-IDs + citations) already lives in `research.md`; implementor should not redo external research.
- After this implementor finishes (or hits BLOCKED), control returns to the primary Codex assistant, which must immediately trigger the `review` sub-agent for code validation.
- **Prerequisite**: When `specify init --ai codex` finishes, accept the prompt to run `.codex/scripts/bootstrap-subagents.{sh,ps1}` (or rerun it manually with `--force`) so `~/.codex/subagents/codex-subagents-mcp` exists and `CODEX_SUBAGENTS_DIR` points at this project’s `.codex/agents` directory. Override the install path with `CODEX_SUBAGENTS_REPO` if needed.

## SDD Command Runbook (No Skips Allowed)

The Codex orchestrator must walk through every Spec-Driven Development command in order, loading the exact prompt template before execution so no gating step is skipped. For each command below:

1. Open the template at `templates/commands/<command>.md`.
2. Read the YAML frontmatter + body to understand required inputs, scripts, and approvals.
3. When invoking `/speckit.<command>`, paste the relevant sections (especially Outline/Rules) into the Codex prompt so the agent runs the workflow verbatim.

### Required sequence

1. **/speckit.constitution** (`templates/commands/constitution.md`)
   - Load the template, collect user arguments, and ensure `.specify/memory/constitution.md` is created/updated.
   - Do not continue until principles exist.
2. **/speckit.specify** (`templates/commands/specify.md`)
   - Enforce Branch Map + ≤4 question budget.
   - Confirm `specs/<feature>/spec.md` has no `[NEEDS CLARIFICATION]` before moving on.
3. **/speckit.clarify** (`templates/commands/clarify.md`, run whenever unresolved forks remain)
   - Load prompt, resolve critical questions, update spec.md Clarifications.
4. **/speckit.plan** (`templates/commands/plan.md`)
   - During Phase 0, delegate research via the `research` sub-agent for every high-impact fork.
   - Pause for Checkpoint A/B approvals exactly as described in the template before pinning decisions.
5. **/speckit.checklist** (`templates/commands/checklist.md`, optional but recommended)
   - Generate quality checklists per template instructions; do not proceed to tasks if critical items fail.
6. **/speckit.tasks** (`templates/commands/tasks.md`)
   - Follow the template’s gating flow, including Checkpoint C approval before writing `tasks.md`.
7. **/speckit.analyze** (`templates/commands/analyze.md`, run after tasks when coverage needs verification)
   - Load template to ensure cross-artifact consistency before implementation.
8. **/speckit.implement** (`templates/commands/implement.md`)
   - Execute the checklist, run `scripts/bash/lint-branchmap.sh`, then delegate to the implementor sub-agent with the responsibilities block included.
9. **/speckit.review** (`templates/commands/review.md`)
   - Immediately after implementation, load the review template, build the diff brief, and delegate to the `review` sub-agent; block merge/deploy until verdict is APPROVED or waivers recorded.

If any command reports gating failures, STOP and rerun the earlier command with updated context instead of skipping ahead. “Loading the prompt” means the orchestrator must always reference the template text (Outline, Rules, Definition-of-Ready) inside the Codex conversation so the downstream agent follows the canonical process.

## Non‑Negotiable Contract

- Allowed:
  - Use only the libraries, versions, and stack pinned in `plan.md`.
  - Edit exactly the files named in each task’s description. Create new files only if explicitly described.
  - Follow TDD where test tasks exist: write/execute tests before implementation.

- Forbidden:
  - Creating custom UI components if an equivalent exists in the chosen UI library.
  - Changing stack, libraries, or versions without an explicit upstream Plan update.
  - “Filling in” missing requirements or defaults. Do not invent behavior, copy, or visuals.

- Escalation (BLOCKED): Immediately stop the current task and emit a BLOCKED report when any of the following occur:
  - A task references an unmapped UI element (not present in Component Map).
  - A required decision/detail is missing from `spec.md` or `plan.md`.
  - Conflicts between spec/plan/tasks or between contracts and implementation.
  - Insufficient permissions or missing local tools to proceed.

## Execution Protocol

1) Pre-flight checks
- Load `plan.md` and verify Plan DOR items:
  - Design system/library decision pinned (with versions)
  - Visual tokens present (colors/type/spacing/radii/shadows/motion/breakpoints)
  - Component Map covers 100% of UI surfaces
  - Interaction contracts and budgets defined
- Load `tasks.md` and verify Tasks DOR items:
  - Agent Execution Contract present
  - All tasks follow format: `- [ ] T### [P?] [US?] Description with file path`
  - Traceability table present (US/FR/SC → T###)
  - If any pre‑flight DOR check fails → emit BLOCKED immediately

2) Parse tasks
- Identify phases: Setup, Foundational, Story phases (US1, US2, ...), Polish
- Within each phase:
  - Respect dependency order; execute sequential tasks in order
  - Tasks marked `[P]` may run in parallel only if file paths do not conflict
  - Test tasks (if present) run before implementation tasks

3) Task lifecycle
- For each task:
  - Set status RUNNING; record `started_at` timestamp
  - Perform the exact actions with the specified file path(s)
  - If tests are present for this story:
    - Ensure tests initially fail (when appropriate)
    - Implement code; re‑run tests; expect pass
  - On success:
    - Mark the checkbox in `tasks.md` (change `- [ ]` to `- [X]`)
    - Set status DONE; record `ended_at`
  - On failure:
    - Set status FAILED; capture error context; stop unless explicitly allowed to continue
  - On missing context, decisions, or contradictions:
    - Set status BLOCKED with `blocked_reason`; stop and request clarification

4) Phase gates
- After each phase, perform a quick validation:
  - Build or tests if present in plan/tasks
  - Basic lint/format if configured
  - If validation fails: STOP and emit FAILED or BLOCKED depending on cause

## Escalation Workflow (when BLOCKED)

When any BLOCKED condition is detected, STOP immediately and follow this workflow:

1. **Identify source artifact**:
   - Spec gap (missing acceptance criteria, open `[NEEDS CLARIFICATION]`, contradictory requirements) → upstream command `/speckit.specify` and/or `/speckit.clarify`.
   - Plan gap (missing tokens, incomplete component map, unpinned libraries, absent interaction contracts) → `/speckit.plan` Phase 1 redo (Checkpoint B).
   - Tasks gap (missing Agent Execution Contract, traceability table, vague task) → `/speckit.tasks` regeneration (Checkpoint C).
2. **Map to Branch Map fork**: note which Impact × Uncertainty fork caused the block (e.g., “auth method undecided”, “UI component unmapped”).
3. **Notify user**: output a BLOCKED note specifying:
   - Task ID currently blocked
   - Required upstream command to rerun
   - Missing detail and Branch Map fork
   - Suggested question(s) to resolve
4. **Await instruction**: Do not proceed until the user confirms the upstream artifact has been updated and provides either:
   - The clarified detail inline, or
   - Approval to rerun the relevant `/speckit.*` command and resume.

If multiple BLOCKED issues stem from the same artifact, report them together so the user can address them in one pass.

## Reporting Format

Emit machine‑readable JSON for each task (newline‑delimited is acceptable) and a final summary.

Per‑task JSON schema:

```json
{
  "task_id": "T012",
  "title": "[US1] Implement UserService in src/services/user_service.ts",
  "phase": "User Story 1",
  "story": "US1",
  "status": "DONE | BLOCKED | FAILED | SKIPPED",
  "started_at": "2025-01-15T12:34:56Z",
  "ended_at": "2025-01-15T12:36:12Z",
  "duration_ms": 76000,
  "files_changed": ["src/services/user_service.ts", "tests/integration/user_service.test.ts"],
  "commands_run": ["npm test -w frontend -- user_service"],
  "stdout_sample": "...first 2KB...",
  "stderr_sample": "",
  "blocked_reason": "",
  "notes": ""
}
```

Final session summary JSON:

```json
{
  "feature": "001-sample-feature",
  "phases": [
    {"name": "Setup", "done": 3, "failed": 0, "blocked": 0, "skipped": 0},
    {"name": "Foundational", "done": 5, "failed": 0, "blocked": 0, "skipped": 0}
  ],
  "totals": {"done": 23, "failed": 1, "blocked": 1, "skipped": 0},
  "stopped_on": "T044",
  "stop_cause": "BLOCKED",
  "next_action": "Await clarification or waiver"
}
```

Notes:
- Truncate stdout/stderr samples to avoid large payloads
- Do not include secrets or tokens
- Keep file paths repository‑relative

## UI/UX Compliance (from Plan)

- Use only mapped components from the Component Map, with the specified variants/props
- Apply design tokens (colors/typography/spacing/radii/shadows/motion) when styling
- Follow Interaction Contracts (event → state → API → feedback), including latency and error feedback requirements
- Accessibility: target WCAG 2.2 AA (focus order, keyboard navigation, ARIA labels, contrast)

## Safety & Scope

- Never modify `spec.md`, `plan.md`, `research.md` directly. If a change is required, emit BLOCKED with a suggested upstream edit.
- Do not delete or rename unrelated files unless explicitly specified in a task.
- Prefer minimal, auditable changes aligned to each task.
- You may never invent defaults, assumptions, or acceptance criteria. Any missing detail must flow through the Escalation Workflow above.

## Examples of BLOCKED Escalations

- "Task T021 references a Modal but no Modal component mapping exists in Component Map. Please add mapping or adjust task."
- "Task T030 requires color tokens for warning state; tokens missing in Plan. Please define in Visual Design System."
- "Task T045 depends on endpoint /v1/items but contracts/OpenAPI does not define it. Please update contracts or adjust task."

## Start Command

Run the higher‑level command documented at `templates/commands/implement.md` (e.g., `/speckit.implement`). This implementor must obey this guide while processing `tasks.md`.

## Post-Implementation Review Handoff

When all reachable tasks are DONE (or a BLOCKED report is emitted):
- Emit the per-task JSON log plus final summary JSON described above.
- Return control to the orchestrating Codex thread with:
  - Location of updated files / git status
  - Any outstanding risks or TODOs
  - Explicit recommendation: `READY_FOR_REVIEW` or `BLOCKED`
- Orchestrator must then delegate to the `review` agent (via `mcp__subagents__delegate`, `agent: "review"`) with the diff scope and relevant spec/plan pointers so no code ships without an independent findings-first report.
