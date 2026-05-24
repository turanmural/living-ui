# Living UI · Eval Harness

Proves the agent SDK actually works. Pipes every prompt in `prompts.json`
through the local Claude CLI with `docs/AGENT.md` as the system prompt,
validates each response against `docs/livingui.schema.json`, and reports
a success rate.

## Setup

```bash
python3 -m pip install jsonschema
```

(No API key needed — uses the locally-installed Claude CLI subscription.)

## Quick start

```bash
cd tools/eval

# Full suite (15 prompts, ~3 minutes)
python3 run-eval.py

# 5 random prompts (~1 minute)
python3 run-eval.py --quick

# Disable repair loop — first-try rate only
python3 run-eval.py --no-repair

# Filter by id substring
python3 run-eval.py --filter finance
```

A markdown report lands in `last-report.md`.

## What you get back

```
Running 15 prompts (with repair)…
  [ 1/15] finance-dashboard… ✅  12.4s (attempts=1)
  [ 2/15] todo-tracker… ✅  10.8s (attempts=1)
  [ 3/15] meditation-timer… ❌  18.2s — At `app.pages.home.blocks.2.data.type`: 'breath' is not a valid widget/block type. Did you mean 'breathe'?
  ...

Success: 13/15 (87%)
Report: last-report.md
```

## Files

| File | Purpose |
|---|---|
| `prompts.json` | 15 representative prompts across 14 categories |
| `validate.py` | Schema validator with human-friendly errors (`'kpi' → did you mean 'number'?`) |
| `repair.py` | Self-healing wrapper: failed schema → feed errors back → retry |
| `run-eval.py` | Batch runner + markdown report writer |
| `last-report.md` | Generated after each run |

## CI integration (later)

```yaml
- name: Living UI eval
  run: python3 tools/eval/run-eval.py --quick
```

Should keep regressions from sneaking into `AGENT.md` or `livingui.schema.json`.

## Validating a single output manually

```bash
echo '{"version":2,"app":{"home":"h","pages":{"h":{"title":"x","blocks":[]}}}}' \
  | python3 validate.py /dev/stdin
```
