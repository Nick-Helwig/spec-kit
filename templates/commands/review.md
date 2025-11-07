---
description: Run a findings-first code review using the dedicated review sub-agent after implementation completes.
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
   - Validate that tasks.md reflects the latest implementation (no unchecked tasks remaining unless BLOCKED).

3. **Capture change scope**:
   - Run `git status --short` to list modified files (or use the user-provided path filter from `$ARGUMENTS`).
   - Generate a diff summary via `git diff --stat` (or `git diff <target>` if the user specifies).
   - Note current branch, latest commit hash, and whether tests have been executed since the last commit.

4. **Build the review brief**:
   - Feature slug + branch
   - Summary of implemented stories / tasks
   - List of modified files + high-risk areas (auth, payments, migrations, infra)
   - Testing status (commands run, pass/fail, missing coverage)
   - Outstanding assumptions / waivers carried over from tasks

5. **Delegate to the review sub-agent**:
   - Call `mcp__subagents__delegate` with:
     * `agent`: `"review"`
     * `cwd`: repo root
     * `mirror_repo`: `true`
     * `sandbox_mode`: `"read-only"` (reviewers do not modify code)
     * `approval_policy`: `"on-request"`
     * `task`: the review brief plus explicit reference to the expectations below
   - Provide spec/plan/tasks file paths so the reviewer can cross-reference requirements.

6. **Process review findings**:
   - If the reviewer returns BLOCKED/FAILED or reports Critical/High issues, stop and address them (or document waivers) before merging/deploying.
   - If APPROVED with only Low/Info notes, summarize findings and next steps for the user (e.g., merge, deploy, rerun review after fixes).

7. **Archive**:
   - Record the reviewer’s JSON/markdown report in the feature directory (e.g., `specs/<feature>/review.md`) if your workflow requires traceability.

## Review Sub-Agent Expectations

Include the following checklist inside the delegation brief:

1. **Findings-first output**:
   - List issues ordered by severity (Critical, High, Medium, Low, Info) with file paths + line numbers.
   - For each issue: describe risk, impacted requirements/RT-IDs, and remediation guidance.
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
