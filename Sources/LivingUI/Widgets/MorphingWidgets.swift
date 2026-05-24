import SwiftUI

// MARK: - Shared-element + morph primitives
//
// 4 new widgets focused on transitions BETWEEN states (not just entrance):
//   • expandable  — compact card morphs into full-screen detail (hero)
//   • morph       — swap between alternative child layouts with smooth blend
//   • flip        — 3D card flip (front ↔ back)
//   • interactive — wrap any child with tap/longPress + scale-down feedback

// MARK: - Expandable (compact ↔ full-screen detail)

struct ExpandableWidgetView: View {
    @Environment(\.livingUIHeroNamespace) private var ns
    @Environment(ExpansionStore.self) private var expansion
    let data: AnyJSONValue

    private var heroId: String {
        data.object?["id"]?.string ?? "expand-\(data.object?["compact"]?.object?["type"]?.string ?? "anon")"
    }

    var body: some View {
        let isExpanded = expansion.expanded?.id == heroId
        let compact = data.object?["compact"] ?? .null

        Button {
            if isExpanded {
                expansion.dismiss()
            } else {
                expansion.expand(
                    id: heroId,
                    json: data.object?["expanded"] ?? compact,
                    cornerRadius: data.object?["cornerRadius"]?.number ?? 24
                )
            }
        } label: {
            Group {
                if isExpanded {
                    // Placeholder so the page layout doesn't collapse while the
                    // expanded copy is morphing in the overlay.
                    Color.clear.frame(height: collapsedPlaceholderHeight)
                } else {
                    renderExpandableChild(compact)
                        .applyHero(id: heroId, ns: ns)
                }
            }
        }
        .buttonStyle(.plain)
        .livingUIAnimations(from: data)
    }

    private var collapsedPlaceholderHeight: CGFloat {
        CGFloat(data.object?["placeholderHeight"]?.number ?? 100)
    }
}

// MARK: - Morph (switch between alternate frames)

struct MorphWidgetView: View {
    @Environment(\.livingUIHeroNamespace) private var ns
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    private var heroId: String {
        data.object?["id"]?.string ?? "morph-default"
    }

    var body: some View {
        let frames = data.object?["frames"]?.array ?? []
        let selectedIndex = resolveIndex()
        let safeIndex = max(0, min(frames.count - 1, selectedIndex))
        let active = frames.indices.contains(safeIndex) ? frames[safeIndex] : .null

        renderExpandableChild(active)
            .id(safeIndex) // re-build on index change for clean morph
            .applyHero(id: heroId, ns: ns)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.94).combined(with: .opacity),
                removal: .scale(scale: 1.04).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.42, dampingFraction: 0.78), value: safeIndex)
            .livingUIAnimations(from: data)
    }

    private func resolveIndex() -> Int {
        if let path = data.object?["selectedIndexStatePath"]?.string,
           let n = store.value(forPath: path)?.number {
            return Int(n)
        }
        if let n = data.object?["selectedIndex"]?.number {
            return Int(n)
        }
        return 0
    }
}

// MARK: - Flip (3D card flip)

struct FlipWidgetView: View {
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    @State private var localFlipped = false

    var body: some View {
        let flipped = resolveFlipped()
        let front = data.object?["front"] ?? .null
        let back = data.object?["back"] ?? .null

        ZStack {
            renderExpandableChild(front)
                .opacity(flipped ? 0 : 1)
            renderExpandableChild(back)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(flipped ? 1 : 0)
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: flipped)
        .onTapGesture {
            if data.object?["selectedStatePath"]?.string != nil {
                fireToggle()
            } else {
                localFlipped.toggle()
            }
        }
        .livingUIAnimations(from: data)
    }

    private func resolveFlipped() -> Bool {
        if let path = data.object?["selectedStatePath"]?.string,
           let b = store.value(forPath: path)?.bool {
            return b
        }
        return localFlipped
    }

    private func fireToggle() {
        if let path = data.object?["selectedStatePath"]?.string {
            store.applyAction(.toggleState(path: path))
        }
    }
}

// MARK: - Interactive (tap/longPress + spring scale feedback)

struct InteractiveWidgetView: View {
    @Environment(\.livingUIDispatcher) private var dispatcher
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    @State private var pressed = false

    var body: some View {
        let child = data.object?["child"] ?? .null
        let pressScale = data.object?["pressScale"]?.number ?? 0.96
        let tap = data.object?["tap"]
        let longPress = data.object?["longPress"]

        renderExpandableChild(child)
            .scaleEffect(pressed ? CGFloat(pressScale) : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: pressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !pressed { pressed = true } }
                    .onEnded { _ in
                        pressed = false
                        if let tap { fire(tap) }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                    if let longPress { fire(longPress) }
                }
            )
            .livingUIAnimations(from: data)
    }

    private func fire(_ action: AnyJSONValue) {
        guard let obj = action.object else { return }
        if let kind = obj["kind"]?.string {
            switch kind {
            case "prompt":        dispatcher.dispatch(.prompt(text: obj["text"]?.string ?? ""))
            case "navigate":      dispatcher.dispatch(.navigate(page: obj["page"]?.string ?? ""))
            case "setState":      store.applyAction(.setState(path: obj["path"]?.string ?? "", value: obj["value"] ?? .null))
            case "toggleState":   store.applyAction(.toggleState(path: obj["path"]?.string ?? ""))
            case "incrementState":
                store.applyAction(.incrementState(
                    path: obj["path"]?.string ?? "",
                    by: obj["by"]?.number ?? 1
                ))
            default: break
            }
        } else if let actionId = obj["actionId"]?.string {
            dispatcher.dispatch(.structuredAction(id: actionId, value: obj["value"]))
        }
    }
}

// MARK: - Helpers

@MainActor
@ViewBuilder
func renderExpandableChild(_ value: AnyJSONValue) -> some View {
    let type = value.object?["type"]?.string ?? ""
    if let view = WidgetCatalog.shared.render(type: type, data: value) {
        view
    } else {
        EmptyView()
    }
}

extension View {
    @ViewBuilder
    fileprivate func applyHero(id: String, ns: Namespace.ID?) -> some View {
        if let ns {
            self.matchedGeometryEffect(id: id, in: ns)
        } else {
            self
        }
    }
}
