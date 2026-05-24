import SwiftUI

/// Renders a single `Block` from the parsed `UiConfig.app.pages[home].blocks`.
/// Supports the 14 built-in block types — everything else delegates to
/// `WidgetCatalog.shared` so hosts can register custom widgets without forking
/// the library.
public struct BlockView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(\.livingUIDispatcher) private var dispatcher
    @Environment(UiConfigStore.self) private var store

    let block: Block

    public init(block: Block) { self.block = block }

    public var body: some View {
        Group {
            switch block.type {
            case "heading":  headingView
            case "text":     textView
            case "note":     noteView
            case "button":   buttonView
            case "buttonRow": buttonRowView
            case "stat":     statView
            case "statRow":  statRowView
            case "list":     listView
            case "card":     cardView
            case "progress": progressView
            case "todo":     todoView
            case "image":    imageView
            case "divider":  Divider().background(theme.colors.border)
            case "spacer":   spacerView
            case "widget":   widgetWrapperView
            default:         unknownView
            }
        }
        .hairlineTrace(blockId: block.id)
    }

    // MARK: - Built-in renderers

    private var headingView: some View {
        Text(textValue(block, "text", fallback: ""))
            .font(.system(size: theme.font.title2, weight: .bold))
            .foregroundStyle(theme.colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var textView: some View {
        Text(boundString(block, "text", "textStatePath"))
            .font(.system(size: theme.font.body))
            .foregroundStyle(theme.colors.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noteView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = block.raw["title"]?.string {
                Text(title).font(.system(size: theme.font.caption1, weight: .bold))
                    .foregroundStyle(theme.colors.textMuted)
            }
            Text(boundString(block, "text", "textStatePath"))
                .font(.system(size: theme.font.body))
                .foregroundStyle(theme.colors.text)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: theme.radii.md)
            .fill(theme.colors.surfaceAlt.opacity(0.7)))
    }

    private var buttonView: some View {
        Button { fireBlockAction(block) } label: {
            HStack(spacing: 8) {
                if let icon = block.raw["icon"]?.string {
                    Image(systemName: icon).foregroundStyle(theme.colors.primary)
                }
                Text(block.raw["label"]?.string ?? "")
                    .font(.system(size: theme.font.callout, weight: .semibold))
                Spacer(minLength: 0)
            }
            .padding(theme.spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: theme.radii.md)
                .fill(theme.colors.surface))
            .overlay(RoundedRectangle(cornerRadius: theme.radii.md)
                .stroke(theme.colors.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var buttonRowView: some View {
        let buttons = block.raw["buttons"]?.array ?? []
        return HStack(spacing: theme.spacing.sm) {
            ForEach(Array(buttons.enumerated()), id: \.offset) { _, btn in
                Button { fireAction(btn.object?["action"]) } label: {
                    HStack(spacing: 6) {
                        if let icon = btn.object?["icon"]?.string {
                            Image(systemName: icon)
                        }
                        Text(btn.object?["label"]?.string ?? "")
                            .font(.system(size: theme.font.callout, weight: .semibold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.sm)
                    .background(Capsule().fill(theme.colors.primary.opacity(0.16)))
                    .foregroundStyle(theme.colors.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statView: some View {
        HStack(spacing: theme.spacing.sm) {
            if let icon = block.raw["icon"]?.string {
                Image(systemName: icon).font(.system(size: 20))
                    .foregroundStyle(theme.colors.primary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(block.raw["label"]?.string ?? "")
                    .font(.system(size: theme.font.caption1))
                    .foregroundStyle(theme.colors.textMuted)
                Text(boundString(block, "value", "valueStatePath"))
                    .font(.system(size: theme.font.title3, weight: .bold))
                    .foregroundStyle(theme.colors.text)
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.md)
        .background(RoundedRectangle(cornerRadius: theme.radii.md)
            .fill(theme.colors.surface))
    }

    private var statRowView: some View {
        let stats = block.raw["stats"]?.array ?? []
        return HStack(spacing: theme.spacing.sm) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, s in
                VStack(alignment: .leading, spacing: 2) {
                    if let icon = s.object?["icon"]?.string {
                        Image(systemName: icon).foregroundStyle(theme.colors.primary)
                    }
                    Text(s.object?["label"]?.string ?? "")
                        .font(.system(size: theme.font.caption2))
                        .foregroundStyle(theme.colors.textMuted)
                    Text(boundStringFromObject(s.object ?? [:], "value", "valueStatePath"))
                        .font(.system(size: theme.font.title3, weight: .bold))
                        .foregroundStyle(theme.colors.text)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(theme.spacing.md)
                .background(RoundedRectangle(cornerRadius: theme.radii.md)
                    .fill(theme.colors.surface))
            }
        }
    }

    private var listView: some View {
        let items = block.raw["items"]?.array ?? []
        return VStack(spacing: theme.spacing.sm) {
            if let title = block.raw["title"]?.string {
                Text(title).font(.system(size: theme.font.subhead, weight: .semibold))
                    .foregroundStyle(theme.colors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button { fireAction(item.object?["action"]) } label: {
                    HStack(spacing: theme.spacing.sm) {
                        if let icon = item.object?["icon"]?.string {
                            Image(systemName: icon).foregroundStyle(theme.colors.primary)
                        }
                        Text(item.object?["label"]?.string ?? "")
                            .font(.system(size: theme.font.body))
                            .foregroundStyle(theme.colors.text)
                        Spacer(minLength: 0)
                        if let value = item.object?["value"]?.string {
                            Text(value).font(.system(size: theme.font.caption1))
                                .foregroundStyle(theme.colors.textMuted)
                        }
                    }
                    .padding(theme.spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: theme.radii.md)
                        .fill(theme.colors.surfaceAlt.opacity(0.55)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cardView: some View {
        let nested = block.raw["blocks"]?.array ?? []
        return VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if let title = block.raw["title"]?.string {
                Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                    .foregroundStyle(theme.colors.text)
            }
            ForEach(Array(nested.enumerated()), id: \.offset) { _, raw in
                if let obj = raw.object,
                   let id = obj["id"]?.string ?? Optional("nested-\(UUID().uuidString)"),
                   let type = obj["type"]?.string {
                    BlockView(block: Block(id: id, type: type, raw: obj))
                }
            }
        }
        .padding(theme.spacing.md)
        .background(RoundedRectangle(cornerRadius: theme.radii.md)
            .fill(theme.colors.surface))
    }

    private var progressView: some View {
        let value = boundNumber(block, "value", "valueStatePath") ?? 0
        return VStack(alignment: .leading, spacing: 6) {
            if let label = block.raw["label"]?.string {
                Text(label).font(.system(size: theme.font.caption1, weight: .medium))
                    .foregroundStyle(theme.colors.textMuted)
            }
            ProgressView(value: min(max(value / 100, 0), 1))
                .tint(theme.colors.primary)
            if let cap = block.raw["caption"]?.string ?? store.value(forPath: block.raw["captionStatePath"]?.string)?.string {
                Text(cap).font(.system(size: theme.font.caption2))
                    .foregroundStyle(theme.colors.textMuted)
            }
        }
        .padding(theme.spacing.md)
        .background(RoundedRectangle(cornerRadius: theme.radii.md).fill(theme.colors.surface))
    }

    private var todoView: some View {
        let items = boundArray(block, "items", "itemsStatePath")
        let title = block.raw["title"]?.string
        return VStack(alignment: .leading, spacing: 6) {
            if let title { Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                .foregroundStyle(theme.colors.text)
            }
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                HStack(spacing: 10) {
                    Button { toggleTodo(block: block, index: idx) } label: {
                        Image(systemName: (item.object?["done"]?.bool ?? false)
                            ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(theme.colors.primary)
                    }
                    .buttonStyle(.plain)
                    Text(item.object?["text"]?.string ?? "")
                        .font(.system(size: theme.font.body))
                        .foregroundStyle((item.object?["done"]?.bool ?? false)
                                         ? theme.colors.textMuted : theme.colors.text)
                        .strikethrough(item.object?["done"]?.bool ?? false)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(theme.spacing.md)
        .background(RoundedRectangle(cornerRadius: theme.radii.md).fill(theme.colors.surface))
    }

    private var imageView: some View {
        let url = block.raw["url"]?.string ?? ""
        let height = block.raw["height"]?.number ?? 160
        return AsyncImage(url: URL(string: url)) { img in
            img.resizable().scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: theme.radii.md).fill(theme.colors.surfaceAlt)
        }
        .frame(height: CGFloat(height))
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }

    private var spacerView: some View {
        let size = block.raw["size"]?.number ?? 16
        return Color.clear.frame(height: CGFloat(size))
    }

    private var widgetWrapperView: some View {
        let inner = block.raw["data"] ?? .null
        let innerType = inner.object?["type"]?.string ?? "unknown"
        return Group {
            if let view = WidgetCatalog.shared.render(type: innerType, data: inner) {
                view
            } else {
                unknownWidgetFallback(type: innerType)
            }
        }
    }

    private var unknownView: some View {
        unknownWidgetFallback(type: block.type)
    }

    private func unknownWidgetFallback(type: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.diamond.fill")
                .foregroundStyle(theme.colors.textMuted)
            Text("Belgisiz widget: \(type)")
                .font(.system(size: theme.font.caption1, weight: .medium))
                .foregroundStyle(theme.colors.textMuted)
            Spacer()
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: theme.radii.md)
            .fill(theme.colors.surfaceAlt.opacity(0.5)))
    }

    // MARK: - Helpers

    private func boundString(_ block: Block, _ literalKey: String, _ pathKey: String) -> String {
        if let lit = block.raw[literalKey]?.string { return lit }
        if let path = block.raw[pathKey]?.string,
           let v = store.value(forPath: path) {
            return v.string ?? v.number.map { String(format: "%g", $0) } ?? ""
        }
        return ""
    }

    private func boundStringFromObject(_ obj: [String: AnyJSONValue], _ literalKey: String, _ pathKey: String) -> String {
        if let lit = obj[literalKey]?.string { return lit }
        if let path = obj[pathKey]?.string,
           let v = store.value(forPath: path) {
            return v.string ?? v.number.map { String(format: "%g", $0) } ?? ""
        }
        return ""
    }

    private func boundNumber(_ block: Block, _ literalKey: String, _ pathKey: String) -> Double? {
        if let lit = block.raw[literalKey]?.number { return lit }
        if let path = block.raw[pathKey]?.string {
            return store.value(forPath: path)?.number
        }
        return nil
    }

    private func boundArray(_ block: Block, _ literalKey: String, _ pathKey: String) -> [AnyJSONValue] {
        if let lit = block.raw[literalKey]?.array { return lit }
        if let path = block.raw[pathKey]?.string {
            return store.value(forPath: path)?.array ?? []
        }
        return []
    }

    private func fireBlockAction(_ block: Block) {
        fireAction(block.raw["action"])
    }

    private func fireAction(_ value: AnyJSONValue?) {
        guard let obj = value?.object else { return }
        if let kind = obj["kind"]?.string {
            switch kind {
            case "prompt":
                let text = obj["text"]?.string ?? ""
                dispatcher.dispatch(.prompt(text: text))
            case "navigate":
                let page = obj["page"]?.string ?? ""
                dispatcher.dispatch(.navigate(page: page))
            case "setState":
                let path = obj["path"]?.string ?? ""
                let val = obj["value"] ?? .null
                let action = UiAction.setState(path: path, value: val)
                store.applyAction(action)
                dispatcher.dispatch(.stateMutation(action: action))
            case "toggleState":
                let path = obj["path"]?.string ?? ""
                let action = UiAction.toggleState(path: path)
                store.applyAction(action)
                dispatcher.dispatch(.stateMutation(action: action))
            case "incrementState":
                let path = obj["path"]?.string ?? ""
                let by = obj["by"]?.number ?? 1
                let action = UiAction.incrementState(path: path, by: by)
                store.applyAction(action)
                dispatcher.dispatch(.stateMutation(action: action))
            case "appendState":
                let path = obj["path"]?.string ?? ""
                let val = obj["value"] ?? .null
                let action = UiAction.appendState(path: path, value: val)
                store.applyAction(action)
                dispatcher.dispatch(.stateMutation(action: action))
            default: break
            }
        } else if let actionId = obj["actionId"]?.string {
            dispatcher.dispatch(.structuredAction(id: actionId, value: obj["value"]))
        }
    }

    private func toggleTodo(block: Block, index: Int) {
        if let path = block.raw["itemsStatePath"]?.string {
            let action = UiAction.toggleState(path: "\(path)[\(index)].done")
            store.applyAction(action)
            dispatcher.dispatch(.stateMutation(action: action))
        }
    }

    private func textValue(_ block: Block, _ key: String, fallback: String) -> String {
        block.raw[key]?.string ?? fallback
    }
}

// MARK: - UiConfigStore convenience for state-bound value lookup

extension UiConfigStore {
    /// Resolve a state path against the current state tree. Returns nil if
    /// the path does not exist.
    public func value(forPath path: String?) -> AnyJSONValue? {
        guard let path, !path.isEmpty else { return nil }
        return UiStateEngine.getAtPath(currentConfig.state, path: path)
    }
}
