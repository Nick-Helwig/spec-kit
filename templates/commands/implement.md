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

5. **Launch the implementor sub-agent**:
   - Compile a delegation brief containing:
     * Absolute repo path + FEATURE_DIR
     * Paths to spec.md, plan.md, tasks.md, research.md, data-model.md, contracts/, quickstart.md (when present)
     * Outstanding waivers/assumptions noted in Checkpoints A/B/C
     * Any checklist warnings from Step 2
     * The "Implementor Sub-Agent Responsibilities" section below (copy/paste or reference explicitly)
   - Call `mcp__subagents__delegate` with:
     * `agent`: `"implementor"`
     * `cwd`: repo root
     * `mirror_repo`: `true` (preserves git metadata)
     * `sandbox_mode`: `"workspace-write"`
     * `approval_policy`: `"on-request"` (or stricter if required)
     * `task`: delegation brief from above
   - Instruct the implementor to emit task-level JSON plus a final summary as defined in `agents/codex/agents.md`.

6. **Handle implementor output**:
   - If the sub-agent reports `BLOCKED` or `FAILED`, stop and surface the blocker plus required upstream command (`/speckit.specify`, `/speckit.plan`, `/speckit.tasks`). Do not continue until the user resolves it.
   - If DONE, capture:
     * Updated files / git status
     * Task log + summary JSON
     * Any residual risks or TODOs lifted by the implementor

7. **Mandatory review**:
   - Immediately run `/speckit.review` (template below) **or** delegate manually via `mcp__subagents__delegate` with `agent: "review"` using the current diff, spec/plan references, and testing status.
   - The review agent must return a findings-first report with severity-ranked issues, explicit APPROVE/BLOCK verdict, and test coverage notes. Do not ship code until high/critical findings are resolved or waived in writing.

8. **Report**:
   - Present implementor summary, review findings, outstanding risks, and recommended next steps (e.g., rerun `/speckit.tasks` for new scope, deploy, etc.).
   - Archive task/review JSON artifacts in the feature directory if required by the team.

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.

## Implementor Sub-Agent Responsibilities

Include the following contract/instructions inside the delegation brief for the `implementor` sub-agent. The implementor must perform these steps while executing tasks.md:

1. **Project Setup Verification**
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

2. **Parse tasks.md structure and extract**
   - Identify task phases (Setup, Tests, Core, Integration, Polish).
   - Capture dependencies (sequential vs parallel) and file/path assignments.
   - Understand execution order plus required validation steps.

3. **Execute implementation following the task plan**
   - Work phase-by-phase; complete prerequisites before moving forward.
   - Respect dependencies (sequential vs `[P]` parallel tasks).
   - Follow TDD instructions: run/add tests before implementation when tasks require it.
   - Coordinate file edits to avoid conflicts (parallel tasks only if files differ).
   - Run validation (tests, linters) at the close of each phase when tasks specify it.

4. **Implementation execution rules**
   - Setup before feature work.
   - Prioritize tests when specified.
   - Implement models/services/endpoints per plan.
   - Handle integration/polish tasks last (monitoring, docs, perf).

5. **Progress tracking and error handling**
   - After each task, update its checkbox (`- [ ]` → `- [X]`) and emit JSON log entry (DONE/BLOCKED/FAILED/SKIPPED).
   - Stop immediately on BLOCKED conditions (missing plan detail, unmapped UI component, contract mismatch) and bubble blocker to orchestrator.
   - Provide clear remediation guidance for failures (commands run, errors, files touched).

6. **Completion validation**
   - Verify all tasks that can run are completed.
   - Confirm implementation matches spec/plan + RT-IDs.
   - Ensure tests pass, coverage expectations met, and lint/format run when required.
   - Produce final summary JSON with totals/by-phase counts and STOP status (READY_FOR_REVIEW vs BLOCKED).
