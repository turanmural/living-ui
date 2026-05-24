"""Living UI eval harness — OpenAI / GPT variant.

Same prompt suite as run-eval.py, but routed through OpenAI's Python SDK with
the model of your choice (`--model gpt-5`, `--model gpt-5.5`, `--model gpt-4o`,
…). Uses JSON-object mode (not strict schema) because the Living UI schema
relies on conditional `allOf`/`if`/`then` blocks that OpenAI strict-mode
rejects — validation happens post-hoc with the same `validate.py` we use for
Claude. Direct apples-to-apples comparison.

Usage:
    export OPENAI_API_KEY=sk-...
    python3 -m pip install openai jsonschema
    cd packages/living-ui/tools/eval

    python3 run-eval-openai.py                  # default: gpt-5
    python3 run-eval-openai.py --model gpt-5.5  # override
    python3 run-eval-openai.py --quick          # 5 random prompts only
    python3 run-eval-openai.py --no-repair      # raw first-try rate
"""
from __future__ import annotations

import argparse
import json
import os
import random
import sys
import time
from pathlib import Path
from typing import Any

try:
    from openai import OpenAI
except ImportError:
    print("Install openai SDK first:  python3 -m pip install openai")
    sys.exit(2)

from validate import extract_first_json, validate_uiconfig, validate_widget

AGENT_MD_PATH = Path(__file__).resolve().parents[2] / "docs" / "AGENT.md"
PROMPTS_PATH = Path(__file__).parent / "prompts.json"
REPORT_PATH = Path(__file__).parent / "last-report-openai.md"
AGENT_MD = AGENT_MD_PATH.read_text()

DEFAULT_MODEL = "gpt-5"


def render_via_openai(prompt: str, system_text: str, model: str) -> str:
    """Call OpenAI Responses API. Returns raw assistant text."""
    client = OpenAI()  # picks up OPENAI_API_KEY from env
    try:
        # Modern Responses API (preferred for GPT-5 family)
        resp = client.responses.create(
            model=model,
            input=[
                {"role": "system", "content": system_text},
                {"role": "user",   "content": prompt},
            ],
        )
        # SDK exposes .output_text for plain text aggregation
        return getattr(resp, "output_text", "") or _flatten_output(resp)
    except Exception as resp_err:
        # Fallback to classic chat.completions (older models or schema differences)
        try:
            chat = client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_text},
                    {"role": "user",   "content": prompt},
                ],
            )
            return chat.choices[0].message.content or ""
        except Exception as chat_err:
            return f"<<openai-error>>\nresponses: {resp_err}\nchat: {chat_err}"


def _flatten_output(resp: Any) -> str:
    """Walk a Responses API result and concat all text parts."""
    out: list[str] = []
    for item in getattr(resp, "output", []) or []:
        for content in getattr(item, "content", []) or []:
            if getattr(content, "type", "") == "output_text":
                text = getattr(content, "text", "")
                if text:
                    out.append(text)
    return "".join(out)


def render_once(prompt: str, expect: str, model: str, extras: list[str] | None) -> dict:
    started = time.time()
    raw = render_via_openai(prompt, AGENT_MD, model)
    elapsed = time.time() - started

    json_text, kind = extract_first_json(raw)
    if json_text is None:
        return {"ok": False, "errors": ["No JSON found"], "raw": raw[:400], "elapsed": elapsed}

    try:
        obj = json.loads(json_text)
    except json.JSONDecodeError as e:
        return {"ok": False, "errors": [f"Malformed JSON: {e}"], "raw": json_text[:400], "elapsed": elapsed}

    actual_kind = kind or expect
    errs = (
        validate_uiconfig(obj, extras)
        if actual_kind == "uiconfig"
        else validate_widget(obj, extras)
    )
    return {
        "ok": not errs,
        "errors": errs,
        "raw": json_text[:400],
        "elapsed": elapsed,
        "kind": actual_kind,
    }


def render_with_repair(
    prompt: str, expect: str, model: str, extras: list[str] | None, max_retries: int = 2
) -> dict:
    """Same self-healing pattern as repair.py but routed through OpenAI."""
    started = time.time()
    history: list[str] = []

    for attempt in range(max_retries + 1):
        system = AGENT_MD
        if history:
            system += "\n\n## Repair instructions — previous attempts failed validation\n\n"
            system += "Fix these schema errors. Output ONLY the corrected JSON.\n\n"
            for e in history[-6:]:
                system += f"- {e}\n"

        raw = render_via_openai(prompt, system, model)
        json_text, kind = extract_first_json(raw)
        if json_text is None:
            history.append("Output contained no JSON. Wrap in ```living-ui-widget fence.")
            continue
        try:
            obj = json.loads(json_text)
        except json.JSONDecodeError as e:
            history.append(f"Malformed JSON: {e}")
            continue

        actual_kind = kind or expect
        errs = (
            validate_uiconfig(obj, extras)
            if actual_kind == "uiconfig"
            else validate_widget(obj, extras)
        )
        if not errs:
            return {
                "ok": True,
                "errors": [],
                "attempts": attempt + 1,
                "elapsed": time.time() - started,
            }
        history.extend(errs)

    return {
        "ok": False,
        "errors": history,
        "attempts": max_retries + 1,
        "elapsed": time.time() - started,
    }


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--model", default=DEFAULT_MODEL, help="OpenAI model id (default: gpt-5)")
    p.add_argument("--no-repair", action="store_true")
    p.add_argument("--quick", action="store_true")
    p.add_argument("--filter")
    args = p.parse_args()

    if not os.environ.get("OPENAI_API_KEY"):
        print("Set OPENAI_API_KEY in your environment first.")
        return 2

    suite = json.loads(PROMPTS_PATH.read_text())["prompts"]
    if args.filter:
        suite = [pp for pp in suite if args.filter in pp["id"]]
    if args.quick:
        random.seed(42)
        suite = random.sample(suite, k=min(5, len(suite)))

    print(f"Running {len(suite)} prompts against {args.model} "
          f"({'no-repair' if args.no_repair else 'with repair'})…")

    results: list[dict] = []
    for i, pr in enumerate(suite, 1):
        print(f"  [{i:>2}/{len(suite)}] {pr['id']}…", end=" ", flush=True)
        extras = pr.get("allowedHostWidgets")
        try:
            r = (
                render_once(pr["prompt"], pr["expect"], args.model, extras)
                if args.no_repair
                else render_with_repair(pr["prompt"], pr["expect"], args.model, extras)
            )
        except Exception as e:  # noqa: BLE001
            r = {"ok": False, "errors": [f"Harness exception: {e}"], "elapsed": 0}
        r["id"] = pr["id"]
        r["category"] = pr["category"]
        results.append(r)
        if r["ok"]:
            note = f"(attempts={r.get('attempts', 1)})" if not args.no_repair else ""
            print(f"✅ {r['elapsed']:5.1f}s {note}")
        else:
            print(f"❌ {r['elapsed']:5.1f}s — {r['errors'][0] if r['errors'] else 'unknown'}")

    write_report(results, args.no_repair, args.model)
    passed = sum(1 for r in results if r["ok"])
    print(f"\nSuccess: {passed}/{len(results)} ({passed/len(results)*100:.0f}%) on {args.model}")
    print(f"Report: {REPORT_PATH}")
    return 0 if passed == len(results) else 1


def write_report(results: list[dict], no_repair: bool, model: str) -> None:
    passed = sum(1 for r in results if r["ok"])
    total = len(results)
    pct = passed / total * 100 if total else 0
    avg_elapsed = sum(r["elapsed"] for r in results) / total if total else 0
    avg_attempts = (
        sum(r.get("attempts", 1) for r in results) / total if total and not no_repair else 1
    )

    lines = [
        "# Living UI · eval report (OpenAI)",
        "",
        f"- **Model:** `{model}`",
        f"- **Success rate:** {passed}/{total} ({pct:.0f}%)",
        f"- **Mode:** {'no-repair (first try)' if no_repair else 'with repair loop (max 3 attempts)'}",
        f"- **Avg latency per prompt:** {avg_elapsed:.1f}s",
        f"- **Avg attempts:** {avg_attempts:.2f}",
        "",
        "## Per-prompt results",
        "",
        "| # | id | category | result | latency | attempts |",
        "| -: | --- | --- | :-: | -: | -: |",
    ]
    for i, r in enumerate(results, 1):
        mark = "✅" if r["ok"] else "❌"
        attempts = r.get("attempts", 1)
        lines.append(
            f"| {i} | `{r['id']}` | {r['category']} | {mark} | {r['elapsed']:.1f}s | {attempts} |"
        )

    failures = [r for r in results if not r["ok"]]
    if failures:
        lines.extend(["", "## Failures", ""])
        for r in failures:
            lines.append(f"### `{r['id']}` ({r['category']})")
            lines.append("")
            for e in r["errors"][:5]:
                lines.append(f"- {e}")
            if "raw" in r:
                lines.extend(["", "```json", r["raw"], "```", ""])

    REPORT_PATH.write_text("\n".join(lines))


if __name__ == "__main__":
    sys.exit(main())
