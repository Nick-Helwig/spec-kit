---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
scripts:
  sh: scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
  ps: scripts/powershell/check-prerequisites.ps1 -Json -RequireTasks -IncludeTasks
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `{SCRIPT}` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     * Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     * Completed items: Lines matching `- [X]` or `- [x]`
     * Incomplete items: Lines matching `- [ ]`
   - Create a status table:
     ```
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```
   - Calculate overall status:
     * **PASS**: All checklists have 0 incomplete items
     * **FAIL**: One or more checklists have incomplete items
   
   - **If any checklist is incomplete**:
     * Display the table with incomplete item counts
     * **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     * Wait for user response before continuing
     * If user says "no" or "wait" or "stop", halt execution
     * If user says "yes" or "proceed" or "continue", proceed to step 3
   
   - **If all checklists are complete**:
     * Display the table showing all checklists passed
     * Automatically proceed to step 3

3. **Verify Branch Map checkpoints (required)**:
   - Run `bash scripts/bash/lint-branchmap.sh "$FEATURE_DIR"` (or `sh` as appropriate) to ensure `plan.md` and `tasks.md` contain the Branch Map + Checkpoint summaries.
   - If the script fails, **STOP** and instruct the user to rerun `/speckit.plan` or `/speckit.tasks` to populate the missing sections before implementation begins.
   - Record any outstanding assumptions noted in Checkpoint A/B/C summaries; they must be resolved or explicitly waived in writing before touching code.

4. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

5. **Select the target task (single-task workflow)**:
   - Parse `tasks.md` for unchecked tasks matching `- [ ] T### ...`.
   - If the user input (`$ARGUMENTS`) supplies a task identifier (e.g., `T123`), validate it exists, is currently unchecked, and is eligible to run (no conflicting `[P]` grouping that touches the same files). If validation fails, stop and ask the user to choose a valid task.
   - If no explicit Task ID is provided, choose the first unchecked task in document order. Capture its phase, `[P]` grouping, dependencies, required files/paths, validation commands, and any notes.
   - If **no unchecked tasks remain**, stop and inform the user that implementation is complete for this feature (or that `/speckit.tasks` must be rerun to add scope) before attempting another `/speckit.implement`.
   - Record the selected Task ID + metadata in your status update; the same identifier must be passed to both the implementor and reviewer delegates.

6. **Create a fresh implementor worktree**:
   ```bash
   WORKTREE=.codex/worktrees/implementor-$FEATURE_DIR
   git worktree remove "$WORKTREE" 2>/dev/null || true
   git worktree add "$WORKTREE" HEAD
   ```
   Use this path as the implementor’s `cwd` for the selected task. After the delegate finishes, run `git worktree remove "$WORKTREE"` (or `rm -rf "$WORKTREE"` if already detached) before starting another session.

7. **Launch the implementor sub-agent**:
   - Compile a delegation brief containing:
     * Absolute repo path + FEATURE_DIR
     * Paths to spec.md, plan.md, tasks.md, research.md, data-model.md, contracts/, quickstart.md (when present)
     * The chosen Task ID, phase, `[P]` grouping, description, dependencies, file targets, and required validation commands/tests
     * Outstanding waivers/assumptions noted in Checkpoints A/B/C
     * Any checklist warnings from Step 2
     * The "Implementor Sub-Agent Responsibilities" section below (copy/paste or reference explicitly), including the embedded **TDD** and **Error Handling Patterns** skill requirements from `agents/implementor.md`.
   - Call `mcp__subagents__delegate` with:
     * `agent`: `"implementor"`
     * `cwd`: `.codex/worktrees/implementor-$FEATURE_DIR`
     * `mirror_repo`: `false`
     * `sandbox_mode`: `"workspace-write"`
     * `approval_policy`: `"on-request"` (or stricter if required)
     * `task`: delegation brief from above
   - Instruct the implementor to emit task-level JSON plus a final summary exactly as described under “Implementor Contract Snapshot” in `agents/orchestrator.md`, reminding them to complete **only** the delegated Task ID and stop immediately afterward.

8. **Handle implementor output**:
   - If the sub-agent reports `BLOCKED` or `FAILED`, stop and surface the blocker plus required upstream command (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`). Do not continue until the user resolves it.
   - If DONE, capture:
     * Updated files / git status
     * Task log + summary JSON
     * Any residual risks or TODOs lifted by the implementor
     * Confirmation that only the delegated Task ID checkbox flipped to `[x]`; if other tasks changed, revert and re-run the implementor with clarified scope.

9. **Mandatory review (per-task, two passes)**:
   - Immediately run `/speckit.review` (template below) to trigger both review passes **or** delegate manually via `mcp__subagents__delegate` twice using the same Task ID and artifacts:
     * First: `agent: "review-code"` for senior-dev code review
     * Second: `agent: "review-alignment"` for Spec Kit alignment and gates
   - Each review must return a findings-first report with severity-ranked issues scoped to that task and an explicit APPROVED/BLOCK/CHANGES REQUESTED verdict. Do not ship code until both reviews pass or blocking findings are explicitly waived.

10. **Report**:
    - Present the selected Task ID, implementor summary, review findings, outstanding risks, and recommended next steps (e.g., rerun `/speckit.tasks` for new scope, deploy, etc.).
    - Archive task/review JSON artifacts in the feature directory if required by the team, and note whether the task is ACCEPTED or requires follow-up.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.

## Implementor Sub-Agent Responsibilities

Include the following contract/instructions inside the delegation brief for the `implementor` sub-agent. They apply to the **single** Task ID delegated in this run:

1. **Task intake & DOR checks**
   - Verify Plan DOR (design system, tokens, component map, interaction contracts, RT-IDs) and Tasks DOR (Agent Execution Contract, traceability table, Branch Map checkpoints, `[NEEDS CLARIFICATION]` cleared).
   - Confirm the orchestrator-supplied Task ID exists in `tasks.md`, is unchecked, and matches the description/phase/`[P]` notes provided in the brief. Halt with `BLOCKED` if anything is inconsistent.
   - Capture dependencies, file/path targets, validation commands, and required libraries from plan.md/tasks.md/research.md.

2. **Project Setup Verification**
   - **REQUIRED**: Create/verify ignore files based on actual project setup:
   
     **Detection & Creation Logic**:
     - Determine if the repository is a git repo (create/verify .gitignore if so):

       ```sh
       git rev-parse --git-dir 2>/dev/null
       ```
     - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
     - Check if .eslintrc* or eslint.config.* exists → create/verify .eslintignore
     - Check if .prettierrc* exists → create/verify .prettierignore
     - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
     - Check if terraform files (*.tf) exist → create/verify .terraformignore
     - Check if .helmignore needed (helm charts present) → create/verify .helmignore
   
     **If ignore file already exists**: Verify it contains essential patterns; append missing critical patterns only.
   
     **If ignore file missing**: Create with full pattern set for detected technology.
   
     **Common Patterns by Technology** (from plan.md tech stack):
     - **Node.js/JavaScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
     - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
     - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
     - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
     - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
     - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
     - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
     - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
     - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
     - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
     - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
     - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`
   
     **Tool-Specific Patterns**:
     - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
     - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
     - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
     - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   
3. **Understand the assigned task context**
   - Locate the delegated Task ID within `tasks.md` and note its phase (Setup, Foundational, USx, Polish, etc.), `[P]` grouping, and sequencing constraints.
   - Document prerequisites and dependent tasks so you can flag a BLOCKED state if prerequisites are incomplete.
   - Extract the exact files, directories, contracts, and validation commands referenced in the task description.

4. **Execute the delegated task**
   - Work strictly within this task’s scope; if `[P]` applies, ensure no conflicting files are touched.
   - Follow TDD instructions: add/run failing tests first, implement minimal code, rerun tests to confirm GREEN, and refactor while staying green.
   - Reuse mapped UI components and libraries pinned in plan.md; avoid new dependencies unless the task explicitly allows them.
   - Run any validations/tests specified by the task before marking it complete.

5. **Progress tracking and error handling**
   - Update only the delegated task checkbox (`- [ ]` → `- [x]`) and emit a JSON log entry (DONE/BLOCKED/FAILED/SKIPPED) for that task.
   - Stop immediately on BLOCKED conditions (missing plan detail, unmapped UI component, contract mismatch) and bubble the blocker to the orchestrator with remediation guidance.
   - Include commands run, errors, files touched, and timestamps inside the JSON log.

6. **Completion validation**
   - Ensure the delegated task satisfies spec/plan requirements, RT-IDs, and any acceptance criteria/tests.
   - Confirm tests/lint/build commands requested by the task pass cleanly (no warnings).
   - Produce the final summary JSON for this single task with totals/by-phase counts and STOP status (`READY_FOR_REVIEW` vs `Await clarification`), then exit so the review agent can take over.
