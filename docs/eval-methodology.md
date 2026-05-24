# Living UI — Eval methodology

This document is the full transparency record behind the badges on the README.
If a number is in the README, the recipe to reproduce it is here. If the
recipe is not here, the number should not be in the README.

> TL;DR: Claude Opus 4.7 passes **14/15 first-try** via the local Claude
> CLI. GPT-5.5 passes **15/15 first-try** via `codex exec` (a Codex CLI
> fallback used because no `OPENAI_API_KEY` was available at run time —
> not the raw OpenAI API). Both reach **15/15** once the repair loop is on.

## What the eval suite is

A black-box test of `docs/AGENT.md` + `docs/livingui.schema.json`. The harness
hands the system prompt to a model, sends one prompt at a time from
[`tools/eval/prompts.json`](../tools/eval/prompts.json), strips any fences,
and validates the JSON against the schema with
[`tools/eval/validate.py`](../tools/eval/validate.py). A prompt is a pass
iff the model produces schema-valid JSON of the expected shape (`uiconfig`
or single `widget`) on the **first reply**, with no human curation and no
retries unless the `--repair` flag is on.

## The 15 prompts

| # | id | category | shape | description |
|---|---|---|---|---|
| 1 | `finance-dashboard` | finance | uiconfig | Full mini-app: balance KPI, monthly grid, 7-day spending chart |
| 2 | `todo-tracker` | productivity | uiconfig | Heading + 3 todos + quick-reply chip row |
| 3 | `meditation-timer` | wellness | uiconfig | Calm-score gauge, breathing countdown, 3 preset buttons |
| 4 | `weather-card` | weather | widget | Single vstack hero card, warm theme |
| 5 | `single-number` | kpi | widget | One number widget with trend |
| 6 | `expandable-card` | morphing | uiconfig | Expandable widget — compact vs expanded |
| 7 | `form-signup` | form | uiconfig | formGroup + name/email/age/city + submit action |
| 8 | `interactive-counter` | state | uiconfig | Counter bound to `ui_state.count` + ±1/reset buttons |
| 9 | `primitive-hero` | primitive | widget | Pure-primitive vstack hero with rise entrance |
| 10 | `morphing-tabs` | morphing | uiconfig | 3 tabs mutating state + morph widget with 3 frames |
| 11 | `calendar-day` | time | uiconfig | dayAgenda widget + heading |
| 12 | `audio-chat-widget` | chat | widget | Host-registered `audioSummary` widget |
| 13 | `approval-flow` | action | uiconfig | confirmAction widget for KZT transfer |
| 14 | `stagger-list` | animation | uiconfig | List with staggered entrance |
| 15 | `edge-thin` | edge | uiconfig | Minimal output — empty page + theme only |

14 distinct categories. Source of truth: `tools/eval/prompts.json`.

## Run 1 — Claude Opus 4.7

| Field | Value |
|---|---|
| Model | `claude-opus-4-7` (the Claude CLI default for the runner's subscription at the time; the `tools/eval/repair.py` script invokes `claude` bare and does **not** pin a model id) |
| Date | 2026-05-24 |
| Runner | `tools/eval/run-eval.py` |
| Transport | Local `claude` CLI (subscription auth, **not** Anthropic API) |
| Temperature | CLI default (not externally set) |
| System prompt | `docs/AGENT.md` (5,759 cl100k tokens, 18,099 chars at the time of this writing) |
| Schema | `docs/livingui.schema.json` |
| Repair loop | Off for first-try metric; on for with-repair metric |

> Because the model id is not pinned in the runner, future runs will record
> whatever the Claude CLI returns as its active model. A backlog item is to
> have `run-eval.py` capture and log the resolved model id per run.

### Result

- **First-try**: 14 / 15 (93%), avg 14.8 s/prompt
- **With repair**: 15 / 15 (100%)
- **Failure**: `meditation-timer` (wellness). Cause: a `vstack` primitive was
  emitted at block level without a valid widget wrapper. Repair loop fed the
  schema error back to the model and the retry passed.

### Reproduce

```bash
# Requires: claude CLI installed and logged in
cd tools/eval
python3 -m venv .venv && source .venv/bin/activate
pip install jsonschema tiktoken
python3 run-eval.py             # 15 prompts, repair on
python3 run-eval.py --no-repair # first-try metric
```

The report lands in `tools/eval/last-report.md`. That file is gitignored —
each user regenerates it locally. If you need to share a run, copy the
report under a dated filename (e.g. `tools/eval/runs/2026-05-24-claude.md`)
and check it in.

### What we **can't** show today

- Raw Claude outputs for each prompt — the run on 2026-05-24 generated a
  summary report but the raw response bodies were not checked in. This is
  a backlog item: the next run will write raw responses to
  `tools/eval/runs/<date>-claude/` and commit them.
- A run against the Anthropic Messages API directly. The 14/15 number is
  from the CLI subscription path. We expect API parity, but it has not
  been measured.

## Run 2 — GPT-5.5

| Field | Value |
|---|---|
| Model | `gpt-5.5` |
| Date | 2026-05-24 |
| Runner | External wrapper around `codex exec -m gpt-5.5` |
| Transport | **Codex CLI**, *not* the OpenAI Chat Completions / Responses API |
| Reason for fallback | `OPENAI_API_KEY` was not set in the environment |
| System prompt | `docs/AGENT.md` (same file as Run 1) |
| Schema | `docs/livingui.schema.json` |
| Cost | $0 measured OpenAI API spend (Codex CLI did not surface per-call cost) |

### Result

- **First-try**: 15 / 15 (100%), avg 47.7 s/prompt
- **With repair**: 15 / 15 (100%), avg 1.00 attempts
- **Total measured time**: 716.0 s for the full first-try sweep

### Important caveats

1. **This is a Codex-CLI result, not a raw OpenAI API result.** Codex may
   add internal scaffolding (e.g. function-call hints, tool-use framing,
   default system additions) that the bare API would not. The 100% number
   is correct for the **Codex CLI path** and should be read that way.
2. We have not yet re-run with `OPENAI_API_KEY` against the Responses API
   in `tools/eval/run-eval-openai.py`. When we do, the result will land
   here under "Run 3". Until then, the GPT-5.5 badge in the README links
   to this document.
3. Latency is **3.2× slower** than Claude in this run. Some of that is
   Codex CLI overhead. The API run should be faster.

### Reproduce (Codex CLI path)

```bash
# Requires: codex CLI installed
cd tools/eval
codex exec -m gpt-5.5 --system "$(cat ../../docs/AGENT.md)" \
  --prompt "$(jq -r '.prompts[0].prompt' prompts.json)" \
  | python3 validate.py /dev/stdin
```

For the full batch, see the wrapper used during the original run
(documented in [`tools/eval/COMPARISON-claude-vs-openai.md`](../tools/eval/COMPARISON-claude-vs-openai.md)).

### Reproduce (real OpenAI API path — pending)

```bash
export OPENAI_API_KEY=sk-...
cd tools/eval
python3 run-eval-openai.py --model gpt-5.5
```

If you run this before we do, please open a PR with the report.

## Schema validation rules

The validator (`tools/eval/validate.py`) checks:

1. JSON parses.
2. Document matches `docs/livingui.schema.json` (top-level shape:
   `uiconfig` requires `app.pages[*].blocks[*]`; single-widget shape
   requires `{ type, data }` inside a `living-ui-widget` fence).
3. Every `block.type` is one of the 14 block types in `BlockRenderer`.
4. Every `widget.type` is registered in `WidgetCatalog` **or** appears in
   the prompt's `allowedHostWidgets` list (used by prompt 12 to model
   host-supplied widgets like `audioSummary`).
5. Action references use only the documented action types: `prompt`,
   `navigate`, `setState`, `toggleState`, `incrementState`, `appendState`.

Friendly error messages include "did you mean..." suggestions
(`'kpi' → did you mean 'number'?`) to help the repair loop converge.

## Repair loop

If `--no-repair` is **off** (the default), a failed prompt is sent back to
the model with the schema error appended as a user message. The model gets
up to **3 attempts** before the prompt is recorded as a hard failure.
`repair.py` implements this. The first-try metric ignores the repair loop;
the with-repair metric counts the prompt as a pass if any attempt validates.

## Open issues we won't paper over

- **Sample size is 15.** A 14/15 vs 15/15 difference is one prompt. We will
  not claim a model is "better" off a single-prompt delta. The headline
  number is "both models hit 100% with repair; first-try gap is ±1 prompt".
- **Raw Claude artifacts missing.** As noted above.
- **No statistical significance testing.** Eval is deterministic-ish
  (temperature defaults), but we have not run N=3 sweeps to bound variance.
- **Claude CLI vs Anthropic API.** The CLI is a subscription product and
  may handle system prompts slightly differently than the raw API. Parity
  is assumed, not measured.
- **Claude model id not pinned.** The runner calls `claude` bare. The
  active model for the 2026-05-24 run was `claude-opus-4-7` per the
  subscription default; future CLI updates may change that default.

We would rather ship an eval with three caveats than one with none.
