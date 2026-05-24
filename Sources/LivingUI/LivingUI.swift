import SwiftUI

// MARK: - Public entry view

/// The single SwiftUI view you need to render an LLM-authored, streaming JSON
/// UI. Hand it a `UiConfigStore` (driven by your JSON source) and an
/// `ActionHandler` (called when the user interacts).
///
/// ```swift
/// LivingUIView(store: store) { action in
///     // .prompt(text: "...") | .navigate(page: "...") | ...
/// }
/// ```
public struct LivingUIView: View {
    @Environment(\.livingUITheme) private var theme

    private let store: UiConfigStore
    @State private var expansion = ExpansionStore()
    private let onAction: @MainActor @Sendable (LivingUIAction) -> Void

    public init(
        store: UiConfigStore,
        onAction: @escaping @MainActor @Sendable (LivingUIAction) -> Void = { _ in }
    ) {
        self.store = store
        self.onAction = onAction
    }

    /// Convenience: render a one-off JSON string. Internally creates a store.
    public init(
        json: String,
        onAction: @escaping @MainActor @Sendable (LivingUIAction) -> Void = { _ in }
    ) {
        let s = UiConfigStore()
        s.update(jsonString: json)
        self.store = s
        self.onAction = onAction
    }

    public var body: some View {
        HeroNamespaceProvider { ns in
            ZStack {
                page
                    .environment(\.livingUIHeroNamespace, ns)
                expansionOverlay(ns: ns)
                    .environment(\.livingUIHeroNamespace, ns)
            }
            .background(theme.colors.bgGradient.ignoresSafeArea())
            .environment(store)
            .environment(expansion)
            .environment(\.livingUIDispatcher, ClosureDispatcher(closure: onAction))
        }
    }

    private var page: some View {
        let page = store.currentConfig.app.homePage
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array(page.blocks.enumerated()), id: \.element.id) { idx, block in
                    BlockView(block: block)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.96).combined(with: .opacity).combined(with: .offset(y: 8)),
                                removal: .opacity.combined(with: .scale(scale: 0.96))
                            )
                        )
                        .animation(.spring(response: 0.42, dampingFraction: 0.82).delay(Double(idx) * 0.04),
                                   value: block.id)
                }
            }
            .padding(16)
        }
    }

    /// Phase 0.5 — full-screen overlay that mounts the `expanded` JSON of the
    /// currently-tapped `ExpandableWidgetView`. Hero matched-geometry id is
    /// shared, so SwiftUI morphs frame + corner across the boundary.
    @ViewBuilder
    private func expansionOverlay(ns: Namespace.ID) -> some View {
        if let item = expansion.expanded {
            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { expansion.dismiss() }
                ScrollView {
                    expandedRenderer(item.json)
                        .matchedGeometryEffect(id: item.id, in: ns)
                        .padding(20)
                        .frame(maxWidth: .infinity)
                }
                VStack {
                    HStack {
                        Spacer()
                        Button { expansion.dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.ultraThinMaterial))
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22).padding(.top, 18)
                    Spacer()
                }
            }
            .zIndex(100)
        }
    }

    @ViewBuilder
    private func expandedRenderer(_ json: AnyJSONValue) -> some View {
        let type = json.object?["type"]?.string ?? ""
        if let view = WidgetCatalog.shared.render(type: type, data: json) {
            view
        }
    }
}

// MARK: - Outbound actions

/// Every user interaction that bubbles out of the rendered UI. Your app
/// decides what to do with them — typically `prompt` goes to your LLM,
/// `stateMutation` is applied locally (already done if the closure is empty),
/// `structuredAction` posts a form submit to your backend.
public enum LivingUIAction: Sendable {
    /// Text payload meant for the LLM/agent (`button.action.kind=prompt`).
    case prompt(text: String)

    /// Navigation request (`button.action.kind=navigate`). The library updates
    /// `UiConfigStore.activePage` automatically; this is fired for analytics.
    case navigate(page: String)

    /// Local UI state mutation (`setState`/`toggleState`/`incrementState`/…).
    /// The library has already applied this to `UiConfigStore.state` by the
    /// time your handler runs — emit a network sync if you want server-side
    /// persistence.
    case stateMutation(action: UiAction)

    /// Form submit or button with `actionId` and optional value. Typically
    /// posted to your backend as structured payload.
    case structuredAction(id: String, value: AnyJSONValue?)

    /// User tapped an external URL (`link` widget, etc.).
    case openURL(URL)

    /// Long-press → share (Phase 2 host-side ShareLink/UIActivityViewController).
    case share(blockId: String)

    /// Agent emitted a `browse` widget; host should open an internal WKWebView,
    /// capture a screenshot, and post the result back.
    case browse(url: String)
}

/// Type-erased value the library uses for form submit payloads and unknown JSON.
public enum AnyJSONValue: Sendable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([AnyJSONValue])
    case object([String: AnyJSONValue])
    case null
}

// MARK: - Dispatcher abstraction

public protocol LivingUIActionHandler: Sendable {
    @MainActor func dispatch(_ action: LivingUIAction)
}

/// A no-op handler that just logs to stdout. Useful in previews/tests.
public struct LoggingActionHandler: LivingUIActionHandler {
    public init() {}
    @MainActor public func dispatch(_ action: LivingUIAction) {
        print("[LivingUI] \(action)")
    }
}

struct ClosureDispatcher: LivingUIActionHandler {
    let closure: @MainActor @Sendable (LivingUIAction) -> Void
    @MainActor func dispatch(_ action: LivingUIAction) {
        closure(action)
    }
}

private struct LivingUIDispatcherKey: EnvironmentKey {
    static let defaultValue: any LivingUIActionHandler = LoggingActionHandler()
}

extension EnvironmentValues {
    public var livingUIDispatcher: any LivingUIActionHandler {
        get { self[LivingUIDispatcherKey.self] }
        set { self[LivingUIDispatcherKey.self] = newValue }
    }
}
