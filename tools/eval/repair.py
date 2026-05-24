"""Repair loop: when the LLM produces invalid Living UI JSON, send the
validation errors back to the model and ask it to fix. Self-healing pattern.

Usage:
    from repair import render_with_repair
    json_obj, attempts = render_with_repair("Build a budget dashboard")
"""
from __future__ import annotations

import json
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any

from validate import extract_first_json, validate_uiconfig, validate_widget

AGENT_MD_PATH = Path(__file__).resolve().parents[2] / "docs" / "AGENT.md"
AGENT_MD = AGENT_MD_PATH.read_text()


def render_via_claude(prompt: str, system_text: str, timeout_sec: int = 90) -> str:
    """Run the local Claude CLI with the given system prompt. Returns raw stdout."""
    # Claude CLI accepts a system prompt via file. Write to a tmp file so we
    # can include accumulated repair hints.
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".md", delete=False, encoding="utf-8"
    ) as tmp:
        tmp.write(system_text)
        tmp_path = tmp.name

    try:
        proc = subprocess.run(
            [
                "claude",
                "-p",
                "--system-prompt-file",
                tmp_path,
                "--output-format",
                "text",
                prompt,
            ],
            capture_output=True,
            text=True,
            timeout=timeout_sec,
        )
        if proc.returncode != 0:
            return f"<<claude-cli-error code={proc.returncode}>>\n{proc.stderr}"
        return proc.stdout
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def render_with_repair(
    prompt: str,
    max_retries: int = 2,
    expect: str = "uiconfig",
    extras: list[str] | None = None,
) -> tuple[Any | None, int, list[str]]:
    """Try to render valid Living UI JSON, retrying with error feedback up to
    max_retries times. Returns (parsed_json, attempts_used, final_errors)."""
    history_errors: list[str] = []
    last_raw: str | None = None

    for attempt in range(max_retries + 1):
        system = AGENT_MD
        if history_errors:
            system += "\n\n## Repair instructions — previous attempts failed validation\n\n"
            system += "Fix these schema errors in your next output. Do not apologise — "
            system += "just emit the corrected JSON only.\n\n"
            for e in history_errors[-6:]:  # last 6 errors only
                system += f"- {e}\n"

        raw_output = render_via_claude(prompt, system_text=system)
        json_text, kind = extract_first_json(raw_output)

        if json_text is None:
            history_errors.append("Output contained no JSON. Wrap output in ```living-ui-widget fence.")
            last_raw = raw_output
            continue

        try:
            obj = json.loads(json_text)
        except json.JSONDecodeError as e:
            history_errors.append(f"Malformed JSON: {e}")
            last_raw = json_text
            continue

        actual_kind = kind or expect
        errs = (
            validate_uiconfig(obj, extras)
            if actual_kind == "uiconfig"
            else validate_widget(obj, extras)
        )
        if not errs:
            return obj, attempt + 1, []

        history_errors.extend(errs)
        last_raw = json_text

    return None, max_retries + 1, history_errors


if __name__ == "__main__":
    import sys

    prompt = " ".join(sys.argv[1:]) or "Build a meditation timer mini-app"
    obj, attempts, errors = render_with_repair(prompt)
    if obj is None:
        print(f"❌ Failed after {attempts} attempts")
        for e in errors[-5:]:
            print(f"  · {e}")
        sys.exit(1)
    print(f"✅ Valid after {attempts} attempt(s)")
    print(json.dumps(obj, indent=2, ensure_ascii=False))
