# Living UI eval: Claude baseline vs Codex GPT-5.5

Run date: 2026-05-24

This run uses `codex exec -m gpt-5.5` instead of the OpenAI API harness because `OPENAI_API_KEY` was not available in the shell. A temporary runner outside the repo fed `docs/AGENT.md` plus each prompt into Codex CLI, then validated the final message with the existing `validate.py`.

No OpenAI API usage was incurred. No `AGENT.md`, schema, or eval script files were modified.

## Comparison table

| Metric | Claude (baseline) | GPT-5.5 via Codex CLI (this run) |
| --- | --- | --- |
| First-try rate | 14/15 (93%) | 15/15 (100%) |
| With-repair rate | Not fully benchmarked in the provided artifact; known failed prompt passes on repair retry | 15/15 (100%), avg attempts 1.00 |
| Avg latency | 14.8s | 47.7s first-try; 47.5s with repair |
| Failures by category | wellness (1) | none |
| Cost per prompt | $0 (local CLI) | $0 OpenAI API spend; Codex CLI did not expose token usage or per-prompt cost |
| Best output sample | Baseline passed 14 prompts; raw success samples were not present in repo artifacts | `finance-dashboard`: clean Kazakh-localized labels plus valid number grid and chart |

## Codex run details

Smoke test:

- Model: `gpt-5.5`
- Prompt: `single-number`
- Mode: no repair
- Result: pass
- Latency: 35.8s

Full first-try run:

- Success: 15/15 (100%)
- Average latency: 47.7s
- Total measured prompt time: 716.0s
- Failures: none

Full repair-mode run:

- Success: 15/15 (100%)
- Average latency: 47.5s
- Average attempts: 1.00
- Failures: none

The main tradeoff is stark: Codex GPT-5.5 was more reliable on this sample, including the Claude-failing `meditation-timer`, but it was about 3.2x slower than the Claude baseline when invoked through `codex exec`.

## Same-prompt examples

Prompt: `single-number`

```text
Just one number widget showing today's revenue ₸ 84,500 with trend +6.5%. Output only the widget JSON in a living-ui-widget fence.
```

Claude baseline: counted as a first-try pass in the existing 14/15 baseline, but raw Claude JSON samples were not present in the current repo artifacts. A local attempt to reproduce a sample could not run because the `claude` CLI is not installed in this environment.

Codex GPT-5.5 output:

```living-ui-widget
{"type":"number","variant":"single","label":"Today's revenue","value":"₸ 84,500","trend":6.5}
```

Prompt: `meditation-timer`

Claude baseline behavior: first-try failure in the `wellness` category. The documented error was that a `vstack` primitive was used at block level without a valid widget wrapper. The same prompt passed after repair retry.

Codex GPT-5.5 behavior: first-try pass. It wrapped the score and timer as widgets and used `buttonRow` at block level:

```json
{
  "type": "widget",
  "id": "calm-score",
  "data": {
    "type": "gauge",
    "label": "Calm score 78/100",
    "value": 78
  }
}
```

```json
{
  "type": "buttonRow",
  "id": "session-presets",
  "buttons": [
    { "label": "1 min", "action": { "kind": "patchState", "patch": { "sessionMinutes": 1 } } },
    { "label": "5 min", "action": { "kind": "patchState", "patch": { "sessionMinutes": 5 } } },
    { "label": "10 min", "action": { "kind": "patchState", "patch": { "sessionMinutes": 10 } } }
  ]
}
```

Kazakh-language sample from Codex GPT-5.5:

```json
{
  "label": "Қаржы",
  "text": "Қаржы бақылауы",
  "metrics": [
    { "label": "Кіріс", "value": "₸ 350K" },
    { "label": "Шығын", "value": "₸ 180K" },
    { "label": "Жинақ", "value": "₸ 170K" }
  ]
}
```

Codex also localized the approval prompt naturally:

```json
{
  "text": "Ақша аударымын растаңыз",
  "confirmLabel": "Растау",
  "cancelLabel": "Бас тарту"
}
```

## Recommendation

Use Codex GPT-5.5 as the quality default when first-try schema correctness matters more than latency. It achieved 15/15 first-try and avoided the known Claude `meditation-timer` page-block/widget-wrapper mistake. It also handled Kazakh labels well in finance and approval flows.

Keep Claude as the speed default for interactive authoring if the 14/15 first-try rate is acceptable and the repair loop is available. Claude's ~14.8s average latency is much better than Codex CLI's ~47.6s average in this run. For production authoring, the best policy is likely: Claude for fast drafts with repair enabled; Codex GPT-5.5 for stricter final generation, golden examples, or regression-sensitive prompts.

## Failure modes worth fixing in `AGENT.md`

No Codex-specific schema failure appeared in this run.

The existing Claude failure still points to a useful prompt hardening opportunity: emphasize that primitive layouts such as `vstack` are valid inside widget composition, but page-level `blocks` must use valid block types or wrap composed content inside a `widget` block. If this rule is already present, promote it closer to the examples for full `UiConfig` generation.

One semantic note from Codex output: the `meditation-timer` countdown used an absolute timestamp. That validates, but it may be brittle for reusable examples. If Living UI supports duration-style countdowns, `AGENT.md` should prefer those for timer prompts; otherwise no schema change is needed.
