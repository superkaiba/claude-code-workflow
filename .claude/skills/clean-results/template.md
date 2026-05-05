# Clean-Result Issue Body — Template

Fill in every `{{PLACEHOLDER}}`. Do not leave any. If a section doesn't
apply, write "N/A" and one sentence why.

Title format: `{{CLAIM_SUMMARY}} ({{HIGH|MODERATE|LOW}} confidence)`

The title MUST (a) summarize the findings / claim (not the experiment
name) and (b) end with an overall-confidence marker `(HIGH confidence)`,
`(MODERATE confidence)`, or `(LOW confidence)`. The marker must match the
confidence line inside `### Results`. The `clean-results` label (not any
title prefix) is the canonical signal that the issue is a clean result —
do NOT prefix the title with `[Clean Result]` or similar.

Example titles (good):
- `Weak evidence that adapter scaling preserves baseline capability (LOW confidence)`
- `Midtraining preserves capability but not alignment (MODERATE confidence)`
- `Contrastive design is the sole determinant of containment (HIGH confidence)`

Example titles (bad):
- `Results for Experiment A3b` ← what does it SHOW? no confidence.
- `Leakage analysis` ← what's the CLAIM? no confidence.
- `Midtraining preserves capability but not alignment` ← claim present but confidence missing.
- `[Clean Result] Midtraining preserves capability but not alignment (MODERATE confidence)` ← drop the `[Clean Result]` prefix; the label carries that signal.

**Multi-issue narrative consolidation** (invoked as `/clean-results <N1>,<N2>,<N3>`):
add the OPTIONAL `Source-issues:` and `Supersedes:` lines below at the very
top of the TL;DR, immediately after the title (i.e., as the first content
under `## TL;DR`). Single-experiment clean-results SHOULD NOT include these
lines.

```markdown
## TL;DR
Source-issues: #N1, #N2, #N3
Supersedes: #M1, #M2

### Background
…
```

---

## TL;DR

### Background

{{1-2 sentences for a reader unfamiliar with the project: what is the broader
research area, what is the specific mechanism / phenomenon under study, and
why it matters. THEN 1-2 sentences: the prior result(s) that motivated THIS
experiment (cite issue numbers like #34), the specific question it answers,
and the goal. A reader who sees only this subsection should know BOTH what
the project is about AND why this experiment was run. Minimum 30 words.}}

### Methodology

{{2-4 sentences. Model, pipeline / intervention, conditions, N, eval signal.
State key matched-vs-confounded design choices. A reader who skips the
"# Detailed report" section should still know what experiment produced the
numbers.}}

### Results

![{{short_alt_text}}](https://raw.githubusercontent.com/{{owner}}/{{repo}}/{{commit_sha}}/figures/{{path}}.png)

{{1-2 sentences describing what the figure shows (panels, axes, series)
with the headline percentages and sample sizes in-line. Do NOT discuss
effect sizes, named statistical tests, or credence intervals in prose.}}

**Main takeaways:**

- **{{Finding #1 with the load-bearing numbers bolded.}}** {{The belief update — what the finding tells you about the hypothesis / mechanism. Continues directly after the bolded claim; do NOT use an explicit `*Updates me:*` label.}}
- **{{Finding #2.}}** {{Belief update continues after the claim.}}
- {{Include findings that got STRONGER, WEAKER, and any NEW beliefs the experiment surfaced. 2-5 bullets; more than 5 means the claim is not compressed enough.}}

**Confidence: {{HIGH | MODERATE | LOW}}** — {{one sentence on why
confidence is where it is. For HIGH: the evidence that survives scrutiny
(e.g. "three matched-protocol seeds cluster within 2 pt"). For
MODERATE/LOW: the binding constraint (e.g. "n=3 with within-condition std
0.024–0.086, a sizable fraction of the ~10 pt gaps the orderings hinge
on").}}

### Next steps

- {{Specific follow-up experiment or check. Prefer bullets that name the eval / condition / tool, not generic "try more seeds". Include an issue link if one already exists.}}
- {{Next step.}}
- {{Next step.}}

---

# Detailed report

## Human summary

{{2-5 sentences in the user's voice — the version of the result you would
share with a non-mentor colleague over Slack. Plain English, no jargon, no
stats. What happened, what surprised you, what you'd tell someone to do
with this. Cannot be empty; verifier rejects sentinels (`{{`, `TBD`, `…`,
`<TODO>`, `<placeholder>`, `XXX`, `FIXME`, `n/a`, `N/A`) and bodies
<30 words.}}

## Source issues

This clean result distills:

- #{{N}} — *{{title}}* — {{one-line contribution}}.
- #{{N}} — *{{title}}* — {{one-line contribution}}.

Downstream consumers:
- {{experiment or draft that uses the winning config, with path}}
- ...

## Setup & hyper-parameters

**Why this experiment / why these parameters / alternatives considered:**
{{2-4 sentences. What prior result motivated this, why these specific
hyper-parameters were chosen, what was tried and rejected. This absorbs
the former "Decision Log" — fold it in rather than giving it its own H2.}}

### Model
| | |
|-|-|
| Base | `{{hub_path}}` ({{param_count}}) |
| Trainable | {{LoRA adapter / full model / ...}} |

### Training — `{{script_path}}` @ commit `{{short_hash}}`
| | |
|-|-|
| Method | {{SFT / DPO / LoRA SFT / ...}} |
| Checkpoint source | {{results-store artifact path or hub path or "from scratch"}} |
| LoRA config | `r={{r}}, α={{alpha}}, dropout={{dropout}}, targets={{targets}}` |
| Loss | {{standard CE / masked to marker positions only / ...}} |
| LR | {{value or grid}} |
| Epochs | {{value or grid}} |
| LR schedule | {{cosine, warmup_ratio=X}} |
| Optimizer | AdamW (β=({{beta1}}, {{beta2}}), ε={{eps}}) |
| Weight decay | {{value}} |
| Gradient clipping | {{value}} |
| Precision | {{bf16 / fp16}}, gradient checkpointing {{on/off}} |
| DeepSpeed stage | {{ZeRO-N or N/A}} |
| Batch size (effective) | {{effective}} ({{per_device}} × {{grad_accum}} × {{gpus}}) |
| Max seq length | {{value}} |
| Seeds | {{list, e.g., [42] or [42, 137, 256]}} |

### Data
| | |
|-|-|
| Source | {{dataset name or generation script}} |
| Version / hash | {{commit hash or download date}} |
| Train / val size | {{N_train}} / {{N_val}} |
| Preprocessing | {{brief description}} |

### Eval
| | |
|-|-|
| Metric definition | {{how each metric is measured, inline}} |
| Eval dataset + size | {{name, N}} |
| Method | {{eval-harness / batched inference / judge / ...}} |
| Judge model + prompt | {{or N/A}} |
| Samples / temperature | {{K completions at temp=T}} |
| Significance | {{p-values reported alongside every percentage / rate in the headline table. Do not name the test in prose.}} |

### Compute
| | |
|-|-|
| Hardware | {{GPU type × count, target identifier}} |
| Wall time | {{range or value}} |
| Total GPU-hours | {{value}} |

### Environment
| | |
|-|-|
| Python | {{e.g., 3.11.5}} |
| Key libraries | {{e.g., torch=X, transformers=Y, ...}} |
| Git commit | {{short_hash — matches the `@` hash above}} |
| Launch command | `{{exact nohup ... &, reproducible from scratch}}` |

## Results store

Project: [{{project_name}}]({{project_url}})

| {{axis1}} | {{axis2}} | Run | State |
|---|---|---|---|
| {{v}} | {{v}} | [`{{run_id}}`]({{run_url}}) | {{finished / crashed / ...}} |
| ... | ... | ... | ... |

**(If logging has a known gap, state it here explicitly AND explain what
you did about it — e.g., post-hoc re-upload script. Do not hide.)**

### Full data (where the complete raw outputs live)

| Artifact | Location |
|---|---|
| Compiled aggregated results | `{{compiled_json_path}}` |
| Per-run / per-condition results | `{{per_run_glob}}` |
| Results-store artifact (type `eval-results`) | `{{artifact_name}}` in project [`{{project_name}}`]({{project_url}}) |
| Raw generations (all completions) | `{{raw_completions_path}}` (also in results-store artifact above) |
| Judge scores (if applicable) | `{{judge_scores_path}}` or N/A |

## Sample outputs

<!-- >=3 randomly-sampled (input, prompt, response) triplets per condition.
     Use `python scripts/sample_outputs.py --eval-json <path> --n 3 --seed 42`
     to seed-fill. The verifier requires:
       - `## Sample outputs` (H2)
       - >=1 `### Condition: <name>` (H3) subsection
       - >=3 fenced ```code``` blocks per condition
     Show BOTH a positive (behavior-present) case AND a negative
     (behavior-absent) case where applicable so the reader calibrates the
     signal, not just the summary statistic. -->

### Condition: {{cond_1_name}}

```
[input]:  {{input_1a}}
[prompt]: {{prompt_1a}}
[output]: {{output_1a}}
```

```
[input]:  {{input_1b}}
[prompt]: {{prompt_1b}}
[output]: {{output_1b}}
```

```
[input]:  {{input_1c}}
[prompt]: {{prompt_1c}}
[output]: {{output_1c}}
```

(Minimum 3 fenced blocks per condition; add more if useful. If a judge score
applies, include it inline in the fenced block, e.g. `[judge]: score=4/5
"reasoning"`.)

### Condition: {{cond_2_name}}

```
[input]:  {{input_2a}}
[prompt]: {{prompt_2a}}
[output]: {{output_2a}}
```

```
[input]:  {{input_2b}}
[prompt]: {{prompt_2b}}
[output]: {{output_2b}}
```

```
[input]:  {{input_2c}}
[prompt]: {{prompt_2c}}
[output]: {{output_2c}}
```

(Minimum 3 fenced blocks per condition; repeat the `### Condition:` block
for any additional conditions.)

## Headline numbers

| {{Regime col}} | {{param1}} | {{param2}} | {{metric1}} | {{metric2}} | {{metric3}} | {{capability}} |
|---|---|---|---|---|---|---|
| {{label}} | {{v}} | {{v}} | {{v}} | {{v}} | {{v}} | {{v}} |
| **{{winning_row_label}} ✓** | **{{v}}** | **{{v}}** | **{{v}}** | **{{v}}** | **{{v}}** | **{{v}}** |
| ... | ... | ... | ... | ... | ... | ... |

(Bold the row that IS the result. No more than ~10 rows — extras go in
`<details>` or the JSON.)

**Standing caveats** (flag inline as they arise; for CRITICAL caveats,
surface in the TL;DR "Confidence" line instead of burying):
- {{single seed / single axis of variation — if it applies, state it}}
- {{in-distribution eval only — if it applies, state it}}
- {{narrow model family — if it applies, state it}}
- {{metric is judge-based / literal string match — if it applies, state it}}
- {{confounds between arms — if any, state the confound and whether it can be ruled out}}

## Artifacts

| Type | Path / URL |
|---|---|
| Sweep / training script | [`scripts/{{x}}.py`](../blob/{{branch}}/scripts/{{x}}.py) @ `{{short_hash}}` |
| Compiled results | `{{compiled_json}}` |
| Per-run results | `{{per_run_glob}}` |
| Plot script | [`scripts/{{plot}}.py`](../blob/{{branch}}/scripts/{{plot}}.py) |
| Figure (PNG) | `figures/{{path}}.png` |
| Figure (PDF) | `figures/{{path}}.pdf` |
| Data cache | `{{data_cache_path}}` |
| Any derived module | `src/{{module_path}}` |
| Artifact-store model / adapter | `{{artifact_store_path_or_prefix}}` |
