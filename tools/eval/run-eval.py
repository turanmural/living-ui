"""Living UI eval harness — runs every prompt in prompts.json through Claude
(with AGENT.md as system prompt + repair loop), validates each output against
livingui.schema.json, and prints a markdown success-rate report.

Usage:
    cd packages/living-ui/tools/eval
    python3 run-eval.py                # run all prompts
    python3 run-eval.py --no-repair    # disable repair loop (raw first-try rate)
    python3 run-eval.py --quick        # 5 random prompts only
"""
from __future__ import annotations

import argparse
import json
import random
import sys
import time
from pathlib import Path

from repair import render_with_repair, render_via_claude, AGENT_MD
from validate import extract_first_json, validate_uiconfig, validate_widget

PROMPTS_PATH = Path(__file__).parent / "prompts.json"
REPORT_PATH = Path(__file__).parent / "last-report.md"


def run_once(prompt: str, expect: str, extras: list[str] | None = None) -> dict:
    """Single-attempt rendering (no repair). Returns result dict."""
    started = time.time()
    raw = render_via_claude(prompt, AGENT_MD)
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


def run_repaired(prompt: str, expect: str, extras: list[str] | None = None) -> dict:
    started = time.time()
    obj, attempts, errors = render_with_repair(prompt, expect=expect, extras=extras)
    elapsed = time.time() - started
    return {
        "ok": obj is not None,
        "errors": errors,
        "attempts": attempts,
        "elapsed": elapsed,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-repair", action="store_true", help="Skip repair loop")
    parser.add_argument("--quick", action="store_true", help="Only 5 random prompts")
    parser.add_argument("--filter", help="Substring filter on prompt id")
    args = parser.parse_args()

    suite = json.loads(PROMPTS_PATH.read_text())["prompts"]
    if args.filter:
        suite = [p for p in suite if args.filter in p["id"]]
    if args.quick:
        random.seed(42)
        suite = random.sample(suite, k=min(5, len(suite)))

    print(f"Running {len(suite)} prompts ({'no-repair' if args.no_repair else 'with repair'})…")

    results = []
    for i, p in enumerate(suite, 1):
        print(f"  [{i:>2}/{len(suite)}] {p['id']}…", end=" ", flush=True)
        extras = p.get("allowedHostWidgets")
        try:
            if args.no_repair:
                r = run_once(p["prompt"], p["expect"], extras=extras)
            else:
                r = run_repaired(p["prompt"], p["expect"], extras=extras)
        except Exception as e:  # noqa: BLE001
            r = {"ok": False, "errors": [f"Harness exception: {e}"], "elapsed": 0}
        r["id"] = p["id"]
        r["category"] = p["category"]
        results.append(r)
        if r["ok"]:
            note = f"(attempts={r.get('attempts', 1)})" if not args.no_repair else ""
            print(f"✅ {r['elapsed']:5.1f}s {note}")
        else:
            print(f"❌ {r['elapsed']:5.1f}s — {r['errors'][0] if r['errors'] else 'unknown'}")

    write_report(results, args.no_repair)
    passed = sum(1 for r in results if r["ok"])
    print(f"\nSuccess: {passed}/{len(results)} ({passed/len(results)*100:.0f}%)")
    print(f"Report: {REPORT_PATH}")
    return 0 if passed == len(results) else 1


def write_report(results: list[dict], no_repair: bool) -> None:
    passed = sum(1 for r in results if r["ok"])
    total = len(results)
    pct = passed / total * 100 if total else 0
    avg_elapsed = sum(r["elapsed"] for r in results) / total if total else 0
    avg_attempts = (
        sum(r.get("attempts", 1) for r in results) / total if total and not no_repair else 1
    )

    lines = [
        "# Living UI · eval report",
        "",
        f"- **Success rate:** {passed}/{total} ({pct:.0f}%)",
        f"- **Mode:** {'no-repair (first try)' if no_repair else 'with repair loop (max 3 attempts)'}",
        f"- **Avg latency per prompt:** {avg_elapsed:.1f}s",
        f"- **Avg attempts:** {avg_attempts:.2f}",
        f"- **Model:** Claude (local CLI)",
        f"- **Prompt suite:** {total} prompts across "
        + ", ".join(sorted({r['category'] for r in results}))
        + ".",
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
