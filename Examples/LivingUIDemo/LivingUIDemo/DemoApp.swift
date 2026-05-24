import SwiftUI
import LivingUI

@main
struct LivingUIDemoApp: App {
    @State private var store = UiConfigStore()
    @State private var selectedPreset: Preset = .daily
    @State private var customJSON = ""
    @State private var showCustomEditor = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ZStack {
                    BreathingBackground(isThinking: false)

                    VStack(spacing: 0) {
                        presetPicker
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        LivingUIView(store: store) { action in
                            print("[demo] action: \(action)")
                        }
                    }
                }
                .navigationTitle("Living UI")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("JSON") { showCustomEditor = true }
                    }
                }
                .sheet(isPresented: $showCustomEditor) {
                    CustomJSONEditor(json: $customJSON) { value in
                        customJSON = value
                        store.update(jsonString: value)
                        selectedPreset = .custom
                        showCustomEditor = false
                    }
                }
                .onAppear { loadPreset(.daily) }
            }
        }
    }

    private var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Picker("Preset", selection: $selectedPreset) {
                Text("Daily").tag(Preset.daily)
                Text("Finance").tag(Preset.finance)
                Text("Form").tag(Preset.form)
                Text("Pure").tag(Preset.pure)
                Text("Motion").tag(Preset.motion)
                Text("Morph").tag(Preset.morph)
                if !customJSON.isEmpty { Text("Custom").tag(Preset.custom) }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPreset) { _, new in
                if new != .custom { loadPreset(new) }
            }
        }
    }

    private func loadPreset(_ preset: Preset) {
        switch preset {
        case .daily:   store.update(jsonString: PresetJSON.daily)
        case .finance: store.update(jsonString: PresetJSON.finance)
        case .form:    store.update(jsonString: PresetJSON.form)
        case .pure:    store.update(jsonString: PresetJSON.pure)
        case .motion:  store.update(jsonString: PresetJSON.motion)
        case .morph:   store.update(jsonString: PresetJSON.morph)
        case .custom:  if !customJSON.isEmpty { store.update(jsonString: customJSON) }
        }
    }
}

enum Preset: Hashable { case daily, finance, form, pure, motion, morph, custom }

struct CustomJSONEditor: View {
    @Binding var json: String
    let onApply: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $json)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .navigationTitle("Custom JSON")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Render") { onApply(json) }
                    }
                }
        }
    }
}

/// Pure primitives — illustrates DivKit-style JSON-driven layout where every
/// pixel decision lives in JSON (padding, color, border, font). Zero Swift
/// changes needed to redesign this screen.
enum PresetJSON {
    /// Interactive morphing showcase: tap card to expand to fullscreen
    /// (hero shared element), morph between alternative layouts via state,
    /// 3D flip, and interactive scale-down on tap. All driven by JSON.
    static let morph = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "state": { "selectedTab": 0, "isFlipped": false },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Morph",
            "blocks": [
              { "type": "heading", "id": "h", "text": "Tap → expand" },
              { "type": "text", "id": "t", "text": "Hero shared element morph — card grows from list into fullscreen detail. Tap the close X or background to collapse back." },
              { "type": "widget", "id": "card1", "data": {
                  "type": "expandable",
                  "id": "weather-hero",
                  "cornerRadius": 24,
                  "placeholderHeight": 110,
                  "compact": {
                    "type": "card",
                    "background": "#FF6B35",
                    "children": [
                      { "type": "hstack", "spacing": 12, "alignment": "center", "children": [
                          { "type": "icon", "name": "sun.max.fill",
                            "effect": "pulse",
                            "style": { "fontSize": 36, "color": "#FFFFFF" } },
                          { "type": "vstack", "spacing": 2, "children": [
                              { "type": "text", "text": "Almaty",
                                "style": { "fontSize": 13, "color": "#FFFFFFAA" } },
                              { "type": "text", "text": "+24°",
                                "style": { "fontSize": 28, "fontWeight": "bold", "color": "#FFFFFF" } }
                            ]
                          },
                          { "type": "spacer" },
                          { "type": "badge", "text": "TAP",
                            "background": "#FFFFFF33", "color": "#FFFFFF" }
                        ]
                      }
                    ]
                  },
                  "expanded": {
                    "type": "card",
                    "background": "#FF6B35",
                    "children": [
                      { "type": "vstack", "spacing": 16, "children": [
                          { "type": "hstack", "spacing": 16, "alignment": "center", "children": [
                              { "type": "icon", "name": "sun.max.fill",
                                "effect": "pulse",
                                "style": { "fontSize": 72, "color": "#FFFFFF" } },
                              { "type": "vstack", "spacing": 4, "children": [
                                  { "type": "text", "text": "Almaty",
                                    "style": { "fontSize": 16, "color": "#FFFFFFAA" } },
                                  { "type": "text", "text": "+24°",
                                    "style": { "fontSize": 64, "fontWeight": "heavy", "color": "#FFFFFF" } },
                                  { "type": "text", "text": "Ашық, желсіз",
                                    "style": { "fontSize": 15, "color": "#FFFFFFCC" } }
                                ]
                              }
                            ]
                          },
                          { "type": "divider", "color": "#FFFFFF33" },
                          { "type": "hstack", "spacing": 12, "stagger": 0.06, "children": [
                              { "type": "vstack", "spacing": 4, "style": { "frame": { "maxWidth": "infinity" } }, "children": [
                                  { "type": "text", "text": "Дс", "style": { "fontSize": 11, "color": "#FFFFFFAA" } },
                                  { "type": "icon", "name": "sun.max.fill", "style": { "fontSize": 22, "color": "#FFFFFF" } },
                                  { "type": "text", "text": "+25°", "style": { "fontSize": 14, "fontWeight": "bold", "color": "#FFFFFF" } }
                                ]
                              },
                              { "type": "vstack", "spacing": 4, "style": { "frame": { "maxWidth": "infinity" } }, "children": [
                                  { "type": "text", "text": "Сс", "style": { "fontSize": 11, "color": "#FFFFFFAA" } },
                                  { "type": "icon", "name": "cloud.sun.fill", "style": { "fontSize": 22, "color": "#FFFFFF" } },
                                  { "type": "text", "text": "+22°", "style": { "fontSize": 14, "fontWeight": "bold", "color": "#FFFFFF" } }
                                ]
                              },
                              { "type": "vstack", "spacing": 4, "style": { "frame": { "maxWidth": "infinity" } }, "children": [
                                  { "type": "text", "text": "Ср", "style": { "fontSize": 11, "color": "#FFFFFFAA" } },
                                  { "type": "icon", "name": "cloud.fill", "style": { "fontSize": 22, "color": "#FFFFFF" } },
                                  { "type": "text", "text": "+19°", "style": { "fontSize": 14, "fontWeight": "bold", "color": "#FFFFFF" } }
                                ]
                              },
                              { "type": "vstack", "spacing": 4, "style": { "frame": { "maxWidth": "infinity" } }, "children": [
                                  { "type": "text", "text": "Бс", "style": { "fontSize": 11, "color": "#FFFFFFAA" } },
                                  { "type": "icon", "name": "cloud.rain.fill", "style": { "fontSize": 22, "color": "#FFFFFF" } },
                                  { "type": "text", "text": "+15°", "style": { "fontSize": 14, "fontWeight": "bold", "color": "#FFFFFF" } }
                                ]
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                }
              },
              { "type": "heading", "id": "h2", "text": "Morph between layouts" },
              { "type": "widget", "id": "tabs", "data": {
                  "type": "hstack", "spacing": 6, "children": [
                    { "type": "button", "label": "Card", "icon": "rectangle.fill",
                      "style": { "background": "#FF6B35", "color": "#FFFFFF",
                                  "frame": { "maxWidth": "infinity" } },
                      "action": { "kind": "setState", "path": "selectedTab", "value": 0 } },
                    { "type": "button", "label": "Stat", "icon": "chart.bar.fill",
                      "style": { "background": "#221814", "color": "#FFFFFF",
                                  "frame": { "maxWidth": "infinity" } },
                      "action": { "kind": "setState", "path": "selectedTab", "value": 1 } },
                    { "type": "button", "label": "Quote", "icon": "quote.bubble.fill",
                      "style": { "background": "#7B6A5E", "color": "#FFFFFF",
                                  "frame": { "maxWidth": "infinity" } },
                      "action": { "kind": "setState", "path": "selectedTab", "value": 2 } }
                  ]
                }
              },
              { "type": "widget", "id": "morphzone", "data": {
                  "type": "morph",
                  "id": "morph-zone",
                  "selectedIndexStatePath": "selectedTab",
                  "frames": [
                    { "type": "card", "background": "#FFFFFF",
                      "children": [
                        { "type": "text", "text": "Card view",
                          "style": { "fontSize": 11, "fontWeight": "bold", "color": "#7B6A5E" } },
                        { "type": "text", "text": "₸ 125 000",
                          "style": { "fontSize": 34, "fontWeight": "heavy", "color": "#FF6B35" } },
                        { "type": "text", "text": "Балансыңыз бүгін осындай",
                          "style": { "fontSize": 13, "color": "#7B6A5E" } }
                      ]
                    },
                    { "type": "card", "background": "#221814",
                      "children": [
                        { "type": "hstack", "spacing": 12, "stagger": 0.08, "children": [
                            { "type": "vstack", "spacing": 2, "children": [
                                { "type": "text", "text": "INCOME",
                                  "style": { "fontSize": 10, "fontWeight": "bold", "color": "#FFFFFFAA" } },
                                { "type": "text", "text": "₸ 350K",
                                  "style": { "fontSize": 22, "fontWeight": "bold", "color": "#FFFFFF" } }
                              ]
                            },
                            { "type": "vstack", "spacing": 2, "children": [
                                { "type": "text", "text": "EXPENSE",
                                  "style": { "fontSize": 10, "fontWeight": "bold", "color": "#FFFFFFAA" } },
                                { "type": "text", "text": "₸ 180K",
                                  "style": { "fontSize": 22, "fontWeight": "bold", "color": "#FFFFFF" } }
                              ]
                            },
                            { "type": "vstack", "spacing": 2, "children": [
                                { "type": "text", "text": "SAVED",
                                  "style": { "fontSize": 10, "fontWeight": "bold", "color": "#FFFFFFAA" } },
                                { "type": "text", "text": "₸ 170K",
                                  "style": { "fontSize": 22, "fontWeight": "bold", "color": "#3DA56A" } }
                              ]
                            }
                          ]
                        }
                      ]
                    },
                    { "type": "card", "background": "#F1A86E",
                      "children": [
                        { "type": "icon", "name": "quote.opening",
                          "style": { "fontSize": 24, "color": "#FFFFFF" } },
                        { "type": "text", "text": "Living UI — әр render бірегей. Шаблон жоқ, тек тірі құрастыру.",
                          "style": { "fontSize": 17, "fontWeight": "semibold", "color": "#FFFFFF", "lineLimit": 3 } }
                      ]
                    }
                  ]
                }
              },
              { "type": "heading", "id": "h3", "text": "3D Flip" },
              { "type": "widget", "id": "flipcard", "data": {
                  "type": "flip",
                  "selectedStatePath": "isFlipped",
                  "front": {
                    "type": "card", "background": "#A78BFA",
                    "children": [
                      { "type": "text", "text": "•••• 4242",
                        "style": { "fontSize": 18, "color": "#FFFFFFAA" } },
                      { "type": "text", "text": "TURAN MURAL",
                        "style": { "fontSize": 14, "fontWeight": "bold", "color": "#FFFFFF" } },
                      { "type": "spacer", "size": 30 },
                      { "type": "text", "text": "Tap to flip →",
                        "style": { "fontSize": 11, "color": "#FFFFFF99" } }
                    ]
                  },
                  "back": {
                    "type": "card", "background": "#221814",
                    "children": [
                      { "type": "text", "text": "CVV 4242",
                        "style": { "fontSize": 13, "color": "#FFFFFFAA" } },
                      { "type": "text", "text": "Exp 04/27",
                        "style": { "fontSize": 16, "fontWeight": "bold", "color": "#FFFFFF" } },
                      { "type": "spacer", "size": 30 },
                      { "type": "text", "text": "← Tap again",
                        "style": { "fontSize": 11, "color": "#FFFFFF99" } }
                    ]
                  }
                }
              },
              { "type": "heading", "id": "h4", "text": "Tap feedback" },
              { "type": "widget", "id": "interactive", "data": {
                  "type": "interactive",
                  "pressScale": 0.94,
                  "tap": { "kind": "incrementState", "path": "selectedTab", "by": 1 },
                  "child": {
                    "type": "card", "background": "#3DA56A",
                    "children": [
                      { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                          { "type": "icon", "name": "hand.tap.fill",
                            "style": { "fontSize": 22, "color": "#FFFFFF" } },
                          { "type": "text", "text": "Hold → springy scale, release → next tab",
                            "style": { "fontSize": 14, "fontWeight": "semibold", "color": "#FFFFFF", "lineLimit": 2 } }
                        ]
                      }
                    ]
                  }
                }
              }
            ]
          }
        }
      }
    }
    """

    /// Pure motion showcase — entrance transitions, looping animations,
    /// keyframe choreography (After-Effects style), staggered children,
    /// and SF Symbol effects. Everything authored in JSON.
    static let motion = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Motion",
            "blocks": [
              { "type": "widget", "id": "hero", "data": {
                  "type": "vstack",
                  "spacing": 6,
                  "transition": "rise",
                  "style": {
                    "padding": { "all": 20 },
                    "background": "#221814",
                    "cornerRadius": 24
                  },
                  "children": [
                    { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                        { "type": "icon", "name": "wand.and.stars",
                          "effect": "pulse",
                          "style": { "fontSize": 26, "color": "#F1A86E" } },
                        { "type": "text", "text": "Living UI Motion",
                          "style": { "fontSize": 22, "fontWeight": "bold", "color": "#FFFFFF" } }
                      ]
                    },
                    { "type": "text",
                      "text": "Барлық анимация JSON-да жазылған. Әр кадр, әр секунд.",
                      "style": { "fontSize": 13, "color": "#FFFFFFAA" } }
                  ]
                }
              },
              { "type": "widget", "id": "row", "data": {
                  "type": "hstack",
                  "spacing": 10,
                  "stagger": 0.12,
                  "children": [
                    { "type": "card",
                      "children": [
                        { "type": "icon", "name": "heart.fill",
                          "effect": "bounce",
                          "style": { "fontSize": 32, "color": "#E8745B" } },
                        { "type": "text", "text": "Bounce",
                          "style": { "fontSize": 11, "color": "#7B6A5E" } }
                      ],
                      "style": { "frame": { "maxWidth": "infinity" } }
                    },
                    { "type": "card",
                      "loop": { "type": "rotate", "duration": 3 },
                      "children": [
                        { "type": "icon", "name": "gearshape.fill",
                          "style": { "fontSize": 32, "color": "#3DA56A" } },
                        { "type": "text", "text": "Rotate",
                          "style": { "fontSize": 11, "color": "#7B6A5E" } }
                      ],
                      "style": { "frame": { "maxWidth": "infinity" } }
                    },
                    { "type": "card",
                      "loop": { "type": "pulse", "duration": 1.4, "amplitude": 1.5 },
                      "children": [
                        { "type": "icon", "name": "waveform",
                          "style": { "fontSize": 32, "color": "#A78BFA" } },
                        { "type": "text", "text": "Pulse",
                          "style": { "fontSize": 11, "color": "#7B6A5E" } }
                      ],
                      "style": { "frame": { "maxWidth": "infinity" } }
                    }
                  ]
                }
              },
              { "type": "widget", "id": "kf", "data": {
                  "type": "card",
                  "animate": {
                    "tracks": [
                      { "property": "scale",
                        "keyframes": [
                          { "t": 0,   "v": 0.85, "curve": "ease" },
                          { "t": 0.4, "v": 1.06, "curve": "ease" },
                          { "t": 0.6, "v": 1.0,  "curve": "spring" }
                        ]
                      },
                      { "property": "rotation",
                        "keyframes": [
                          { "t": 0,   "v": -8, "curve": "ease" },
                          { "t": 0.6, "v": 0,  "curve": "spring" }
                        ]
                      },
                      { "property": "opacity",
                        "keyframes": [
                          { "t": 0,   "v": 0,   "curve": "linear" },
                          { "t": 0.3, "v": 1.0, "curve": "linear" }
                        ]
                      }
                    ]
                  },
                  "children": [
                    { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                        { "type": "icon", "name": "sparkles",
                          "style": { "fontSize": 22, "color": "#F1A86E" } },
                        { "type": "vstack", "spacing": 2, "children": [
                            { "type": "text", "text": "After Effects style",
                              "style": { "fontSize": 16, "fontWeight": "bold", "color": "#221814" } },
                            { "type": "text", "text": "Keyframes: scale + rotation + opacity",
                              "style": { "fontSize": 11, "color": "#7B6A5E" } }
                          ]
                        }
                      ]
                    }
                  ]
                }
              },
              { "type": "widget", "id": "list", "data": {
                  "type": "vstack",
                  "spacing": 8,
                  "stagger": 0.07,
                  "children": [
                    { "type": "card", "transition": "slide",
                      "children": [
                        { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                            { "type": "badge", "text": "01", "background": "#FF6B35", "color": "#FFFFFF" },
                            { "type": "text", "text": "Stagger cascade",
                              "style": { "fontSize": 14, "fontWeight": "semibold", "color": "#221814" } }
                          ]
                        }
                      ]
                    },
                    { "type": "card", "transition": "slide",
                      "children": [
                        { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                            { "type": "badge", "text": "02", "background": "#FF6B35", "color": "#FFFFFF" },
                            { "type": "text", "text": "70ms delay between items",
                              "style": { "fontSize": 14, "fontWeight": "semibold", "color": "#221814" } }
                          ]
                        }
                      ]
                    },
                    { "type": "card", "transition": "slide",
                      "children": [
                        { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                            { "type": "badge", "text": "03", "background": "#FF6B35", "color": "#FFFFFF" },
                            { "type": "text", "text": "Each child fades + rises in turn",
                              "style": { "fontSize": 14, "fontWeight": "semibold", "color": "#221814" } }
                          ]
                        }
                      ]
                    },
                    { "type": "card", "transition": "slide",
                      "children": [
                        { "type": "hstack", "spacing": 10, "alignment": "center", "children": [
                            { "type": "badge", "text": "04", "background": "#FF6B35", "color": "#FFFFFF" },
                            { "type": "text", "text": "Container stagger=0.07s",
                              "style": { "fontSize": 14, "fontWeight": "semibold", "color": "#221814" } }
                          ]
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    }
    """

    static let pure = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Pure JSON",
            "blocks": [
              { "type": "widget", "id": "hero", "data": {
                  "type": "vstack",
                  "spacing": 6,
                  "style": {
                    "padding": { "all": 20 },
                    "background": "#FF6B35",
                    "cornerRadius": 24,
                    "shadow": { "color": "#FF6B35", "opacity": 0.35, "radius": 14, "y": 8 }
                  },
                  "children": [
                    { "type": "hstack", "spacing": 8, "alignment": "center", "children": [
                        { "type": "icon", "name": "sparkles",
                          "style": { "fontSize": 22, "color": "#FFFFFF" } },
                        { "type": "text", "text": "Pure JSON layout",
                          "style": { "fontSize": 20, "fontWeight": "bold", "color": "#FFFFFF" } }
                      ]
                    },
                    { "type": "text",
                      "text": "Every padding, color, shadow, font is in JSON. No Swift code for this card.",
                      "style": { "fontSize": 14, "color": "#FFE9DD", "lineLimit": 3 } }
                  ]
                }
              },
              { "type": "widget", "id": "row1", "data": {
                  "type": "hstack",
                  "spacing": 10,
                  "children": [
                    { "type": "card", "background": "#FFFFFF",
                      "children": [
                        { "type": "text", "text": "STREAK",
                          "style": { "fontSize": 10, "fontWeight": "bold", "color": "#7B6A5E" } },
                        { "type": "text", "text": "21",
                          "style": { "fontSize": 36, "fontWeight": "heavy", "color": "#FF6B35" } },
                        { "type": "text", "text": "days in a row",
                          "style": { "fontSize": 11, "color": "#7B6A5E" } }
                      ],
                      "style": { "frame": { "maxWidth": "infinity" } }
                    },
                    { "type": "card",
                      "children": [
                        { "type": "hstack", "spacing": 6, "children": [
                            { "type": "badge", "text": "NEW", "background": "#3DA56A",
                              "color": "#FFFFFF" },
                            { "type": "spacer" }
                          ]
                        },
                        { "type": "text", "text": "Earned",
                          "style": { "fontSize": 10, "fontWeight": "bold", "color": "#7B6A5E" } },
                        { "type": "text", "text": "₸ 1.2M",
                          "style": { "fontSize": 28, "fontWeight": "bold", "color": "#221814" } },
                        { "type": "pill", "text": "+12.5%",
                          "background": "#3DA56A22", "color": "#3DA56A" }
                      ],
                      "style": { "frame": { "maxWidth": "infinity" } }
                    }
                  ]
                }
              },
              { "type": "widget", "id": "info", "data": {
                  "type": "vstack",
                  "spacing": 8,
                  "style": {
                    "padding": { "all": 14 },
                    "background": "#F1A86E",
                    "cornerRadius": 16
                  },
                  "children": [
                    { "type": "hstack", "spacing": 8, "alignment": "top", "children": [
                        { "type": "icon", "name": "lightbulb.fill",
                          "style": { "fontSize": 16, "color": "#FFFFFF" } },
                        { "type": "vstack", "spacing": 2, "children": [
                            { "type": "text", "text": "Try editing the JSON →",
                              "style": { "fontSize": 14, "fontWeight": "bold", "color": "#FFFFFF" } },
                            { "type": "text",
                              "text": "Tap the JSON button top-right. Swap a color or rearrange a vstack. The screen rebuilds live.",
                              "style": { "fontSize": 12, "color": "#FFFFFFCC" } }
                          ]
                        }
                      ]
                    }
                  ]
                }
              },
              { "type": "widget", "id": "btn", "data": {
                  "type": "button",
                  "label": "Talk to Shymyr",
                  "icon": "waveform",
                  "style": {
                    "background": "#221814", "color": "#FFFFFF",
                    "frame": { "maxWidth": "infinity" },
                    "padding": { "vertical": 14 }
                  },
                  "action": { "kind": "prompt", "text": "Hi" }
                }
              }
            ]
          }
        }
      }
    }
    """

    static let daily = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Today",
            "blocks": [
              { "type": "heading", "id": "h1", "text": "Доброе утро" },
              { "type": "text",    "id": "t1", "text": "Вот ваш сегодняшний день." },
              { "type": "statRow", "id": "row1", "stats": [
                  { "label": "Energy", "value": "78%", "icon": "bolt.fill" },
                  { "label": "Focus",  "value": "2h",  "icon": "clock.fill" }
                ]
              },
              { "type": "widget", "id": "w-today", "data": {
                  "type": "calendar",
                  "title": "Today",
                  "events": [
                    { "time": "09:00", "title": "Standup" },
                    { "time": "11:00", "title": "Design review" },
                    { "time": "15:30", "title": "Pickup kids" }
                  ]
                }
              },
              { "type": "todo", "id": "td1", "title": "Quick wins",
                "items": [
                  { "text": "Reply to Aliya", "done": false },
                  { "text": "Submit invoice", "done": true }
                ]
              },
              { "type": "buttonRow", "id": "br1", "buttons": [
                  { "label": "Plan tomorrow", "icon": "calendar.badge.plus",
                    "action": { "kind": "prompt", "text": "Plan tomorrow" } },
                  { "label": "Quick note", "icon": "note.text",
                    "action": { "kind": "prompt", "text": "Capture a note" } }
                ]
              }
            ]
          }
        }
      }
    }
    """

    static let finance = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Finance",
            "blocks": [
              { "type": "heading", "id": "h1", "text": "Aigul's budget" },
              { "type": "widget", "id": "w1", "data": {
                  "type": "number", "variant": "grid",
                  "title": "This month",
                  "metrics": [
                    { "label": "Income",  "value": "₸ 350K" },
                    { "label": "Expense", "value": "₸ 180K" },
                    { "label": "Saved",   "value": "₸ 170K" }
                  ]
                }
              },
              { "type": "widget", "id": "w2", "data": {
                  "type": "number", "variant": "score",
                  "label": "Goal progress", "score": 64, "caption": "₸ 640K of ₸ 1M target"
                }
              },
              { "type": "widget", "id": "w3", "data": {
                  "type": "chart",
                  "title": "Last week",
                  "data": [
                    { "label": "Mon", "value": 12000 }, { "label": "Tue", "value": 8500 },
                    { "label": "Wed", "value": 22000 }, { "label": "Thu", "value": 15600 },
                    { "label": "Fri", "value": 33400 }, { "label": "Sat", "value": 4200 },
                    { "label": "Sun", "value": 9100 }
                  ]
                }
              }
            ]
          }
        }
      }
    }
    """

    static let form = """
    {
      "version": 2,
      "theme": { "active": "warm" },
      "app": {
        "home": "home",
        "pages": {
          "home": {
            "title": "Save the moment",
            "blocks": [
              { "type": "heading", "id": "h", "text": "Quick note" },
              { "type": "note", "id": "n", "title": "About",
                "text": "All taps below mutate ui_state.json locally — the agent is asleep."
              },
              { "type": "stat", "id": "s", "label": "Counter", "icon": "number",
                "valueStatePath": "counter" },
              { "type": "buttonRow", "id": "br", "buttons": [
                  { "label": "−1", "action": { "kind": "incrementState", "path": "counter", "by": -1 } },
                  { "label": "+1", "action": { "kind": "incrementState", "path": "counter", "by":  1 } },
                  { "label": "Reset", "action": { "kind": "setState", "path": "counter", "value": 0 } }
                ]
              },
              { "type": "divider", "id": "d" },
              { "type": "todo", "id": "td", "title": "Day list",
                "itemsStatePath": "tasks"
              },
              { "type": "buttonRow", "id": "br2", "buttons": [
                  { "label": "Add task",
                    "action": { "kind": "appendState", "path": "tasks",
                                "value": { "text": "New task", "done": false } } }
                ]
              }
            ]
          }
        }
      },
      "state": {
        "counter": 0,
        "tasks": [
          { "text": "Try Living UI", "done": true },
          { "text": "Add a custom widget", "done": false }
        ]
      }
    }
    """
}
