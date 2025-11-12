---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
scripts:
  sh: scripts/bash/setup-plan.sh --json
  ps: scripts/powershell/setup-plan.ps1 -Json
agent_scripts:
  sh: scripts/bash/update-agent-context.sh __AGENT__
  ps: scripts/powershell/update-agent-context.ps1 -AgentType __AGENT__
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `{SCRIPT}` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow with gated checkpoints**:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - **Phase 0 (Research Pass)**:
     - For every high-impact Branch Map fork, delegate research to the `research` sub-agent (Perplexity MCP) by calling `mcp__subagents__delegate` with `agent: "research"`, `sandbox_mode: "read-only"`, and a concise brief (fork ID, question, success criteria, RT-ID placeholder). Expect Perplexity-sourced citations ≤6 months old.
     - Build a Branch Map of technical forks (frameworks, hosting model, auth strategies, data stores, etc.). Rank each fork by Impact × Uncertainty.
     - Spend a Question Budget (≤ 4) on the highest-ranked forks and capture responses. Record any remaining high-impact forks as unresolved clarifications—do not self-resolve them.
     - Generate `research.md` via `templates/research-template.md`, ensuring Design Reference Gallery, Library/Stack analysis, Domain validation, and RT-IDs are documented. Explicitly list unresolved forks at the end.
     - **Checkpoint A**: Summarize findings + unresolved forks for the user and pause execution until they respond with `continue`, `revise`, or new clarifications. Abort command if approval is not granted.
   - **Phase 1 (Design & Contracts)**:
     - Proceed only after Checkpoint A approval and after all high-impact forks are answered or explicitly deferred by the user.
     - Populate plan.md, data-model.md, contracts/, quickstart.md using the templates, ensuring every Section DOR item (tokens, component map, interaction contracts, evidence links) is completed.
     - Run the agent context update scripts only after presenting the drafted plan summary to the user.
     - **Checkpoint B**: Present a Branch Map snapshot (covering design tokens, component map coverage, contract scope) plus any remaining assumptions. Wait for user approval before finalizing files or updating agent context. Abort if approval is withheld.
   - Pin final design system/library and versions only after Checkpoint B approval, referencing RT-IDs.
   - Re-evaluate Constitution Check post-design and stop if violations remain unresolved.

4. **Stop and report**: Command ends after all checkpoints are approved. Report branch, IMPL_PLAN path, generated artifacts, and any deferrals.

## Phases

### Phase 0: Outline & Research (Checkpoint A)

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Construct the Branch Map & question plan**:
   - Enumerate smallest forks (e.g., SPA vs MPA, serverless vs container, OAuth vs SAML).
   - Rank forks by Impact × Uncertainty.
   - Spend up to four clarification questions on the highest-ranked forks; capture answers verbatim. Unanswered high-impact forks must be flagged for the user.

3. **Generate and dispatch research agents**:
   ```
   Before delegating, prepare a read-only worktree for research:
   ```bash
   WORKTREE=.codex/worktrees/research-$FEATURE_DIR
   git worktree remove "$WORKTREE" 2>/dev/null || true
   git worktree add "$WORKTREE" HEAD
   ```
   Reuse this path for all research delegates during this plan run and remove it afterward (`git worktree remove "$WORKTREE"`).
   For each high-impact fork or unknown:
     1. Draft a brief (fork ID, question, decision criteria, success metrics, RT-ID placeholder).
     2. Call `mcp__subagents__delegate` with `agent: "research"` (Perplexity MCP backend) and include:
        - `cwd`: `.codex/worktrees/research-$FEATURE_DIR`
        - `sandbox_mode`: "read-only"
        - `task`: the brief above plus required outputs (3–5 insights, citations, recommendation+confidence)
     3. Capture the sub-agent's citations, RT-IDs, and recommendation notes and paste them into `research.md`.
   ```

4. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]
   - Unresolved forks / outstanding clarifications

5. **Checkpoint A**:
   - Summarize key findings, citation highlights, and unresolved forks.
   - Present summary + Branch Map status to the user and wait for approval (`continue`) or revisions.
   - Abort command if approval is denied or new clarifications are issued (rerun `/speckit.specify` or `/speckit.clarify` as directed).

**Output**: research.md plus a user-approved research summary (Checkpoint A).

### Delegated Research Runbook

1. Prioritize forks/questions by Impact × Uncertainty.
2. For each item, assemble:
   - Fork/decision identifier
   - Current assumptions + blockers
   - Desired deliverables (insights list, pros/cons, recommendation, citations)
3. Invoke `mcp__subagents__delegate` (`agent: "research"`, `mirror_repo: false`, `sandbox_mode: "read-only"`, `approval_policy: "on-request"`) using the dedicated worktree (`cwd=.codex/worktrees/research-$FEATURE_DIR`) so the Perplexity-backed agent can perform live web research.
4. Ensure the response includes:
   - RT-ID (traceable back to `research.md`)
   - 3–5 bullet insights tied to cited sources (≤6 months old where possible)
   - Recommendation + confidence level + alternative paths
5. Paste the findings into `research.md`, linking citations inline. If the agent reports insufficient sources, escalate via `/speckit.clarify` instead of guessing.

### Phase 1: Design & Contracts (Checkpoint B)

**Prerequisites:** `research.md` plus Checkpoint A approval; no high-impact forks unresolved unless user explicitly deferred them.

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Draft plan artifacts & seek approval**:
   - Populate plan.md sections (tokens, component map, interaction contracts, Evidence-to-Decision Map). Highlight any assumptions still pending.
   - Prepare data-model.md, contracts/, quickstart.md drafts but do not run agent context scripts yet.
   - Present summary + Branch Map snapshot and outstanding assumptions to the user (**Checkpoint B**). Wait for approval before finalizing files.
   - Upon approval, run `{AGENT_SCRIPT}` to sync agent context, then finalize plan.md, data-model.md, contracts/, quickstart.md.

**Output**: data-model.md, /contracts/*, quickstart.md, plan.md, and updated agent context, each approved via Checkpoint B.

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications

## Definition of Ready — Pre-Tasks Gate

- [ ] research.md complete with Design Gallery, Library/Stack analysis, Domain validation
- [ ] Plan decisions linked to RT-IDs (Evidence-to-Decision Map)
- [ ] Design system/library decision pinned with version and rationale
- [ ] Component Map complete (100% UI mapped to library components)
