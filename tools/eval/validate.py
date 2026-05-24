"""Helpful validator: turns cryptic JSON Schema errors into messages an LLM
can act on. Used by both run-eval.py and repair.py."""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

SCHEMA_PATH = Path(__file__).resolve().parents[2] / "docs" / "livingui.schema.json"
SCHEMA = json.loads(SCHEMA_PATH.read_text())

# Known widget type enum — pulled from schema so it stays in sync
KNOWN_WIDGETS: list[str] = SCHEMA["$defs"]["Widget"]["properties"]["type"]["enum"]
KNOWN_BLOCKS: list[str] = SCHEMA["$defs"]["Block"]["properties"]["type"]["enum"]


def extract_first_json(text: str) -> tuple[str | None, str | None]:
    """Find the first JSON object in the text. Looks at fenced
    ```living-ui-widget``` / ```json blocks first, falls back to the first
    balanced {...} match. Returns (json_text, kind) where kind is inferred
    from CONTENT (presence of `version`+`app` → uiconfig, else widget)."""
    candidates: list[str] = []

    # Prefer Living UI fenced block
    fence = re.search(r"```living-ui-widget\s*\n([\s\S]*?)\n```", text)
    if fence:
        candidates.append(fence.group(1).strip())

    # Generic JSON fence
    for j in re.finditer(r"```(?:json)?\s*\n(\{[\s\S]*?\})\n```", text):
        candidates.append(j.group(1).strip())

    # Balanced fallback
    depth = 0
    start = -1
    for i, ch in enumerate(text):
        if ch == "{":
            if depth == 0:
                start = i
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start != -1:
                candidates.append(text[start : i + 1])

    for raw in candidates:
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            continue
        kind = "uiconfig" if isinstance(obj, dict) and "app" in obj and "version" in obj else "widget"
        return raw, kind

    return None, None


def _schema_with_extras(extras: list[str] | None) -> dict:
    """Clone the schema and add `extras` to the widget enum so host-registered
    widget types (e.g. `audioSummary`) don't trip validation when the prompt
    explicitly says the host has registered them."""
    if not extras:
        return SCHEMA
    cloned = json.loads(json.dumps(SCHEMA))
    cloned["$defs"]["Widget"]["properties"]["type"]["enum"].extend(extras)
    return cloned


def validate_uiconfig(obj: Any, extras: list[str] | None = None) -> list[str]:
    """Returns a list of human-friendly error messages. Empty list = valid."""
    schema = _schema_with_extras(extras)
    validator = Draft202012Validator(schema)
    return [_humanize(e) for e in sorted(validator.iter_errors(obj), key=lambda e: e.path)]


def validate_widget(obj: Any, extras: list[str] | None = None) -> list[str]:
    """Validate a single widget node against the Widget definition."""
    schema = _schema_with_extras(extras)
    widget_schema = {**schema["$defs"]["Widget"], "$defs": schema["$defs"]}
    validator = Draft202012Validator(widget_schema)
    return [_humanize(e) for e in sorted(validator.iter_errors(obj), key=lambda e: e.path)]


def _humanize(err: ValidationError) -> str:
    """Turn JSON Schema error into a self-correcting hint for the LLM."""
    path = ".".join(str(p) for p in err.absolute_path) or "<root>"

    if err.validator == "enum":
        bad = err.instance
        valid = err.validator_value
        # Suggest closest if it's a widget type / block type
        if isinstance(bad, str):
            close = _closest_match(bad, valid)
            if close:
                return (
                    f"At `{path}`: '{bad}' is not a valid widget/block type. "
                    f"Did you mean '{close}'? Allowed values: {', '.join(valid[:8])}..."
                )
        return f"At `{path}`: value {bad!r} is not allowed. Valid choices: {valid}"

    if err.validator == "required":
        missing = err.validator_value
        return f"At `{path}`: missing required field(s) {missing!r}"

    if err.validator == "type":
        return (
            f"At `{path}`: wrong type. Got {type(err.instance).__name__}, "
            f"expected {err.validator_value}"
        )

    if err.validator == "additionalProperties":
        return f"At `{path}`: unexpected extra property — {err.message}"

    if err.validator == "pattern":
        return f"At `{path}`: value does not match expected pattern ({err.validator_value})"

    return f"At `{path}`: {err.message}"


def _closest_match(bad: str, candidates: list[str]) -> str | None:
    """Cheap Levenshtein-ish: longest common-prefix bucket."""
    bad_l = bad.lower()
    best, best_score = None, 0
    for c in candidates:
        score = 0
        for a, b in zip(bad_l, c.lower()):
            if a == b:
                score += 1
            else:
                break
        if score > best_score:
            best_score = score
            best = c
    return best if best_score >= 2 else None


if __name__ == "__main__":
    import sys

    text = Path(sys.argv[1]).read_text() if len(sys.argv) > 1 else sys.stdin.read()
    raw, kind = extract_first_json(text)
    if raw is None:
        print("❌ No JSON found in input")
        sys.exit(2)
    try:
        obj = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON: {e}")
        sys.exit(2)
    errs = validate_uiconfig(obj) if kind == "uiconfig" else validate_widget(obj)
    if not errs:
        print(f"✅ Valid {kind}")
        sys.exit(0)
    print(f"❌ {len(errs)} error(s):")
    for e in errs:
        print(f"  · {e}")
    sys.exit(1)
