#!/usr/bin/env python3
"""
Living UI — source-of-truth metrics.

Counts widgets, skeletons, eval prompts, and AGENT.md tokens directly from
the source tree so README numbers cannot drift out of sync.

Usage:
    python3 tools/metrics.py            # print human-readable table
    python3 tools/metrics.py --json     # machine-readable
    python3 tools/metrics.py --check    # exit 1 if README disagrees
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def count_widgets() -> tuple[int, list[str], int]:
    """Return (widget_count, sorted_type_names, category_count) from WidgetCatalog."""
    src = (ROOT / "Sources/LivingUI/Rendering/WidgetCatalog.swift").read_text()
    inside_register = False
    types: list[str] = []
    categories: set[str] = set()
    current_category: str | None = None

    for line in src.splitlines():
        if "private func registerBuiltins()" in line:
            inside_register = True
            continue
        if not inside_register:
            continue
        if line.startswith("    }"):
            break

        cat_match = re.match(r"\s*//\s*([A-Za-z][^\n]*)", line)
        if cat_match and "register" not in line and "MARK" not in line:
            label = re.split(r"\s*[(\-—–]", cat_match.group(1).strip())[0].strip()
            if label:
                categories.add(label)

        m = re.search(r'register\(type:\s*"([^"]+)"', line)
        if m:
            types.append(m.group(1))

    return len(types), sorted(set(types)), len(categories)


def count_skeletons() -> tuple[int, list[str]]:
    """Return (skeleton_count, sorted_shape_names) from SkeletonShape enum."""
    src = (ROOT / "Sources/LivingUI/Parser/SkeletonShape.swift").read_text()
    cases: list[str] = []
    for line in src.splitlines():
        m = re.match(r"\s*case\s+([a-zA-Z][a-zA-Z0-9_,\s]+)$", line)
        if m and "shape(forType" not in line and "return" not in line:
            for name in m.group(1).split(","):
                name = name.strip()
                if name and name.isidentifier():
                    cases.append(name)
        if "public static func shape" in line:
            break
    return len(cases), cases


def count_block_types() -> tuple[int, list[str]]:
    """Return (block_count, sorted_block_types) from BlockRenderer switch."""
    src = (ROOT / "Sources/LivingUI/Rendering/BlockRenderer.swift").read_text()
    types: list[str] = []
    seen = False
    for line in src.splitlines():
        m = re.match(r'\s*case\s+"([a-zA-Z]+)"\s*:', line)
        if m:
            t = m.group(1)
            if t in ("prompt", "navigate", "setState", "toggleState",
                     "incrementState", "appendState"):
                continue
            types.append(t)
            seen = True
        elif seen and "default" in line:
            break
    block_types = [t for t in types if t != "widget"]
    return len(block_types), sorted(set(block_types))


def count_eval() -> tuple[int, list[str], int]:
    """Return (prompt_count, sorted_ids, unique_category_count)."""
    data = json.loads((ROOT / "tools/eval/prompts.json").read_text())
    prompts = data.get("prompts", [])
    ids = [p["id"] for p in prompts]
    cats = {p["category"] for p in prompts}
    return len(prompts), sorted(ids), len(cats)


def count_agent_tokens() -> tuple[int, int, int]:
    """Return (cl100k_tokens, o200k_tokens, char_count) for AGENT.md."""
    text = (ROOT / "docs/AGENT.md").read_text()
    chars = len(text)
    try:
        import tiktoken
        cl = len(tiktoken.get_encoding("cl100k_base").encode(text))
        o2 = len(tiktoken.get_encoding("o200k_base").encode(text))
        return cl, o2, chars
    except ImportError:
        return 0, 0, chars


def collect() -> dict:
    w_count, w_names, w_cats = count_widgets()
    s_count, s_names = count_skeletons()
    b_count, b_names = count_block_types()
    e_count, e_ids, e_cats = count_eval()
    a_cl, a_o2, a_chars = count_agent_tokens()
    return {
        "widgets": {"count": w_count, "categories": w_cats, "types": w_names},
        "skeletons": {"count": s_count, "shapes": s_names},
        "blocks": {"count": b_count, "types": b_names},
        "renderable_total": w_count + b_count,
        "eval": {"prompts": e_count, "ids": e_ids, "categories": e_cats},
        "agent_md": {
            "tokens_cl100k": a_cl,
            "tokens_o200k": a_o2,
            "chars": a_chars,
        },
    }


def human(report: dict) -> str:
    w, s, b, e, a = (
        report["widgets"], report["skeletons"], report["blocks"],
        report["eval"], report["agent_md"],
    )
    lines = [
        "Living UI — measured from source",
        "-" * 40,
        f"  Widget types         {w['count']:>4}  across {w['categories']} categories",
        f"  Skeleton shapes      {s['count']:>4}",
        f"  Block-level types    {b['count']:>4}",
        f"  Renderable total     {report['renderable_total']:>4}",
        f"  Eval prompts         {e['prompts']:>4}  across {e['categories']} categories",
        f"  AGENT.md tokens      {a['tokens_cl100k']:>4}  (cl100k)",
        f"                       {a['tokens_o200k']:>4}  (o200k)",
        f"  AGENT.md chars       {a['chars']:>4}",
    ]
    return "\n".join(lines)


CHECK_PATTERNS = [
    # (regex on README, key path in report)
    (r"(\d+)\s+ready-to-render domain types", "widgets.count"),
    (r"(\d+)\s+widgets",                      "widgets.count"),
    (r"(\d+)\s+type-aware skeletons",         "skeletons.count"),
    (r"(\d+)-prompt eval suite",              "eval.prompts"),
    (r"`docs/AGENT\.md`,\s*([\d.]+)K tokens", "agent_md.tokens_cl100k_k"),
]


def check_readme(report: dict) -> int:
    text = (ROOT / "README.md").read_text()
    flat = {
        "widgets.count": report["widgets"]["count"],
        "skeletons.count": report["skeletons"]["count"],
        "eval.prompts": report["eval"]["prompts"],
        "agent_md.tokens_cl100k_k": round(report["agent_md"]["tokens_cl100k"] / 1000, 1),
    }
    failed = 0
    for pat, key in CHECK_PATTERNS:
        m = re.search(pat, text)
        if not m:
            continue
        claimed = m.group(1)
        actual = flat[key]
        try:
            cf = float(claimed)
            af = float(actual)
            if abs(cf - af) > 0.2:
                print(f"  MISMATCH  '{m.group(0)}' claims {claimed}, actual {actual}")
                failed += 1
            else:
                print(f"  ok        '{m.group(0)}' matches {actual}")
        except ValueError:
            pass
    return failed


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    ap.add_argument("--check", action="store_true", help="exit 1 if README disagrees")
    args = ap.parse_args()

    report = collect()

    if args.json:
        print(json.dumps(report, indent=2))
        return 0

    print(human(report))

    if args.check:
        print()
        print("Checking README.md ...")
        failures = check_readme(report)
        if failures:
            print(f"\n{failures} mismatch(es). Update README.md to match source.")
            return 1
        print("\nAll README claims match source.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
