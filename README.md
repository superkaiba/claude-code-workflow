# claude-code-workflow

A reusable Claude Code agentic research workflow template. Drop the `.claude/`
directory and `CLAUDE.md` into a research repo and you get an opinionated,
adversarial-review-driven lifecycle for ML / AI-safety experiments —
GitHub-issue-backed, with named agent roles, named skills, and a state
machine that runs from "proposed idea" to "published clean result."

## What's inside

```
.claude/
  agents/    # 13 agent role definitions (planner, critic, analyzer, reviewer,
             # consistency-checker, experimenter, experiment-implementer,
             # implementer, code-reviewer, interpretation-critic, upload-verifier,
             # follow-up-proposer, retrospective)
  skills/    # 15 skills / playbooks (issue, adversarial-planner, clean-results,
             # paper-plots, ideation, daily, weekly, experiment-runner,
             # auto-experiment-runner, experiment-proposer, codebase-debugger,
             # cleanup, refactor, independent-reviewer)
  rules/     # Project conventions (agents-vs-skills, research-project-structure,
             # arxiv-mcp)
  settings.json  # Permissions + Pre/PostToolUse hooks (generic placeholders)
  mcp.json       # arxiv + arxiv-latex MCP servers
CLAUDE.md    # Top-level project instructions consumed by Claude Code
```

## How the lifecycle works

Every experiment is a GitHub issue carrying its state in a `status:*` label:

```
proposed → planning → plan-pending → approved → implementing → code-reviewing
       → running → uploading → interpreting → reviewing → awaiting-promotion
       → done-experiment / done-impl
```

The `/issue <N>` skill is the single execution path. It dispatches the right
agent for the issue's current label, parses structured `<!-- epm:* -->`
markers from issue comments to track substate, and only pauses for user
input at six explicit gates (see `CLAUDE.md` → "Auto-continuation policy").

Inside `/issue`, plans are produced by `planner` and stress-tested by `critic`
+ `consistency-checker` (the `/adversarial-planner` skill), code is written
by `experiment-implementer` / `implementer` and reviewed by `code-reviewer`
in up-to-3 iteration rounds, experiments run via `experimenter` against a
compute target you provide, results are gated through `upload-verifier`,
interpreted by `analyzer` and stress-tested by `interpretation-critic`, and
finally the clean-result issue is reviewed by `reviewer` before promotion.

## Drop-in usage

1. Copy `.claude/` and `CLAUDE.md` into the root of your research repo.
2. Fill in the `TODO:` placeholders in `CLAUDE.md` (project overview,
   directory structure, common commands, compute-target lifecycle).
3. Adjust placeholder paths in skill files where they reference your
   project's analysis helpers, verifier scripts, or pod / compute CLI.
4. Set up a GitHub project board with the `status:*` labels listed above
   and (optionally) a workflow that auto-adds new issues to it.
5. Wire up your results store (e.g. WandB) and artifact store (e.g. HF Hub
   or S3) — the workflow doesn't care which, but the agents reference
   "results store" / "artifact store" abstractly.
6. From your repo, invoke `/issue <N>` to drive any single issue end-to-end,
   or use the broader skills (`/ideation`, `/experiment-proposer`, `/daily`,
   `/weekly`) for cross-experiment orchestration.

## Assumptions the workflow makes

- You have a GitHub repo and use `gh` for issues / PRs.
- You have an experiment queue project board with `status:*` labels.
- You have *some* compute target — local box, managed cluster, or
  ephemeral cloud pod — reachable by SSH or the equivalent.
- You use `uv` for Python env management and `ruff` for lint.
- You upload eval JSON to a results store and model artifacts to an
  artifact store before deleting them locally.
- `nohup` is acceptable on your compute target for surviving parent-session
  disconnect.

## Source

Original lineage: <https://github.com/superkaiba/explore-persona-space>.
The agents, skills, and rule files were extracted from that project, where
they evolved over many real research cycles. The project-specific details
(domain, hardware, storage hosts, experiment matrix) have been stripped;
the architecture (state machine, marker schema, agent roster) is intact.
