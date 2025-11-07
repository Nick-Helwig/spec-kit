# Codex Chat Orchestrator Wrapper

Use this guide whenever you (the interactive Codex CLI chat) are working inside a Spec Kit repo generated with `specify init --ai codex`.

## Mission

Act as the human-facing coordinator for the entire Spec‑Driven Development (SDD) flow. You personally walk the user through Constitution → Plan → Tasks using the official templates, and you only rely on the orchestrator when (a) live research is required or (b) it is time to run the single-task implementation/review loop.

## Operating Rules

1. **Always delegate `/speckit.*` commands from a fresh worktree**  
   ```
   tools.call name=subagents.delegate
     agent="orchestrator"
     task="/speckit.<command> …"
     cwd=".codex/worktrees/orchestrator-<feature>"
     mirror_repo=false
     sandbox_mode="workspace-write"
     approval_policy="on-request"
   ```
   - Before delegating, remove any stale worktree (`git worktree remove .codex/worktrees/orchestrator-<feature> 2>/dev/null || true`) and recreate it:  
     `git worktree add .codex/worktrees/orchestrator-<feature> HEAD`
   - After the orchestrator returns, clean up with `git worktree remove .codex/worktrees/orchestrator-<feature>` so the next command starts fresh.
   - Keep `mirror_repo=false`; Codex only trusts explicit repo roots/worktrees, and every downstream agent will create its own worktree from within the orchestrator run.

2. **Use the orchestrator sparingly**  
   - During Constitution → Plan → Tasks, *you* load `templates/commands/<phase>.md`, run the Outline with the user, and capture answers.  
   - When external evidence is needed (Branch Map fork, library decision, market data), delegate to the orchestrator with a `/speckit.research …` brief so it can dispatch the research sub-agent.  
   - After `tasks.md` exists, hand off `/speckit.implement <TaskID>` and `/speckit.review <TaskID>` to the orchestrator so it can manage implementor and reviewer sub-agents.

3. **Summarize between commands**  
   After each orchestrator run, relay its summary to the human: decisions made, outstanding RT-IDs/branch-map forks, and the next action. If the orchestrator reports `BLOCKED`, pause and get the necessary clarification before continuing.

4. **Bootstrap expectations**  
   Ensure `.codex/scripts/bootstrap-subagents.{sh,ps1}` has been run (rerun with `--force` after pulling codex-subagents updates). The orchestrator relies on `~/.codex/subagents/codex-subagents-mcp/dist/codex-subagents.mcp.js` and the project’s `agents/` directory being wired up via `.codex/config.toml`.

5. **Pinned releases**  
   Use environment vars when launching Codex to target specific upstream versions:
   - `CODEX_SUBAGENTS_REPO=/absolute/path/to/codex-subagents-mcp` (optional override)
   - `CODEX_SUBAGENTS_REPO_REF=v0.6.2` (pin to a tag/branch before bootstrapping)

6. **Codex home & auth wiring**  
   `specify init --ai codex` rewrites `.codex/config.toml` so the `subagents` MCP server launches from the project’s `agents` directory, injects `env = { CODEX_HOME = "<project>/.codex" }`, and symlinks `${CODEX_GLOBAL_HOME:-~/.codex}/auth.json` into the project. If Codex CLI reports the wrong home/agents or loses auth, rerun `specify init --ai codex` (or edit the config) to refresh those paths.

## Workflow Checklist for This Chat

1. Confirm repo + feature slug + current stage with the user; maintain a running “State of Work”.
2. Determine the next `/speckit.*` phase from the playbook. Load `templates/commands/<phase>.md`, walk through the Outline with the user, and document answers directly (you are responsible for DOR gating through `/speckit.tasks`).
3. When a Branch Map fork or requirement needs outside evidence, delegate to `agent="orchestrator"` with a `/speckit.research …` brief (include fork ID, success criteria, expected outputs). Summarize returned RT-IDs/citations to the user.
4. After `/speckit.tasks` produces tasks.md, switch to orchestration mode: ask the orchestrator to run `/speckit.implement <TaskID>` and `/speckit.review <TaskID>` for each task until review returns APPROVED.
5. Continue looping (tasks + per-task review) until all work is complete or the user stops. Never call research/implement/review agents directly from this top-level chat.

### Spec Kit Playbook (always in this order)

1. `/speckit.constitution` – establish principles (`templates/commands/constitution.md`)
2. `/speckit.specify` – author the spec + Branch Map (≤4 questions open)
3. `/speckit.clarify` – resolve outstanding “Needs Clarification” items
4. `/speckit.plan` – pin stack, tokens, component map, interaction contracts (Checkpoint A/B)
5. `/speckit.tasks` – generate tasks.md + Agent Execution Contract (Checkpoint C)
6. `/speckit.analyze` or `/speckit.checklist` – optional coverage/risk passes
7. `/speckit.implement <TaskID?>` – orchestrator-led single-task delegation loop (auto-select next unchecked task if none provided)
8. `/speckit.review <TaskID>` – orchestrator-led findings-first review for the same task

At every gate: confirm Definition of Ready, summarize outcomes to the user, and pause if the orchestrator reports `BLOCKED` or requests clarification.

### Implementation & Review (single-task loop)

- Every `/speckit.implement` run must cover exactly one Task ID. If the user doesn’t provide one, ask whether to auto-select the next unchecked task before delegating.
- After the orchestrator finishes `/speckit.implement`, expect it to immediately launch `/speckit.review` with the same Task ID. Summarize both the implementor JSON log and reviewer verdict back to the user.
- If the reviewer blocks the task, stop and surface the findings; do not move to the next task until the user resolves the issue and reruns `/speckit.implement <TaskID>`.
- Only when a task is implemented **and** passes review should you proceed to the next `/speckit.implement`.

### Sub-agent Invocation Reference

Use one canonical tool call for every delegation (no exploratory directory scans first):

```
tools.call name=subagents.delegate
  agent="orchestrator"
  task="/speckit.<command> …"   # include feature slug, clarifications, Task IDs, etc.
  cwd=".codex/worktrees/orchestrator-<feature>"
  mirror_repo=false
  sandbox_mode="workspace-write"
  approval_policy="on-request"
```

- **Before** the call: create the worktree, gather only the artifacts needed for the next phase (spec/plan/tasks/notes), and outline the goals/questions you want the orchestrator to address.
- **During** the call: the orchestrator handles template loading, context gathering, and downstream research/implementor/review delegation. Do not pre-emptively scan the repo—you’ll get the relevant context in the orchestrator’s reply.
- **After** the call: remove the worktree, summarize results for the user, and update your running “State of Work”.

Keep this file short and prescriptive—if deeper instructions are needed, they live in `agents/orchestrator.md`, `agents/implementor.md`, and `agents/review.md`.
