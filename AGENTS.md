# AGENTS.md

## About Spec Kit and Specify

**GitHub Spec Kit** is a comprehensive toolkit for implementing Spec-Driven Development (SDD) - a methodology that emphasizes creating clear specifications before implementation. The toolkit includes templates, scripts, and workflows that guide development teams through a structured approach to building software.

**Specify CLI** is the command-line interface that bootstraps projects with the Spec Kit framework. It sets up the necessary directory structures, templates, and AI agent integrations to support the Spec-Driven Development workflow.

The toolkit supports multiple AI coding assistants, allowing teams to use their preferred tools while maintaining consistent project structure and development practices.

---

## General practices

- Any changes to `__init__.py` for the Specify CLI require a version rev in `pyproject.toml` and addition of entries to `CHANGELOG.md`.

## Adding New Agent Support

This section explains how to add support for new AI agents/assistants to the Specify CLI. Use this guide as a reference when integrating new AI tools into the Spec-Driven Development workflow.

### Overview

Specify supports multiple AI agents by generating agent-specific command files and directory structures when initializing projects. Each agent has its own conventions for:

- **Command file formats** (Markdown, TOML, etc.)
- **Directory structures** (`.claude/commands/`, `.windsurf/workflows/`, etc.)
- **Command invocation patterns** (slash commands, CLI tools, etc.)
- **Argument passing conventions** (`$ARGUMENTS`, `{{args}}`, etc.)

### Current Supported Agents

| Agent | Directory | Format | CLI Tool | Description |
|-------|-----------|---------|----------|-------------|
| **Claude Code** | `.claude/commands/` | Markdown | `claude` | Anthropic's Claude Code CLI |
| **Gemini CLI** | `.gemini/commands/` | TOML | `gemini` | Google's Gemini CLI |
| **GitHub Copilot** | `.github/prompts/` | Markdown | N/A (IDE-based) | GitHub Copilot in VS Code |
| **Cursor** | `.cursor/commands/` | Markdown | `cursor-agent` | Cursor CLI |
| **Qwen Code** | `.qwen/commands/` | TOML | `qwen` | Alibaba's Qwen Code CLI |
| **opencode** | `.opencode/command/` | Markdown | `opencode` | opencode CLI |
| **Codex CLI** | `.codex/commands/` | Markdown | `codex` | Codex CLI |
| **Windsurf** | `.windsurf/workflows/` | Markdown | N/A (IDE-based) | Windsurf IDE workflows |
| **Kilo Code** | `.kilocode/rules/` | Markdown | N/A (IDE-based) | Kilo Code IDE |
| **Auggie CLI** | `.augment/rules/` | Markdown | `auggie` | Auggie CLI |
| **Roo Code** | `.roo/rules/` | Markdown | N/A (IDE-based) | Roo Code IDE |
| **CodeBuddy CLI** | `.codebuddy/commands/` | Markdown | `codebuddy` | CodeBuddy CLI |
| **Amazon Q Developer CLI** | `.amazonq/prompts/` | Markdown | `q` | Amazon Q Developer CLI |

### Step-by-Step Integration Guide

Follow these steps to add a new agent (using a hypothetical new agent as an example):

#### 1. Add to AGENT_CONFIG

**IMPORTANT**: Use the actual CLI tool name as the key, not a shortened version.

Add the new agent to the `AGENT_CONFIG` dictionary in `src/specify_cli/__init__.py`. This is the **single source of truth** for all agent metadata:

```python
AGENT_CONFIG = {
    # ... existing agents ...
    "new-agent-cli": {  # Use the ACTUAL CLI tool name (what users type in terminal)
        "name": "New Agent Display Name",
        "folder": ".newagent/",  # Directory for agent files
        "install_url": "https://example.com/install",  # URL for installation docs (or None if IDE-based)
        "requires_cli": True,  # True if CLI tool required, False for IDE-based agents
    },
}
```

**Key Design Principle**: The dictionary key should match the actual executable name that users install. For example:
- ✅ Use `"cursor-agent"` because the CLI tool is literally called `cursor-agent`
- ❌ Don't use `"cursor"` as a shortcut if the tool is `cursor-agent`

This eliminates the need for special-case mappings throughout the codebase.

**Field Explanations**:
- `name`: Human-readable display name shown to users
- `folder`: Directory where agent-specific files are stored (relative to project root)
- `install_url`: Installation documentation URL (set to `None` for IDE-based agents)
- `requires_cli`: Whether the agent requires a CLI tool check during initialization

#### 2. Update CLI Help Text

Update the `--ai` parameter help text in the `init()` command to include the new agent:

```python
ai_assistant: str = typer.Option(None, "--ai", help="AI assistant to use: claude, gemini, copilot, cursor-agent, qwen, opencode, codex, windsurf, kilocode, auggie, codebuddy, new-agent-cli, or q"),
```

Also update any function docstrings, examples, and error messages that list available agents.

#### 3. Update README Documentation

Update the **Supported AI Agents** section in `README.md` to include the new agent:

- Add the new agent to the table with appropriate support level (Full/Partial)
- Include the agent's official website link
- Add any relevant notes about the agent's implementation
- Ensure the table formatting remains aligned and consistent

#### 4. Update Release Package Script

Modify `.github/workflows/scripts/create-release-packages.sh`:

##### Add to ALL_AGENTS array:
```bash
ALL_AGENTS=(claude gemini copilot cursor-agent qwen opencode windsurf q)
```

##### Add case statement for directory structure:
```bash
case $agent in
  # ... existing cases ...
  windsurf)
    mkdir -p "$base_dir/.windsurf/workflows"
    generate_commands windsurf md "\$ARGUMENTS" "$base_dir/.windsurf/workflows" "$script" ;;
esac
```

#### 4. Update GitHub Release Script

Modify `.github/workflows/scripts/create-github-release.sh` to include the new agent's packages:

```bash
gh release create "$VERSION" \
  # ... existing packages ...
  .genreleases/spec-kit-template-windsurf-sh-"$VERSION".zip \
  .genreleases/spec-kit-template-windsurf-ps-"$VERSION".zip \
  # Add new agent packages here
```

#### 5. Update Agent Context Scripts

##### Bash script (`scripts/bash/update-agent-context.sh`):

Add file variable:
```bash
WINDSURF_FILE="$REPO_ROOT/.windsurf/rules/specify-rules.md"
```

Add to case statement:
```bash
case "$AGENT_TYPE" in
  # ... existing cases ...
  windsurf) update_agent_file "$WINDSURF_FILE" "Windsurf" ;;
  "") 
    # ... existing checks ...
    [ -f "$WINDSURF_FILE" ] && update_agent_file "$WINDSURF_FILE" "Windsurf";
    # Update default creation condition
    ;;
esac
```

##### PowerShell script (`scripts/powershell/update-agent-context.ps1`):

Add file variable:
```powershell
$windsurfFile = Join-Path $repoRoot '.windsurf/rules/specify-rules.md'
```

Add to switch statement:
```powershell
switch ($AgentType) {
    # ... existing cases ...
    'windsurf' { Update-AgentFile $windsurfFile 'Windsurf' }
    '' {
        foreach ($pair in @(
            # ... existing pairs ...
            @{file=$windsurfFile; name='Windsurf'}
        )) {
            if (Test-Path $pair.file) { Update-AgentFile $pair.file $pair.name }
        }
        # Update default creation condition
    }
}
```

#### 6. Update CLI Tool Checks (Optional)

For agents that require CLI tools, add checks in the `check()` command and agent validation:

```python
# In check() command
tracker.add("windsurf", "Windsurf IDE (optional)")
windsurf_ok = check_tool_for_tracker("windsurf", "https://windsurf.com/", tracker)

# In init validation (only if CLI tool required)
elif selected_ai == "windsurf":
    if not check_tool("windsurf", "Install from: https://windsurf.com/"):
        console.print("[red]Error:[/red] Windsurf CLI is required for Windsurf projects")
        agent_tool_missing = True
```

**Note**: CLI tool checks are now handled automatically based on the `requires_cli` field in AGENT_CONFIG. No additional code changes needed in the `check()` or `init()` commands - they automatically loop through AGENT_CONFIG and check tools as needed.

## Important Design Decisions

### Using Actual CLI Tool Names as Keys

**CRITICAL**: When adding a new agent to AGENT_CONFIG, always use the **actual executable name** as the dictionary key, not a shortened or convenient version.

**Why this matters:**
- The `check_tool()` function uses `shutil.which(tool)` to find executables in the system PATH
- If the key doesn't match the actual CLI tool name, you'll need special-case mappings throughout the codebase
- This creates unnecessary complexity and maintenance burden

**Example - The Cursor Lesson:**

❌ **Wrong approach** (requires special-case mapping):
```python
AGENT_CONFIG = {
    "cursor": {  # Shorthand that doesn't match the actual tool
        "name": "Cursor",
        # ...
    }
}

# Then you need special cases everywhere:
cli_tool = agent_key
if agent_key == "cursor":
    cli_tool = "cursor-agent"  # Map to the real tool name
```

✅ **Correct approach** (no mapping needed):
```python
AGENT_CONFIG = {
    "cursor-agent": {  # Matches the actual executable name
        "name": "Cursor",
        # ...
    }
}

# No special cases needed - just use agent_key directly!
```

**Benefits of this approach:**
- Eliminates special-case logic scattered throughout the codebase
- Makes the code more maintainable and easier to understand
- Reduces the chance of bugs when adding new agents
- Tool checking "just works" without additional mappings

## Agent Categories

### CLI-Based Agents

Require a command-line tool to be installed:
- **Claude Code**: `claude` CLI
- **Gemini CLI**: `gemini` CLI  
- **Cursor**: `cursor-agent` CLI
- **Qwen Code**: `qwen` CLI
- **opencode**: `opencode` CLI
- **CodeBuddy CLI**: `codebuddy` CLI

### IDE-Based Agents
Work within integrated development environments:
- **GitHub Copilot**: Built into VS Code/compatible editors
- **Windsurf**: Built into Windsurf IDE

## Command File Formats

### Markdown Format
Used by: Claude, Cursor, opencode, Windsurf, Amazon Q Developer

```markdown
---
description: "Command description"
---

Command content with {SCRIPT} and $ARGUMENTS placeholders.
```

### TOML Format
Used by: Gemini, Qwen

```toml
description = "Command description"

prompt = """
Command content with {SCRIPT} and {{args}} placeholders.
"""
```

## Directory Conventions

- **CLI agents**: Usually `.<agent-name>/commands/`
- **IDE agents**: Follow IDE-specific patterns:
  - Copilot: `.github/prompts/`
  - Cursor: `.cursor/commands/`
  - Windsurf: `.windsurf/workflows/`

## Argument Patterns

Different agents use different argument placeholders:
- **Markdown/prompt-based**: `$ARGUMENTS`
- **TOML-based**: `{{args}}`
- **Script placeholders**: `{SCRIPT}` (replaced with actual script path)
- **Agent placeholders**: `__AGENT__` (replaced with agent name)

## Testing New Agent Integration

1. **Build test**: Run package creation script locally
2. **CLI test**: Test `specify init --ai <agent>` command
3. **File generation**: Verify correct directory structure and files
4. **Command validation**: Ensure generated commands work with the agent
5. **Context update**: Test agent context update scripts

## Common Pitfalls

1. **Using shorthand keys instead of actual CLI tool names**: Always use the actual executable name as the AGENT_CONFIG key (e.g., `"cursor-agent"` not `"cursor"`). This prevents the need for special-case mappings throughout the codebase.
2. **Forgetting update scripts**: Both bash and PowerShell scripts must be updated when adding new agents.
3. **Incorrect `requires_cli` value**: Set to `True` only for agents that actually have CLI tools to check; set to `False` for IDE-based agents.
4. **Wrong argument format**: Use correct placeholder format for each agent type (`$ARGUMENTS` for Markdown, `{{args}}` for TOML).
5. **Directory naming**: Follow agent-specific conventions exactly (check existing agents for patterns).
6. **Help text inconsistency**: Update all user-facing text consistently (help strings, docstrings, README, error messages).

## Future Considerations

When adding new agents:

- Consider the agent's native command/workflow patterns
- Ensure compatibility with the Spec-Driven Development process
- Document any special requirements or limitations
- Update this guide with lessons learned
- Verify the actual CLI tool name before adding to AGENT_CONFIG

---

*This documentation should be updated whenever new agents are added to maintain accuracy and completeness.*

## Codex-Centric SDD Flow (Conversation + Sub-Agent Implementor)

### Mission
Use Codex as the conversational partner to guide all Spec‑Driven Development phases up to implementation. When tasks are ready, hand off to a dedicated sub‑agent implementor that executes tasks.md under strict contracts and escalates any ambiguity instead of guessing.

### Operating Principles
- Specs are the source of truth; code is their output.
- Zero ambiguity at phase gates (Definition of Ready for Spec, Plan, Tasks).
- Deep research grounds decisions with citations and recency checks.
- UI follows modern SaaS best practices with variation allowed (anchors: Linear, Stripe, Figma); design system and libraries are chosen in Plan after research and pinned with versions and rationale.
- Implementor must not invent defaults or components; any gap → BLOCKED and escalated.

### Workflow and Artifacts

Commands map to templates and DOR gates:

| Command | Template | Key Outputs | Gate (DOR) |
|---------|----------|-------------|------------|
| /speckit.constitution | constitution.md | .specify/memory/constitution.md | Principles set |
| /speckit.specify | spec-template.md | specs/<feature>/spec.md (incl. Clarifications, Assumptions, UX Intent, Microcopy) | No banned phrases; measurable SCs; edge cases listed |
| /speckit.clarify | clarify guide | Updates spec.md (Clarifications Resolved) | All critical [NEEDS CLARIFICATION] resolved |
| /speckit.plan | plan-template.md + research-template.md | plan.md, research.md, data-model.md, contracts/, quickstart.md | Library decision pinned; tokens, component map 100% coverage; interaction contracts; evidence links (RT-IDs) |
| /speckit.tasks | tasks-template.md | tasks.md (Agent Execution Contract, Traceability Summary) | Format compliance; traceability complete |
| /speckit.checklist | checklist-template.md | checklists/* | Ambiguity lint, UI coverage, research freshness |
| /speckit.analyze | analyze guide | Analysis report | All gates PASS → Ready |
| /speckit.review | review.md | Review findings report (severity ordered) | All blocking issues resolved or waived |

### Conversation with Codex (Designer Role)
- Lead each phase with a short synthesis and ≤5 decisive questions.
- Record answers in spec.md Clarifications (Resolved); move assumptions to research for validation.
- Keep stack undecided until Plan; choose via Decision Matrix using research evidence.

### Research Policy
- Perform live web research with authoritative sources; prefer citations ≤6 months old.
- Build a Design Reference Gallery (8–15 examples) starting with: Linear, Stripe, Figma; allow visual variation while enforcing a11y and performance budgets.
- Maintain Evidence‑to‑Decision mapping (RT‑IDs) and pin final decisions in Plan.

#### Delegated Research (Perplexity MCP)
- Use the Perplexity MCP server (`mcp__perplexity__perplexity_search`) for every high-impact Branch Map fork that requires external data.
- Wrap each query in a short brief (fork ID, question, success criteria) and record RT-IDs plus citations in `research.md`.
- Minimum deliverables per research run:
  - Source list with URLs and publication dates
  - 3–5 key insights mapped back to decision points
  - Recommendation + confidence level
- Escalate via `/speckit.clarify` if Perplexity results fail recency/authority checks.

### Implementor Sub‑Agent (Tasks Executor)
Input: tasks.md, plan.md, research.md, data-model.md, contracts/, quickstart.md.

Contract (must follow, no autonomy):
- Allowed: Only libraries and versions pinned in plan.md.
- Forbidden: Creating custom UI when a library equivalent exists; changing stack/versions; inventing defaults.
- Escalation: Any missing plan/spec detail, unmapped UI element, or blocked dependency → mark BLOCKED and prompt for clarification.
- Execution: Follow exact file paths; respect parallel markers [P]; adhere to TDD instructions when present.
- Reporting: Emit JSON status per task (DONE|BLOCKED|FAILED|SKIPPED); stop on first BLOCKED and request waiver/clarification.
- Hygiene: Update tasks.md checkboxes on completion; do not modify spec/plan without an approved change.

Handoff: Place implementor guidance in `agents/codex/agents.md` (recommended). This file should restate the Agent Execution Contract and reporting format.

### Sub-Agent Orchestration

| Phase | Trigger | Delegation Target | Required Outputs |
|-------|---------|-------------------|------------------|
| Research | Branch Map forks with open questions | `research` sub-agent (Perplexity MCP) | RT-IDs, citations, recommendation summary |
| Implementation | `/speckit.implement` kickoff | `implementor` sub-agent (`agents/codex/agents.md`) | Task JSON logs, updated `tasks.md` checkboxes |
| Review | After implementor finishes or when diff exists | `review` sub-agent (`agents/review.md`) | Findings-first report (issues ordered by severity) |

- Use `mcp__subagents__delegate` with `agent: "research"` for Perplexity-backed runs, `agent: "implementor"` for task execution, and `agent: "review"` for mandatory code review.
- Each delegation must specify `cwd`, sandbox mode, approval policy, and whether to mirror the repo (implementor typically `mirror_repo=true` to keep git metadata; research and review can stay read-only).
- Conversation Codex thread remains the coordinator: summarize incoming artifacts, decide next command (`/speckit.*`), and surface review findings to the human before accepting changes.
- Reference personas live in `.codex/agents/*.md`, with `.codex/scripts/run-subagents.sh` + `.codex/config.toml` auto-wired by the release script so Codex CLI can launch the MCP sub-agent server out of the box.

- Applicable scenarios:
  - **Full-stack build**: run the entire Spec → Plan → Tasks pipeline, then delegate implementation and review.
  - **Refactor / bug fix**: document the delta in `spec.md`, run targeted research if external behavior changes, then delegate implementation + review.
  - **Precise edit / hotfix**: even for single-file edits, Codex must hand work to the implementor (respecting tasks scope) and finish with a review report before merge.

### UI/UX Requirements (Plan-Level)
- Visual tokens: colors, typography, spacing, radii, shadows, motion, breakpoints.
- Component Map: 100% of UI mapped to library components/variants.
- Interaction Contracts: event → state → API → feedback; latency and error budgets; WCAG 2.2 AA.
- Variation allowed per feature; stay consistent with modern SaaS patterns.

### Export & Readiness
Ready for implementor when:
- Spec DOR, Plan DOR, Tasks DOR all PASS
- Research completed with citations and RT‑IDs
- Analyze report shows no CRITICAL/HIGH issues

Bundle should include: specs/<feature>/* and (optionally) agents/codex/agents.md.

### Starting and Handoff Prompts
- Start: “/speckit.constitution …” then “/speckit.specify …”
- Handoff: “/speckit.implement” to spawn the implementor sub‑agent following tasks.md under the Agent Execution Contract.
- Close: “/speckit.review” (or manual delegate call) to run the review sub-agent once implementation tasks complete; block shipping until findings are resolved or explicitly waived.
