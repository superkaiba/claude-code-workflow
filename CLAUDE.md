# CLAUDE.md

> Top-level project instructions consumed by Claude Code. This file is the
> generic template — fill in the project-specific TODOs at the bottom and
> adjust the placeholders (results store, artifact store, compute target,
> entrypoint scripts) to your stack.

## Critical Rules

- **Ask before assuming.** If a task has multiple valid interpretations, ask. Don't guess requirements, data formats, or success criteria.
- **Never take shortcuts.** Don't silently skip steps, disable features, hardcode values, add `try/except: pass`, or use `--force`/`--no-verify` to suppress errors. Diagnose the root cause.
- **Every new experiment MUST go through the adversarial planner** (Planner → Critic → Consistency-Checker → Revise → User approval). No exceptions. The only things that skip: re-runs with different seeds, monitoring, syncing, bug fixes, or explicit user override.
- **NEVER run experiments inline in conversation.** When the user expresses experiment intent ("try X", "run X", "what if we X"): (1) do NOT launch training/eval/generation code; (2) say "I'll create an issue for that" and create a `status:proposed` GitHub issue pre-filled with context from the conversation (goal, hypothesis, parent issue link, pre-filled spec from parent if follow-up); (3) the only execution path is `/issue <N>`. Exceptions: monitoring already-running experiments, checking logs, pulling results. Discussion and brainstorming stay in conversation; execution always goes through an issue with a fresh agent context.
- **List assumptions before implementing.** For any factual claim about APIs, data formats, or hardware — state it, mark confidence, and verify if below high.
- **Search before building.** Check package indexes, model hubs, and GitHub for existing solutions before writing code.

- **Auto-continuation policy.** When orchestrating a multi-step workflow
  (`/issue`, `/adversarial-planner`, etc.) the agent MUST auto-continue
  through every step EXCEPT the explicit user-gated states. The only
  legitimate user-input gates in `/issue` are:
  1. Step 0b (1) — issue body empty (cannot guess primary input).
  2. Step 0b (2) — `type:*` label missing (wrong guess corrupts Done column).
  3. Step 1 — clarifier blocking ambiguities (`status:proposed`).
  4. Step 2c — plan approval (`status:plan-pending`).
  5. Step 10c — compute teardown (irreversible).
  6. Step 10d — worktree merge prompt (irreversible).

  Outside these six gates, NEVER ask "should I continue with the pipeline"
  or similar. When auto-continuing past a non-obvious decision, STATE the
  assumption made (one line, prefixed `Assumption:`) so the user can
  reverse it. Use `AskUserQuestion` only at the six gates above.
  Reviewers reject PRs that introduce additional pause points.

- **STATE-TO-`status:blocked` criteria** (escape hatch to prevent
  catastrophic auto-continuation). When the agent would `Assumption:`-past
  ANY of the following, label `status:blocked` and EXIT instead:
  1. The assumption would silently delete or overwrite user files OUTSIDE
     the worktree.
  2. The assumption changes a public API contract (label semantics, marker
     schema, GitHub Actions secret name, project-board column name).
  3. consistency-checker / code-reviewer / interpretation-critic / reviewer
     returns BLOCKER or FAIL with `needs-user` flag (see "Subagent halt
     conditions" below).
  4. `failure_class: infra` respawn cap (3) hit.

- **Subagent halt conditions** (verdicts that pause regardless of
  auto-continuation):

  | Subagent | Verdict | Action |
  |---|---|---|
  | consistency-checker | BLOCKER | Step 2c writes BLOCKER to plan body, awaits user reply |
  | code-reviewer | FAIL | Bounces to implementer up to 3 rounds; on 4th FAIL, `status:blocked` |
  | interpretation-critic | FATAL | Bounces to analyzer up to 3 rounds; on 4th FATAL, `status:blocked` |
  | reviewer | FAIL with `needs-user` flag | Posts FAIL on source issue, awaits user |
  | upload-verifier | FAIL | `status:uploading` does not advance to interpretation |

## After Every Experiment

1. **Verify uploads + clean local artifacts:** per the Upload Policy table below — confirm eval results in your results store and checkpoints in your artifact store, then delete weights/merged dirs from the compute target.
2. Save structured JSON to `eval_results/` and log to your results store (all metrics, not just headline).
3. Generate plots (bar charts with error bars, pre/post comparisons) → `figures/`.
4. The `analyzer` agent creates the clean-result GitHub issue directly (labeled `clean-results:draft`). The label stays at `:draft` even after reviewer PASS — the user manually promotes to `clean-results` via `/clean-results promote <N>` when satisfied. Body follows `.claude/skills/clean-results/template.md`. Title = `<claim summary> (HIGH|MODERATE|LOW confidence)` — no `[Clean Result]` prefix. Run the clean-result verifier (e.g. `uv run python scripts/verify_clean_result.py`) before posting; FAIL blocks posting.
5. Update `RESULTS.md` and `docs/research_ideas.md`.
6. **Check disk usage** on the compute target — if low, flag to the user and preview what can be freed.
7. **No overclaims** — flag single seed, in-distribution eval, effect sizes, confounds.
8. **End-of-session check:** Run `git status` — if modified drafts, RESULTS.md, or eval_results JSON are uncommitted, commit before ending.

## Experiment Report Structure

All experiment write-ups — analyzer drafts and clean-result GitHub issues — follow ONE unified template at **`.claude/skills/clean-results/template.md`**.

The template has two parts:

- **TL;DR** — 4 H3 subsections in order: `Background`, `Methodology`, `Results`, `Next steps`. No more, no fewer.
- **Detailed report** — `Source issues`, `Setup & hyper-parameters` (reproducibility card; opens with a short "why this experiment / why these parameters / alternatives considered" prose block — this absorbs the former Decision Log), results-store URL, `Sample outputs`, `Headline numbers` (with a "Standing caveats" bullet block after the table — absorbs the former `## Caveats` section), `Artifacts`.

Key requirements:

- The `### Results` subsection contains four things in order: (1) hero figure, (2) 1-2 sentences describing the figure with headline percentages + N inline, (3) a `**Main takeaways:**` bolded label followed by 2-5 bullets where each bolds the load-bearing claim + numbers and continues with the belief update in plain prose (do NOT use an explicit `*Updates me:*` label — see `.claude/skills/clean-results/SKILL.md`), (4) a single `**Confidence: HIGH | MODERATE | LOW** — <one sentence>` line naming the binding constraint (LOW/MODERATE) or the evidence that survives scrutiny (HIGH).
- **Statistics: p-values and sample sizes only.** No effect sizes (Cohen's d, η², r-as-effect, Δ-framed-as-effect), no named statistical tests (paired t, Fisher, Mann-Whitney, bootstrap) in prose, no power analyses, no credence intervals as inline `value ± err`. Error bars on charts are allowed; discussing them in prose is not.
- All figures go through the `paper-plots` skill + your project's plotting helpers (e.g. `<your-project>/analysis/paper_plots.py`).
- Every draft MUST pass the clean-result verifier (e.g. `uv run python scripts/verify_clean_result.py <path>`) before posting.

See `.claude/skills/clean-results/principles.md` for the research-communication rationale (Nanda, Perez, Chua, Hughes, Evans).

## Reproducibility Requirements (MANDATORY)

Every experiment write-up MUST include a filled **Reproducibility Card** (all parameters to rerun from scratch — actual values, not "see config"). It lives at `## Setup & hyper-parameters` inside the Detailed report. That section MUST open with a short "why this experiment / why these parameters / alternatives considered" prose block so the rationale travels with the card. The clean-result validator flags empty-cell sentinels (`{{`, `TBD`, `see config`, `default`) as FAIL.

## Compute / remote execution

> TODO: describe how experiments run in this project. The workflow assumes
> there is *some* compute target — a local box, a managed cluster, an
> ephemeral cloud pod, etc. Fill in the lifecycle commands you actually
> use, the SSH / remote-exec mechanism, and any health-check entrypoints.
> The `/issue` skill expects a way to provision (or attach to), launch,
> monitor, and (optionally) tear down compute per issue.

Once filled in, document at minimum:

- How to provision / attach to compute for issue `<N>`.
- How to launch a long-running job (must survive the parent session — typically `nohup`).
- How to tail logs and check process / GPU health.
- How to push code to the target (the workflow assumes code edits happen on
  the local VM and the target pulls — never edit on the target).
- How to tear down compute when done. The `/issue` skill will prompt the
  user before any irreversible teardown.

## Upload Policy

| Artifact | Destination | When | Size |
|----------|------------|------|------|
| Eval results (JSON) | `<your results store>` (e.g. WandB Artifacts, S3) | Auto after eval | Small (<100MB) |
| Model checkpoints | `<your artifact store>` (e.g. HF Hub, S3) | Auto after training | Large |
| Datasets | `<your dataset store>` (e.g. HF Hub, S3) | Auto after generation | Medium |
| Adapters / fine-tune deltas | `<same as checkpoints>` | Auto after training | Small |
| Figures/plots | Git (`figures/`) | Manual commit | Tiny |

**Rules:**
- Models MUST be uploaded to the artifact store before local deletion. Never delete unuploaded models.
- `eval_results/` must contain only JSON/text — never raw model weights.
- Datasets must be uploaded so any compute target can access them without manual copy.
- After successful upload, clean local model weights to free disk.

## Pre-Launch Protocol (MANDATORY for Experimenters)

Before starting ANY experiment, experimenters MUST:

1. **Sync the target** — `git pull --ff-only` your reviewed branch onto the
   compute target. Code sync is not automatic; this prevents accidental
   mid-experiment mutations.
2. **Run pre-flight checks** — at minimum: working tree clean, env matches
   lockfile, disk space, GPU availability, results-store + artifact-store
   credentials present, network reachability of those stores. Project-
   specific preflights live in your project's `orchestrate/preflight.py`
   (or equivalent) and abort with a clear error if anything is wrong.

If preflight fails, fix the issue before proceeding. Do not skip.

## Agents vs Skills

See **`.claude/rules/agents-vs-skills.md`** for the full rule. Summary:

- **Agent** = a role with a fresh context. Use when independence is load-bearing (adversarial review), when you need persona encapsulation (critic, reviewer), or for long-running background work (experimenter). Lives in `.claude/agents/*.md`; spawned via `Agent`.
- **Skill** = a playbook loaded into the current context. Use when the task is a reusable workflow or convention. Lives in `.claude/skills/<name>/SKILL.md`; invoked via `Skill` or `/<name>`.
- A thing is one or the other, never both. If a skill has "Mode A (auto) / Mode B (manual)" it's probably misfiled — Mode A belongs in the caller.

## GitHub Project auto-add

The workflow assumes you have a GitHub project board acting as the
experiment queue, and that issues carry `status:*` labels (see
`.claude/rules/research-project-structure.md`). To auto-add newly-opened
issues to the board, add a GitHub Actions workflow that uses a personal
access token with `Projects: Read & Write` scope. The workflow should
fail soft (warn + skip) when the token is missing so a missing secret
doesn't break issue creation.

## Code Style

- **All code changes on local VM, never on remote compute.** Edit files locally, commit, push, then `git pull` on the target. Editing on remote compute creates sync conflicts and loses changes.
- **Linting:** `uv run ruff check . && uv run ruff format .` (line-length=100, py311, select E/F/I/UP).
- **Packages:** Always `uv` (not pip/conda).
- **Never silently fail.** Prefer crashing over wrong results. No bare `except: pass`.
- **Always run long jobs with `nohup`:** `nohup uv run python scripts/<entrypoint>.py &`. Long-running training / generation jobs must survive parent-session disconnect.
- **Reproducibility metadata:** All result JSONs include git commit hash, environment versions, and timestamps. Never manually build a result dict without this metadata.

## Project Overview

> TODO: one-paragraph description of what this project does and what it
> studies. Include the model(s) under test, the eval suite, and the
> primary research question.

## Directory Structure

```
src/<your-project>/   # Library code
scripts/              # Entrypoints (train.py, eval.py, sweep.py, etc.)
configs/              # Config files (your project's chosen format)
eval_results/         # Structured JSON results (one source of truth: see rules/research-project-structure.md)
figures/              # Generated plots
docs/                 # Research documentation
```

## Common Commands

> TODO: replace with your project's actual entrypoints. Examples:

```bash
# Pre-flight (run before any experiment)
uv run python -m <your_project>.orchestrate.preflight

# Training
python scripts/train.py <args>

# Evaluation
python scripts/eval.py <args>

# Analysis
python scripts/analyze_results.py

# Lint
ruff check . && ruff format .
```

## Results Format

Every run saves `run_result.json` containing at minimum: experiment name,
condition, seed, goal, base model, pipeline, pre/post metrics, the
artifact-store path for the model, and the results-store run id. See your
project's analyzer for the exact shape.

## Monitoring (MANDATORY)

- Check every 15-30s for first 2 min after launch, then every 5-10 min.
- Always: `grep -iE 'error|traceback|killed|OOM' <logfile>`.
- Report results immediately on completion.
