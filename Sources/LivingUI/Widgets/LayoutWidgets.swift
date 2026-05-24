import SwiftUI

// MARK: - Layout containers (5): tabs, accordion, carousel, grid, columns
// Each container recursively renders nested widgets via WidgetCatalog.

struct TabsWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    @State private var selected: Int = 0

    var body: some View {
        let tabs = data.object?["tabs"]?.array ?? []

        WidgetCard {
            VStack(alignment: .leading, spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                            let isActive = idx == selected
                            Button { selected = idx } label: {
                                Text(tab.object?["label"]?.string ?? "Tab \(idx + 1)")
                                    .font(.system(size: theme.font.caption1, weight: .semibold))
                                    .foregroundStyle(isActive ? theme.colors.onPrimary : theme.colors.text)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(
                                        isActive ? theme.colors.primary : theme.colors.surfaceAlt.opacity(0.7)
                                    ))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                let currentContent = tabs.indices.contains(selected)
                    ? tabs[selected].object?["content"] : nil
                if let widgets = currentContent?.array {
                    ForEach(Array(widgets.enumerated()), id: \.offset) { _, w in
                        renderNested(w)
                    }
                }
            }
        }
    }
}

struct AccordionWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    @State private var expanded: Set<Int> = []

    var body: some View {
        let items = data.object?["items"]?.array ?? []

        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    let isOpen = expanded.contains(idx)
                    Button {
                        if isOpen { expanded.remove(idx) } else { expanded.insert(idx) }
                    } label: {
                        HStack {
                            Text(item.object?["title"]?.string ?? "")
                                .font(.system(size: theme.font.body, weight: .semibold))
                                .foregroundStyle(theme.colors.text)
                            Spacer()
                            Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                                .foregroundStyle(theme.colors.textMuted)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)

                    if isOpen, let widgets = item.object?["content"]?.array {
                        VStack(spacing: 6) {
                            ForEach(Array(widgets.enumerated()), id: \.offset) { _, w in
                                renderNested(w)
                            }
                        }
                        .padding(.leading, 8)
                        .padding(.bottom, 6)
                    }
                    Divider().background(theme.colors.border.opacity(0.5))
                }
            }
        }
    }
}

struct CarouselWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let items = data.object?["items"]?.array ?? []

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    renderNested(item)
                        .frame(width: 240)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct GridWidgetView: View {
    let data: AnyJSONValue

    var body: some View {
        let items = data.object?["items"]?.array ?? []
        let columns = Int(data.object?["columns"]?.number ?? 2)

        WidgetCard {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    renderNested(item)
                }
            }
        }
    }
}

struct ColumnsWidgetView: View {
    let data: AnyJSONValue

    var body: some View {
        let cols = data.object?["columns"]?.array ?? []

        HStack(alignment: .top, spacing: 10) {
            ForEach(Array(cols.enumerated()), id: \.offset) { _, col in
                VStack(spacing: 10) {
                    let widgets = col.array ?? col.object?["items"]?.array ?? []
                    ForEach(Array(widgets.enumerated()), id: \.offset) { _, w in
                        renderNested(w)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Helper

@MainActor
@ViewBuilder
fileprivate func renderNested(_ value: AnyJSONValue) -> some View {
    let type = value.object?["type"]?.string ?? "unknown"
    if let view = WidgetCatalog.shared.render(type: type, data: value) {
        view
    } else {
        EmptyView()
    }
}
