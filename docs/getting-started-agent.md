# Drop-in Agent SDK

Living UI ships with a **single-file system prompt** ([AGENT.md](AGENT.md))
and a **JSON Schema** ([livingui.schema.json](livingui.schema.json)). Hand
them to any modern LLM and the model produces valid Living UI JSON on the
first try. ~4.8K tokens of context — fits every model with 6K+ window.

## Anthropic (Python)

```python
import anthropic, pathlib

client = anthropic.Anthropic()
SYSTEM = pathlib.Path("docs/AGENT.md").read_text()

def render(prompt: str) -> str:
    msg = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2000,
        system=SYSTEM,
        messages=[{"role": "user", "content": prompt}],
    )
    return msg.content[0].text

print(render("Build a meditation timer mini-app for a busy mom"))
```

## OpenAI (Python) with structured outputs

```python
import json, pathlib
from openai import OpenAI

client = OpenAI()
SYSTEM = pathlib.Path("docs/AGENT.md").read_text()
SCHEMA = json.loads(pathlib.Path("docs/livingui.schema.json").read_text())

resp = client.responses.create(
    model="gpt-5",
    input=[
        {"role": "system", "content": SYSTEM},
        {"role": "user",   "content": "Build a workout tracker for runners"},
    ],
    response_format={
        "type": "json_schema",
        "json_schema": {"name": "UiConfig", "schema": SCHEMA, "strict": True}
    }
)
print(resp.output_text)
```

The schema is enforced — invalid widget types literally cannot escape the
model. Combined with `AGENT.md`, the model is gently guided toward the
right patterns (audio-first, one emotional center, primitive composition).

## TypeScript (any LLM that supports JSON Schema)

```ts
import { readFileSync } from "node:fs";
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();
const SYSTEM = readFileSync("docs/AGENT.md", "utf-8");

const msg = await client.messages.create({
  model: "claude-sonnet-4-6",
  max_tokens: 2000,
  system: SYSTEM,
  messages: [{ role: "user", content: "Build a packing list for Almaty in winter" }],
});
console.log(msg.content[0].text);
```

## iOS — feeding the output back to the renderer

```swift
import LivingUI

let store = UiConfigStore()

// Hook this up to your stream of LLM tokens
func onLLMChunk(_ chunk: String) {
    accumulated += chunk
    // For full-screen reload after the LLM finishes:
    if isStreamComplete {
        store.update(jsonString: accumulated)
    }
}

// Render
LivingUIView(store: store) { action in
    switch action {
    case .prompt(let text):
        // forward to the LLM as next user message
        Task { await llm.send(text) }
    case .structuredAction(let id, let value):
        // post to your backend
        Task { await backend.submit(actionId: id, value: value) }
    default:
        break
    }
}
```

## Streaming widgets in chat (Shymyr pattern)

Living UI's parser also handles the **chat-fence pattern** for streaming
widgets one-at-a-time inside an assistant message:

````
Дайын. Бұл бүгінгі бюджетің:

```living-ui-widget
{"type":"number","variant":"single","label":"Сальдо","value":"₸ 125 000","trend":12.5}
```

Әрі қарай не істейміз?
````

The host's chat view uses `SegmentParser.parse(message.text)` and renders
the message as a mix of text, widget cards, and (while the JSON is still
streaming) a type-aware skeleton.

## Validation

Run the schema against any UiConfig you produce to catch issues before
sending to the device:

```bash
npx ajv-cli validate -s docs/livingui.schema.json -d my-ui.json
```

Or in Python:

```python
from jsonschema import validate
import json, pathlib

schema = json.loads(pathlib.Path("docs/livingui.schema.json").read_text())
candidate = json.loads(open("my-ui.json").read())
validate(instance=candidate, schema=schema)  # raises on error
```

## Where to go next

- [AGENT.md](AGENT.md) — the actual prompt file. Read it once. Hand it to your LLM.
- [livingui.schema.json](livingui.schema.json) — drop into structured-outputs mode.
- [../README.md](../README.md) — Swift package install + iOS host integration.
- [../Examples/LivingUIDemo](../Examples/LivingUIDemo) — runnable demo with 6 presets.
