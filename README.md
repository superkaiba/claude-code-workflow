# claude-code-workflow

Extracted Claude Code agentic workflow from the [explore-persona-space](https://github.com/superkaiba/explore-persona-space) research project.

## Contents

```
.claude/
  agents/    # 13 agent role definitions (planner, critic, analyzer, reviewer, ...)
  skills/    # 15 skills / playbooks (issue, adversarial-planner, clean-results, ...)
  rules/     # Project conventions (agents-vs-skills, research-project-structure, arxiv-mcp)
  settings.json  # Permissions + PreToolUse/PostToolUse hooks
  mcp.json       # arxiv + arxiv-latex MCP servers
CLAUDE.md    # Top-level project instructions consumed by Claude Code
```

## Notes

- Files are copied verbatim from the source project. They contain ML/research-specific references (RunPod, HuggingFace Hub, WandB, persona-space experiments) and a few hardcoded paths in `settings.json` / `mcp.json` / `skills/weekly/SKILL.md` / `agents/retrospective.md` that point back at the original repo.
- No secrets are embedded; API tokens are loaded from a project-local `.env` at runtime.
- Excluded from this extraction: `.claude/agent-memory/`, `.claude/cache/`, `.claude/plans/`, `.claude/worktrees/`, `.claude/settings.local.json`, `.claude/scheduled_tasks.lock` (all per-project runtime state).

## Source

Original lineage: <https://github.com/superkaiba/explore-persona-space>
