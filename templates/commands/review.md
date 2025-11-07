---
description: Run a findings-first code review for a completed task using the dedicated review sub-agent immediately after implementation.
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

1. **Setup**: Run `{SCRIPT}` from repo root and parse FEATURE_DIR plus AVAILABLE_DOCS. All paths must be absolute. Escaped quoting same as other commands (`'I'\''m'` etc.).

2. **Load context**:
   - Required: spec.md, plan.md, tasks.md
   - Optional: research.md, data-model.md, contracts/, quickstart.md, checklists/*
   - Confirm `tasks.md` is updated after the most recent `/speckit.implement` run. Other tasks may remain unchecked, but the target Task ID under review must now be `[x]`.

3. **Identify review target (single-task workflow)**:
   - Expect `$ARGUMENTS` to provide the Task ID (e.g., `T123`). If missing or malformed, stop and request the orchestrator/user rerun `/speckit.review` with the Task ID.
   - Locate the Task ID in `tasks.md`, verify it exists and is `[x]`, and capture its description, phase, `[P]` grouping, dependencies, file targets, and validation commands.
   - If the Task ID is absent or still unchecked, halt and instruct the user to re-run `/speckit.implement` for that task before requesting review.
   - Collect the implementor’s JSON/log output for this task (commands executed, tests run, files modified) so the reviewer can reference it.

4. **Capture change scope**:
   - Run `git status --short` to list modified files (or use the user-provided path filter from `$ARGUMENTS`).
   - Generate a diff summary via `git diff --stat` (or `git diff <target>` if the user specifies).
   - Note current branch, latest commit hash, and whether tests have been executed since the last commit.

5. **Build the review brief**:
   - Feature slug + branch
   - Summary of the delegated Task ID (description, phase, `[P]` grouping) and any dependent stories
   - List of modified files + high-risk areas (auth, payments, migrations, infra)
   - Testing status (commands run, pass/fail, missing coverage) from the implementor’s JSON/log
   - Outstanding assumptions / waivers carried over from tasks
   - Implementor evidence: attach or inline the task-level JSON/log so the reviewer can verify scope, timing, and commands.

6. **Create a dedicated review worktree**:
   ```bash
   WORKTREE=.codex/worktrees/review-$FEATURE_DIR
   git worktree remove "$WORKTREE" 2>/dev/null || true
   git worktree add "$WORKTREE" HEAD
   ```
   Set `cwd` to this path when delegating, and remove it (`git worktree remove "$WORKTREE"`) after the reviewer returns.

7. **Delegate to the review sub-agent**:
   - Call `mcp__subagents__delegate` with:
     * `agent`: `"review"`
     * `cwd`: `.codex/worktrees/review-$FEATURE_DIR`
     * `mirror_repo`: `false`
     * `sandbox_mode`: `"read-only"` (reviewers do not modify code)
     * `approval_policy`: `"on-request"`
     * `task`: the review brief plus explicit reference to the expectations below, including the embedded **TDD** and **Error Handling Patterns** checks defined in `agents/review.md`, and the Task ID + implementor JSON/log for this run.
   - Provide spec/plan/tasks file paths so the reviewer can cross-reference requirements and trace findings back to the Task ID.

8. **Process review findings**:
   - If the reviewer returns BLOCKED/FAILED or reports Critical/High issues, stop and address them (or document waivers) before re-running `/speckit.implement` for that task.
   - If APPROVED with only Low/Info notes, summarize findings and next steps for the user (e.g., mark the task accepted, proceed to the next unchecked task, merge, deploy).

9. **Archive**:
   - Record the reviewer’s JSON/markdown report in the feature directory (e.g., `specs/<feature>/review.md`) or your preferred log so the per-task audit trail remains intact.

## Review Sub-Agent Expectations

Include the following checklist inside the delegation brief:

1. **Findings-first output**:
   - List issues ordered by severity (Critical, High, Medium, Low, Info) with file paths + line numbers.
   - For each issue: describe risk, impacted requirements/RT-IDs/tasks (reference the Task ID when relevant), and remediation guidance.
2. **Testing verification**:
   - Confirm which tests were run (unit/integration/e2e) and whether additional coverage is required.
   - Suggest concrete test additions if gaps exist.
3. **Verdict**:
   - Provide a single-line status: `BLOCK`, `CHANGES REQUESTED`, or `APPROVED`.
   - If APPROVED with nits, enumerate them separately.
4. **Traceability**:
   - Reference spec.md sections, plan.md component IDs, or tasks (T###) when flagging issues.
5. **Handoff**:
   - Summarize outstanding actions for the implementor/user (e.g., “Fix T018 regression test”, “Add RT-204 latency guardrail”).
