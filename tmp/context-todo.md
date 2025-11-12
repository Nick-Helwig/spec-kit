# Spec-Kit Context TODO (Temp)

## Current Findings (2025-02-14)
1. Spec command conflict — **RESOLVED** (2025-02-14): `/speckit.specify` & `templates/spec-template.md` enforce Branch Map + ≤4 question budget; no more auto-assumptions.
2. Planning workflow auto-resolves uncertainties — **RESOLVED** (2025-02-14): `/speckit.plan` uses Checkpoints A/B, Branch Map snapshots, and approval gates captured in `plan.md`.
3. Tasks generation lacks gating — **RESOLVED** (2025-02-14): `/speckit.tasks` now blocks on Plan/Spec DOR, Branch Map clarifications, and Checkpoint C before writing ultra-explicit tasks (mirrored in `tasks.md` template).
4. Implementor escalation unclear — **RESOLVED** (2025-02-14): `agents/orchestrator.md` (“Implementor Delegation Packet” + “Implementor Contract Snapshot”) spells out the BLOCKED workflow plus upstream command mapping.
5. Implementation phase not enforcing checkpoints — **RESOLVED** (2025-02-14): `/speckit.implement` now runs `bash scripts/bash/lint-branchmap.sh <feature>` before touching code, ensuring plan/tasks artifacts include Branch Map + approvals.
6. Codex multi-agent orchestration — **RESOLVED** (2025-02-15): `/speckit.plan`, `/speckit.implement`, and `/speckit.review` templates now instruct the orchestrator to delegate to research (Perplexity), implementor, and two review sub-agents; accompanying docs live in `AGENTS.md`, `agents/orchestrator.md`, `agents/review-code.md`, and `agents/review-alignment.md`.
7. Implementor/Reviewer skill integration — **RESOLVED** (2025-02-15): Embedded the obra/superpowers TDD cycle and error-handling patterns directly into `agents/orchestrator.md`, `agents/implementor.md`, `agents/review-code.md`, and the `/speckit.implement` + `/speckit.review` templates so every delegate enforces those practices.

> **Status:** All known gaps are resolved. Add new items below if future work appears.

## How To Update This File
1. Use `nano tmp/context-todo.md` (or your preferred editor) to append new findings or mark items resolved.
2. When editing via Codex CLI, prefer `apply_patch` for incremental changes so diffs stay readable.
3. Keep entries dated (YYYY-MM-DD) and note whether each item is OPEN, IN PROGRESS, or RESOLVED.
4. If an item is resolved, add a short note referencing the commit or command that fixed it.
5. Share this file with future agents by mentioning `tmp/context-todo.md` so context persists even if chat history resets.
