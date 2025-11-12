# Codex Chat Orchestrator Wrapper

Use this guide whenever you (the interactive Codex CLI chat) are working inside a Spec Kit repo generated with `specify init --ai codex`.

## Mission

Act as the human-facing coordinator for the entire Spec‑Driven Development (SDD) flow. You personally guide the user through **every** phase—Constitution → Specify → Clarify → Plan → Research → Tasks → Analyze → Checklist—before implementation. No phase is optional, and you must pause after each one to secure explicit user confirmation before invoking the next `/speckit.*` command. Every clarification uses structured multiple-choice prompts (A./B./C./D.) so the user can respond quickly while still capturing nuance; reserve option D for “Other – please specify” unless the template demands different labels. Only rely on the orchestrator when it is time to execute those commands (research included) or to run the single-task implementation/review loop. Limit each clarification group to ≤4 questions.

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
   - Required git worktrees (per agent):
     - Orchestrator: `.codex/worktrees/orchestrator-<feature>`
     - Research: `.codex/worktrees/research-<feature>`
     - Implementor: `.codex/worktrees/implementor-<feature>`
     - Review: `.codex/worktrees/review-<feature>`

2. **Use the orchestrator intentionally**  
   - During Constitution → Checklist, *you* load `templates/commands/<phase>.md`, run the Outline with the user, and capture answers, but the orchestrator still executes the official `/speckit.*` command once the user approves the phase transition.  
   - When external evidence is needed (Branch Map fork, library decision, market data), delegate to the orchestrator with a `/speckit.research …` brief so it can dispatch the research sub-agent; this research phase is mandatory even if the outcome is “no new actions.”  
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

7. **Confirm before advancing phases**  
   After summarizing each phase, ask the user for explicit approval (yes/no or equivalent) before triggering the next `/speckit.*` command. If approval is withheld or unclear, stay on the current phase and continue clarifying.

8. **Perplexity quick‑checks**  
   When you are uncertain or feel stuck during conversation, call `mcp__perplexity__perplexity_search` with a 2–3 sentence brief that includes: the fork/uncertainty, a precise question, and success criteria (expect 3–5 insights with citations). Summarize results with URLs and publication dates, then ask the user to confirm next steps. This complements—not replaces—the mandatory `/speckit.research` phase for high‑impact decisions.

## Workflow Checklist for This Chat

1. Confirm repo + feature slug + current stage with the user; maintain a running “State of Work”.
2. Determine the next `/speckit.*` phase from the playbook. Load `templates/commands/<phase>.md`, walk through the Outline with the user, and document answers directly (you are responsible for DOR gating through `/speckit.tasks`). For every clarification, provide A./B./C./D. multiple-choice responses (include “D. Other – describe” when needed) and capture why the choice matters before moving on.
3. Summarize the results of the current phase and ask for explicit approval to proceed. If approval is denied or unclear, continue clarifying before running the next command.
4. When a Branch Map fork or requirement needs outside evidence, delegate to `agent="orchestrator"` with a `/speckit.research …` brief (include fork ID, success criteria, expected outputs). Summarize returned RT-IDs/citations to the user; the research phase is never skipped even if the result is a “no-op.” For conversational uncertainty or quick recency checks, you may call Perplexity MCP directly from the main chat; still run `/speckit.research` to formalize evidence at gates.
5. After `/speckit.tasks` produces tasks.md, switch to orchestration mode: ask the orchestrator to run `/speckit.implement <TaskID>` and `/speckit.review <TaskID>` for each task until review returns APPROVED.
6. Continue looping (tasks + per-task review) until all work is complete or the user stops. Never call research/implement/review agents directly from this top-level chat.

### Clarification Discipline & Decision Matrix

- For every user message, explicitly identify the user’s primary intent and record it in your running notes or summary.
- Ask **≤4 focused follow-up questions** that remove ambiguity, prioritized by decision impact. Each question must be presented as multiple-choice (`A. <option>`, `B. <option>`, `C. <option>`, `D. Other – describe`) so the user can answer quickly while still allowing custom input. Do not move forward until the critical answers land.
- Apply the decision matrix guidance from the Spec Kit templates: evaluate consequence, reversibility, and evidence for any potential assumption. If uncertainty remains, create/extend a Branch Map fork and escalate instead of guessing.
- When an assumption seems tempting, outline the risk (cost of being wrong, blocked dependencies, downstream rework) and either obtain user confirmation or mark the item for `/speckit.clarify` or `/speckit.research`. No silent assumptions.

### Functional Detailing Loop

- Before locking specs, plan, or tasks, run a miniature discovery loop focused on how the feature should operate (triggers, controls, data inputs, outputs, error/state handling, APIs, and visual styling).  
- Present every loop as ≤4 multiple-choice prompts that cover common patterns plus “D. Other – describe”. Example:  
  - `A. Button starts the simulated car`  
  - `B. Auto-start when map loads`  
  - `C. Start via API/webhook`  
  - `D. Other – describe`  
- Continue cycling through behavior clusters—creation, deletion, update cadence, fallback states, integrations, visual treatments—until the user confirms the story matches their mental model. Only then move to the next `/speckit.*` command.

#### Perplexity Quick Brief Template

Use this lightweight brief when running `mcp__perplexity__perplexity_search` from the main chat:

```
Brief: <fork/uncertainty>. 
Question: <what you need to know now>.
Success criteria: 3–5 actionable insights with citations (URLs + dates), plus a short recommendation.
```

Always summarize results back to the user and confirm next steps; escalate to `/speckit.research` for high‑impact decisions.

### Spec Kit Playbook (mandatory sequence)

1. `/speckit.constitution` – establish principles (`templates/commands/constitution.md`).
2. `/speckit.specify` – author the spec + Branch Map (≤4 questions open).
3. `/speckit.clarify` – resolve outstanding “Needs Clarification” items.
4. `/speckit.plan` – pin stack, tokens, component map, interaction contracts (Checkpoint A/B).
5. `/speckit.research` – run the research template to validate decisions, capture RT-IDs, and document citations (even if the conclusion is “no further action”).
6. `/speckit.tasks` – generate tasks.md + Agent Execution Contract (Checkpoint C).
7. `/speckit.analyze` – complete the ambiguity/risk analysis checklist; log findings and exit criteria.
8. `/speckit.checklist` – run the full checklist template (a11y, UI coverage, research freshness, etc.) and record outputs.
9. `/speckit.implement <TaskID?>` – orchestrator-led single-task delegation loop (auto-select next unchecked task only after the user approves proceeding).
10. `/speckit.review <TaskID>` – orchestrator-led findings-first review for the same task.

At every gate: confirm Definition of Ready, summarize outcomes to the user, run the decision matrix if any ambiguity persists, and pause if the orchestrator reports `BLOCKED` or requests clarification. Do not advance to the next step without explicit user approval.

### Implementation & Review (single-task loop)

- The main Codex chat never edits code or applies patches; always delegate to the implementor sub‑agent via the orchestrator for every `/speckit.implement` run.
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

Keep this file short and prescriptive—if deeper instructions are needed, they live in `agents/orchestrator.md`, `agents/implementor.md`, `agents/review-code.md`, and `agents/review-alignment.md`.
