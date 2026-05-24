import SwiftUI

// MARK: - Time widgets (3): countdown, timeline, dayAgenda

struct CountdownWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string
        let targetStr = data.object?["target"]?.string
        let target = ISO8601DateFormatter().date(from: targetStr ?? "") ?? Date().addingTimeInterval(3600)

        WidgetCard {
            VStack(alignment: .leading, spacing: 8) {
                if let title { Text(title).font(.system(size: theme.font.subhead, weight: .semibold))
                    .foregroundStyle(theme.colors.text) }
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let remaining = max(0, target.timeIntervalSince(ctx.date))
                    let days = Int(remaining / 86400)
                    let hours = Int(remaining.truncatingRemainder(dividingBy: 86400) / 3600)
                    let mins = Int(remaining.truncatingRemainder(dividingBy: 3600) / 60)
                    let secs = Int(remaining.truncatingRemainder(dividingBy: 60))
                    HStack(spacing: 12) {
                        timeCell("\(days)", "күн")
                        timeCell(String(format: "%02d", hours), "сағ")
                        timeCell(String(format: "%02d", mins), "мин")
                        timeCell(String(format: "%02d", secs), "сек")
                    }
                }
            }
        }
    }

    private func timeCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: theme.font.title2, weight: .bold, design: .rounded))
                .foregroundStyle(theme.colors.primary)
            Text(label).font(.system(size: theme.font.caption2))
                .foregroundStyle(theme.colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(theme.colors.surfaceAlt.opacity(0.6)))
    }
}

struct TimelineWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let items = data.object?["items"]?.array ?? []

        WidgetCard {
            VStack(alignment: .leading, spacing: 10) {
                if let title = data.object?["title"]?.string {
                    Text(title).font(.system(size: theme.font.subhead, weight: .semibold))
                        .foregroundStyle(theme.colors.text)
                }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(spacing: 2) {
                            Circle().fill(statusColor(item.object?["status"]?.string))
                                .frame(width: 10, height: 10)
                            Rectangle().fill(theme.colors.border.opacity(0.4))
                                .frame(width: 1)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            if let time = item.object?["time"]?.string {
                                Text(time).font(.system(size: theme.font.caption2, weight: .semibold))
                                    .foregroundStyle(theme.colors.textMuted)
                            }
                            Text(item.object?["title"]?.string ?? "")
                                .font(.system(size: theme.font.body))
                                .foregroundStyle(theme.colors.text)
                            if let desc = item.object?["description"]?.string {
                                Text(desc).font(.system(size: theme.font.caption1))
                                    .foregroundStyle(theme.colors.textMuted)
                            }
                        }
                    }
                }
            }
        }
    }

    private func statusColor(_ s: String?) -> Color {
        switch s {
        case "active":   return theme.colors.primary
        case "done":     return theme.colors.success
        case "error":    return theme.colors.error
        default:         return theme.colors.textMuted
        }
    }
}

struct DayAgendaWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let events = data.object?["events"]?.array ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 8) {
                if let date = data.object?["date"]?.string {
                    Text(date).font(.system(size: theme.font.caption1, weight: .bold))
                        .foregroundStyle(theme.colors.textMuted)
                }
                ForEach(Array(events.enumerated()), id: \.offset) { _, ev in
                    HStack(alignment: .top, spacing: 12) {
                        Text(ev.object?["time"]?.string ?? "")
                            .font(.system(size: theme.font.caption1, weight: .semibold, design: .monospaced))
                            .foregroundStyle(theme.colors.primary)
                            .frame(width: 56, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ev.object?["title"]?.string ?? "")
                                .font(.system(size: theme.font.body))
                                .foregroundStyle(theme.colors.text)
                            if let location = ev.object?["location"]?.string {
                                Text(location).font(.system(size: theme.font.caption2))
                                    .foregroundStyle(theme.colors.textMuted)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
