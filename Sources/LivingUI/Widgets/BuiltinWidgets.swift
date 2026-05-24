import SwiftUI
import Charts

// MARK: - Number (single | grid | score)

struct NumberWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        WidgetCard {
            let variant = data.object?["variant"]?.string ?? "single"
            switch variant {
            case "grid": grid
            case "score": score
            default: single
            }
        }
    }

    private var single: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = data.object?["label"]?.string {
                Text(label).font(.system(size: theme.font.caption1, weight: .medium))
                    .foregroundStyle(theme.colors.textMuted)
            }
            if let value = data.object?["value"]?.string {
                Text(value).font(.system(size: theme.font.title1, weight: .bold))
                    .foregroundStyle(theme.colors.text)
            }
            if let trend = data.object?["trend"]?.number {
                TrendChip(trend: trend)
            }
            if let caption = data.object?["caption"]?.string {
                Text(caption).font(.system(size: theme.font.caption2))
                    .foregroundStyle(theme.colors.textMuted)
            }
        }
    }

    private var grid: some View {
        let metrics = data.object?["metrics"]?.array ?? []
        return VStack(alignment: .leading, spacing: 10) {
            if let title = data.object?["title"]?.string {
                Text(title).font(.system(size: theme.font.subhead, weight: .semibold))
                    .foregroundStyle(theme.colors.text)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, m in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.object?["label"]?.string ?? "")
                            .font(.system(size: theme.font.caption2))
                            .foregroundStyle(theme.colors.textMuted)
                        Text(m.object?["value"]?.string ?? "")
                            .font(.system(size: theme.font.title3, weight: .bold))
                            .foregroundStyle(theme.colors.text)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var score: some View {
        let scoreValue = data.object?["score"]?.number ?? 0
        let maxValue = data.object?["max"]?.number ?? 100
        return VStack(alignment: .leading, spacing: 6) {
            if let label = data.object?["label"]?.string {
                Text(label).font(.system(size: theme.font.caption1))
                    .foregroundStyle(theme.colors.textMuted)
            }
            HStack(spacing: 6) {
                Text("\(Int(scoreValue))").font(.system(size: theme.font.title1, weight: .bold))
                    .foregroundStyle(theme.colors.text)
                Text("/\(Int(maxValue))").font(.system(size: theme.font.body))
                    .foregroundStyle(theme.colors.textMuted)
            }
            ProgressView(value: min(max(scoreValue / max(maxValue, 1), 0), 1))
                .tint(theme.colors.primary)
            if let caption = data.object?["caption"]?.string {
                Text(caption).font(.system(size: theme.font.caption2))
                    .foregroundStyle(theme.colors.textMuted)
            }
        }
    }
}

struct TrendChip: View {
    @Environment(\.livingUITheme) private var theme
    let trend: Double
    var body: some View {
        let positive = trend >= 0
        HStack(spacing: 3) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
            Text("\(positive ? "+" : "")\(trend, specifier: "%.1f")%")
        }
        .font(.system(size: theme.font.caption2, weight: .semibold))
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(Capsule().fill((positive ? theme.colors.success : theme.colors.error).opacity(0.16)))
        .foregroundStyle(positive ? theme.colors.success : theme.colors.error)
    }
}

// MARK: - Chart (bar)

struct ChartWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let points = data.object?["data"]?.array ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let title = data.object?["title"]?.string {
                    Text(title).font(.system(size: theme.font.subhead, weight: .semibold))
                        .foregroundStyle(theme.colors.text)
                }
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                        BarMark(
                            x: .value("Label", p.object?["label"]?.string ?? ""),
                            y: .value("Value", p.object?["value"]?.number ?? 0)
                        )
                        .foregroundStyle(theme.colors.primary)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 140)
            }
        }
    }
}

// MARK: - Todo (read-only render — interactive variant via the `todo` block)

struct TodoWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let items = data.object?["items"]?.array ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 4) {
                if let title = data.object?["title"]?.string {
                    Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                        .foregroundStyle(theme.colors.text)
                }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Image(systemName: (item.object?["done"]?.bool ?? false)
                            ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(theme.colors.primary)
                        Text(item.object?["text"]?.string ?? "")
                            .font(.system(size: theme.font.body))
                            .foregroundStyle(theme.colors.text)
                            .strikethrough(item.object?["done"]?.bool ?? false)
                    }
                }
            }
        }
    }
}

// MARK: - Calendar (compact week strip)

struct CalendarWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let events = data.object?["events"]?.array ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 4) {
                if let title = data.object?["title"]?.string ?? data.object?["date"]?.string {
                    Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                        .foregroundStyle(theme.colors.text)
                }
                ForEach(Array(events.enumerated()), id: \.offset) { _, ev in
                    HStack(spacing: 10) {
                        Text(ev.object?["time"]?.string ?? "")
                            .font(.system(size: theme.font.caption1, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.colors.primary)
                            .frame(width: 56, alignment: .leading)
                        Text(ev.object?["title"]?.string ?? "")
                            .font(.system(size: theme.font.body))
                            .foregroundStyle(theme.colors.text)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Shared chrome

struct WidgetCard<Content: View>: View {
    @Environment(\.livingUITheme) private var theme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .fill(theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.lg)
                    .stroke(theme.colors.border.opacity(0.55), lineWidth: 0.5)
            )
    }
}
