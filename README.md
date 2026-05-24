# Living UI

> **The first LLM-native SDUI engine.**
> JSON arrives as a stream. The UI builds itself, breathes, and stays in sync
> with state — no `flutter run`, no app store deploy, no template authoring.
> Just structured intent from any agent.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](#)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude](https://img.shields.io/badge/Claude%20Sonnet%204.7-93%25%20first--try-7C3AED.svg)](tools/eval/last-report.md)
[![GPT-5.5](https://img.shields.io/badge/GPT--5.5-100%25%20first--try-10A37F.svg)](tools/eval/COMPARISON-claude-vs-openai.md)

**Verified on two frontier models** — 15-prompt eval suite, no human curation:
Claude Sonnet 4.7 hits 93% first-try (avg 14.8s/prompt), GPT-5.5 hits **100% first-try** (avg 47.7s/prompt). Both reach 100% with the built-in repair loop. [Full comparison →](tools/eval/COMPARISON-claude-vs-openai.md)

```swift
import LivingUI

LivingUIView(json: agent.outputStream)
    .onAction { action in
        // .prompt("...") | .navigate("page") | .submit("formId", values)
        print(action)
    }
```

That's it. Hook any JSON source — a WebSocket from a Claude/GPT agent, a
periodic poll, a hand-written file — and the renderer paints native SwiftUI
with the right skeletons while the JSON streams in.

## Why this exists

Server-Driven UI frameworks (Airbnb's BloomerangUI, Yandex's DivKit, Lyft's
Server Driven UI) were built for **human-authored** layouts that change every
sprint. The bottleneck was deployment, so they shipped JSON instead of code.

Living UI was built for **LLM-authored** layouts that change every sentence.
The bottleneck is now *latency* — the user is watching the layout assemble as
the agent thinks. Three things make this different from DivKit & friends:

| | Living UI | Classic SDUI |
|---|---|---|
| Author | LLM (agent writes JSON live) | Designer (template + variables) |
| Streaming | First-class — skeleton appears the moment `{"type":"chart"` is parsed | Layout arrives whole or not at all |
| Animation | Staged 3-phase reveal (skeleton → shimmer → morph) | Static |
| Widgets | 127 ready-to-render domain types (KZT finance, voice, AI primitives) | ~30 generic divs |
| State | `ui_state.json` + 6 typed local actions, no agent wake-up needed | Variables + URL-style actions |
| iOS native | Liquid Glass, Dynamic Island integration | Material-leaning |

If you are building an AI assistant that needs to *show* things, not just
describe them, you want Living UI.

## Quick start

### 1. Add the package

```swift
.package(url: "https://github.com/turanmural/living-ui", from: "0.1.0")
```

### 2. Render

```swift
import SwiftUI
import LivingUI

struct ContentView: View {
    @State private var json = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Today",
            "blocks": [
              { "type": "heading", "id": "h", "text": "Доброе утро, Айгүл" },
              { "type": "widget", "id": "w1", "data": {
                  "type": "number", "variant": "single",
                  "label": "Бүгінгі кіріс", "value": "₸ 28 000", "trend": 15
              }}
            ]
          }
        }
      }
    }
    """

    var body: some View {
        LivingUIView(json: json) { action in
            print("user fired action: \(action)")
        }
    }
}
```

### 3. Stream from your LLM

```swift
let store = UiConfigStore()

for try await chunk in agent.outputStream {
    store.update(jsonFragment: chunk)   // appends; skeleton-aware
}

LivingUIView(store: store).onAction { ... }
```

The library handles partial JSON, fences (` ```shymyr-widget {...}` ` in chat
text), schema validation, and 18 type-aware skeletons while the agent finishes
writing.

## What's in the box

```
Sources/LivingUI/
├── Core/                    UiConfig schema · UiAction · UiState engine · Store
├── Parser/                  SegmentParser (streaming) · SkeletonShape
├── Widgets/                 127-widget catalog (15 category enums)
│   └── Category/            Renderer per category (KPI, DataViz, Form, …)
├── Rendering/               BlockRenderer · StagedWidgetView (3-phase reveal)
├── Theme/                   ThemeTokens · GlassEffect · Color+Hex
└── Animation/               BreathingBackground · HairlineTrace · Shimmer
```

A single `LivingUIView` wraps the lot.

## Demo

```bash
cd Examples/LivingUIDemo
open LivingUIDemo.xcodeproj
```

The demo app ships a text box where you paste any `ui.json` and watch it
render live, plus three preset layouts (Finance, Daily, Form) you can step
through to see the streaming animation.

## Agent SDK — the killer feature

Living UI ships with a **drop-in system prompt** (`docs/AGENT.md`, 4.8K tokens)
and a **JSON Schema** (`docs/livingui.schema.json`) so any LLM can author
valid Living UI JSON on the first try. No fine-tuning, no eval suite — just
hand the file to the model.

```python
import anthropic, pathlib

client = anthropic.Anthropic()
SYSTEM = pathlib.Path("docs/AGENT.md").read_text()

msg = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=2000,
    system=SYSTEM,
    messages=[{"role":"user","content":"Build a daily mood tracker"}],
)
print(msg.content[0].text)   # ← valid Living UI JSON, on first try
```

OpenAI structured outputs (`response_format = json_schema`) is supported
via `docs/livingui.schema.json` — the model **physically cannot** invent
an unknown widget type. See [docs/getting-started-agent.md](docs/getting-started-agent.md).

## Documentation

- **[AGENT.md](docs/AGENT.md)** — the LLM system prompt. Read it once.
- **[livingui.schema.json](docs/livingui.schema.json)** — machine-readable schema.
- **[getting-started-agent.md](docs/getting-started-agent.md)** — Anthropic / OpenAI / iOS host integration in 30 lines each.

## Roadmap

- ✅ **0.1** — iOS Swift Package, 127 widgets, streaming parser, three themes
- 🚧 **0.2** — Android renderer (Jetpack Compose port)
- 🚧 **0.3** — Web renderer (React, SSR-friendly)
- 🚧 **0.4** — Expression engine (`@{ income - expense > 0 ? "ОК" : "Тарылды" }`)
- 🚧 **0.5** — Templates (reusable JSON fragments)
- 🚧 **0.6** — Visual editor (no-code Figma-like authoring beside the agent)

## Used by

- [Shymyr.ai](https://shymyr.ai) — Kazakh-language mass-market AI assistant, the
  product that gave birth to this library.

> Using Living UI in your project? Open a PR to add yourself.

## License

MIT — see [LICENSE](LICENSE).
