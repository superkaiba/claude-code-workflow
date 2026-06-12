# claude-code-workflow

A reusable Claude Code agentic research workflow, extracted June 2026 from a
live ML / AI-safety research project that has run ~600 experiment tasks
through it. Drop the `.claude/` directory, `CLAUDE.md`, `scripts/`, and
`src/research_workflow/` into a research repo and you get an opinionated,
adversarial-review-driven lifecycle that runs from "proposed idea" to
"published clean result" — across multiple parallel, phone-visible Claude
Code sessions, with autonomous crash-recovered execution, a Claude+Codex
review ensemble, and a multi-cloud compute router.

This is the second extraction (the first was May 2026). It reflects the
workflow as actually used: file-based task state (no GitHub-issue control
plane), Happy Coder + tmux session orchestration, autonomous sessions with a
watchdog cron, campaign-level orchestration, and ~45 control-plane scripts.

## What's inside

```
.claude/
  agents/        # 25 agent roles: planner, critic, consistency-checker,
                 # experiment-implementer, experimenter, implementer,
                 # code-reviewer, analyzer, interpretation-critic,
                 # clean-result-critic, methodology-writer, upload-verifier,
                 # uploader, follow-up-proposer, living-docs-updater,
                 # research-pm, reconciler, workflow-improver, retrospective,
                 # + 4 Codex twin reviewers (+ 2 deprecated, kept for history)
  skills/        # 21 skills: issue, issue-tick, adversarial-planner, campaign,
                 # campaign-tick, pm, clean-results (incl. the clean-result
                 # SPEC), promote-clean-result, paper-plots, ideation, daily,
                 # weekly, experiment-runner, auto-experiment-runner,
                 # experiment-proposer, independent-reviewer, cleanup,
                 # refactor, deep-clean, codebase-debugger, mentor-update-slides
  rules/         # 11 rules: workflow-fix-on-bug, agents-vs-skills,
                 # research-project-structure, code-style, gotchas,
                 # upload-policy, arxiv-mcp + 4 domain-specific examples
  workflow.yaml  # the state machine: statuses, marker schemas, gates,
                 # halt criteria, ensemble-review policy
  settings.json  # permissions + hooks (paths use $CLAUDE_PROJECT_DIR)
  mcp.json       # arxiv MCP servers
CLAUDE.md        # top-level project instructions Claude Code loads every session
scripts/         # ~55 control-plane scripts (see below) + 6 placeholder
                 # experiment entrypoints (train.py, eval.py, ... — stubs you
                 # replace with your own pipelines)
src/research_workflow/   # the task-workflow library + compute-backend router
tasks/           # seeded empty task tree (REGISTRY.json) — ready for task.py new
tests/           # 41 test files pinning workflow invariants
```

## Core ideas

### 1. The task tree is the control plane

Every experiment is a folder `tasks/<status>/<N>/` holding `body.md` (YAML
frontmatter + body), `events.jsonl` (append-only progress markers),
`comments.jsonl`, `plans/v{N}.md`, and `artifacts/`. The folder's parent
directory IS the status:

```
proposed → planning → plan_pending → approved → running → verifying →
interpreting → reviewing → awaiting_promotion → completed | blocked | archived
```

All reads/writes go through `scripts/task.py` (CLI) or the importable
`research_workflow.task_workflow` library — atomic `git mv` status changes,
file-locked mutations, one commit per mutation. No HTTP, no tokens, no
GitHub-issue dependency; the git history is the audit log.

### 2. Adversarial review at every stage

- **Plans** (`/adversarial-planner`): planner → fact-checker → critic
  ensemble ∥ consistency-checker → revise → user approval. Every load-bearing
  hyperparameter needs a recorded `Source:`; measurement validity is checked
  per dependent variable.
- **Code**: experiment-implementer paired with an independent code-reviewer
  that never sees the implementer's reasoning.
- **Results**: analyzer ↔ interpretation-critic (content honesty), then
  analyzer ↔ clean-result-critic (15-lens structure/register/statistics gate).
- **Claude + Codex ensemble**: four review sites run a Claude reviewer and an
  OpenAI Codex twin in parallel; disagreements go to a fresh-context
  `reconciler` whose verdict is binding (`scripts/codex_task.py` handles
  dispatch).

### 3. Sessions: Happy Coder + tmux

The workflow runs as **multiple parallel Claude Code sessions on one VM**,
all visible (and drivable) from a phone via
[Happy Coder](https://happy.engineering) (`npm i -g happy-coder`). The Happy
daemon runs each session as a background child — inside tmux when available —
registered with the Happy relay, so sessions survive SSH disconnects and show
up in the mobile app.

- `scripts/spawn_session.py` — the canonical programmatic entry point. Talks
  to the daemon's localhost HTTP RPC (`/spawn-session`, `/list`,
  `/stop-session`; port from `~/.happy/daemon.state.json`):
  - `spawn-pm` — the one PM session (queue triage + dispatch, never executes)
  - `spawn-issue --issue N [--auto]` — per-experiment session; `--auto` boots
    `/issue N` autonomously, auto-approves plans under a GPU-hour cap, and
    registers with the crash-recovery watcher
  - `spawn-campaign --issue N` — campaign session orchestrating child issues
  - `list` / `stop` — enriched live-session view, issue mapping
- `scripts/patch_happy_daemon.py` — surgically patches the vendored Happy
  daemon so its spawn RPC accepts `claudeArgs` (forwarded to the Claude Code
  subprocess in both the tmux and non-tmux spawn paths). This is what lets a
  fresh session boot directly into `/issue 263`. Idempotent, backs up the
  original, `--check` / `--restore` supported.
- `scripts/persona.sh` — open a persistent daemon-spawned session by hand.
- **Autonomous sessions** set `EPM_AUTONOMOUS_SESSION=1`: no questions, every
  fork auto-resolves toward the task Goal; a PreToolUse hook hard-blocks
  `AskUserQuestion`.
- `scripts/autonomous_session_watch.py` (cron, every 10 min) — crash-recovery
  respawn, pod-safety reconciliation, stalled-session detection,
  zombie-wrapper reaping, and auto-stop of sessions whose task is parked or
  terminal.
- `/issue-tick` + `/campaign-tick` — lightweight 20-min backstop crons that
  re-drive a stale session without reloading the full skill.
- `scripts/session_progress_report.py` / `session_summarize.py` /
  `session_resolver.py` — phone-facing titles and roll-up summaries.

### 4. Compute: multi-lane backend router

`scripts/dispatch_issue.py` + `src/research_workflow/backends/` route every
launch by the task's `backend:` frontmatter across GCP, SLURM clusters, and
RunPod: credits-backed GCP first, free SLURM lanes as fallback, RunPod only as
an explicit opt-in (never auto — pinned by test). Pods are ephemeral by
design: provision → run → upload artifacts → upload-verification PASS →
auto-terminate. The pod fleet has its own lifecycle CLI (`scripts/pod.py`),
config single-source (`scripts/pods.conf`), stale-pod audit cron, and disk
guards.

### 5. Clean results, verified mechanically

Every experiment ends as a "clean result": the task body is promoted in place
to a spec'd markdown report (TL;DR → Motivation / What I ran / Findings with
one figure per finding → Reproducibility). `scripts/verify_task_body.py`
checks ~17 mechanical invariants; `audit_clean_results_body_discipline.py`
sweeps for banned statistical-framing anti-patterns; a findings-blind
`methodology-writer` agent generates a standalone methodology reference. The
full spec lives at `.claude/skills/clean-results/SPEC.md`.

### 6. The workflow improves itself

When any agent hits a bug caused by a gap in the workflow surface itself, it
emits a `workflow-fix-candidate` block; the orchestrator auto-spawns
`workflow-improver` in the background to apply, lint, review, and merge the
fix (`.claude/rules/workflow-fix-on-bug.md`). Hard-won lessons get pinned as
tests (`tests/test_no_*`), hooks, or always-on rules.

## Adopting this in your repo

1. **Copy** `.claude/`, `CLAUDE.md`, `scripts/`, `src/research_workflow/`,
   `tests/`, and `pyproject.toml` (or merge the latter into yours; the
   package uses a `src/` layout).
2. **Search-replace the placeholders** left by generalization:
   `your-project`, `Your Project`, `your-username`, `your.username`,
   `your-hf-username`, `your-github-username`, `dashboard.example.com`,
   `YOUR_RUNPOD_TEAM_ID`, `your-gcp-project`, `your-gcloud-config`,
   `your-cluster-user`, `your-slurm-account`, `<project-root>`,
   `user@example.com`. The SLURM lane names (`mila`, `nibi`, `fir`) and
   cluster configs in `src/research_workflow/backends/slurm.py` are the
   source project's compute lanes — swap in your own clusters or drop the
   lanes you don't have.
3. **Prereqs**: `uv`, `gh`, `git`, `jq`, `ruff`. Optional but recommended:
   Happy Coder + tmux (session layer), the Codex CLI plugin (ensemble
   review), RunPod / GCP / SLURM credentials (compute), the arxiv MCP servers
   (plan fact-checking). API keys live in `.env` — see
   `src/research_workflow/orchestrate/env.py`.
4. **Patch the Happy daemon** if you want prompt-booted sessions:
   `sudo uv run python scripts/patch_happy_daemon.py`.
5. **Arm the crons**: `cron_autonomous_session_watch.sh` (every 10 min),
   `cron_worktree_audit.sh`, `cron_pod_audit.sh`, `cron_session_summarize.sh`.
6. **Create your first task**:
   `uv run python scripts/task.py new --kind experiment --title "..."`, then
   run `/issue <N>` in a Claude Code session (or
   `uv run python scripts/spawn_session.py spawn-issue --issue <N> --auto`).

## Conventions and caveats

- **Namespace prefixes are kept.** `epm:` (event markers), `EPM_*` (env
  vars), and assorted `eps`/`wf` tokens are the source project's namespace.
  They are load-bearing across scripts, hooks, tests, and docs — treat them
  as the workflow's namespace rather than renaming.
- **This is a reference extraction, not a polished framework.** Scripts carry
  incident-hardened logic, dates, and issue numbers from the source project.
  They are kept deliberately: they document *why* each guardrail exists.
- **Domain-specific rules are examples.** Four rules files
  (marker-leakage-measurement, marker-training-recipe, contrastive-negatives,
  persona-distance-metrics) and parts of `CLAUDE.md` encode the source
  project's experimental lessons. Replace them with your domain's equivalents
  — the pattern of "hard-won lesson → always-on rule file" is the point.
- **Some agents/skills reference per-project docs** (`docs/open_questions.md`,
  `RESULTS.md`, `docs/research_ideas.md`) that you create as you go.
- **Experiment entrypoints are stubs.** `scripts/train.py`, `eval.py`,
  `run_sweep.py`, `generate_wrong_answers.py`, `analyze_results.py`, and
  `run_trait_transfer.py` are placeholders the agents/skills reference —
  wire up your own pipelines there.
- **Tests** pin the workflow's invariants and pass out of the box
  (`uv run pytest`: 1708 passed, 10 skipped — the skips are
  repo-state-dependent tests that resolve live task ids). None need live
  credentials. `scripts/workflow_lint.py` also passes on the template
  itself.
