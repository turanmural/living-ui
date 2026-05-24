import SwiftUI
import Charts

// MARK: - DataViz widgets (6): lineChart, pieChart, donutChart, sparkline,
// progressBar, gauge. Built on SwiftUI Charts (iOS 16+).

struct LineChartWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let points = data.object?["data"]?.array ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let t = data.object?["title"]?.string {
                    Text(t).font(.system(size: theme.font.subhead, weight: .semibold))
                        .foregroundStyle(theme.colors.text)
                }
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                        LineMark(
                            x: .value("L", p.object?["label"]?.string ?? ""),
                            y: .value("V", p.object?["value"]?.number ?? 0)
                        )
                        .foregroundStyle(theme.colors.primary)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("L", p.object?["label"]?.string ?? ""),
                            y: .value("V", p.object?["value"]?.number ?? 0)
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [theme.colors.primary.opacity(0.3), theme.colors.primary.opacity(0)],
                            startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 140)
            }
        }
    }
}

struct PieChartWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var donut: Bool = false

    var body: some View {
        let slices = data.object?["data"]?.array
            ?? data.object?["categories"]?.array
            ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let t = data.object?["title"]?.string {
                    Text(t).font(.system(size: theme.font.subhead, weight: .semibold))
                        .foregroundStyle(theme.colors.text)
                }
                Chart {
                    ForEach(Array(slices.enumerated()), id: \.offset) { _, s in
                        SectorMark(
                            angle: .value("V", (s.object?["value"]?.number ?? s.object?["amount"]?.number) ?? 0),
                            innerRadius: .ratio(donut ? 0.6 : 0.0),
                            angularInset: 1.2
                        )
                        .foregroundStyle(by: .value("L", s.object?["label"]?.string ?? ""))
                        .cornerRadius(2)
                    }
                }
                .frame(height: 180)
            }
        }
    }
}

struct DonutChartWidgetView: View {
    let data: AnyJSONValue
    var body: some View { PieChartWidgetView(data: data, donut: true) }
}

struct SparklineWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let points = data.object?["data"]?.array ?? []
        WidgetCard {
            VStack(alignment: .leading, spacing: 4) {
                if let label = data.object?["label"]?.string {
                    Text(label).font(.system(size: theme.font.caption1))
                        .foregroundStyle(theme.colors.textMuted)
                }
                if let value = data.object?["value"]?.string {
                    Text(value).font(.system(size: theme.font.title2, weight: .bold))
                        .foregroundStyle(theme.colors.text)
                }
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { idx, p in
                        LineMark(
                            x: .value("X", idx),
                            y: .value("Y", p.object?["value"]?.number ?? (p.number ?? 0))
                        )
                        .foregroundStyle(theme.colors.primary)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis(.hidden).chartYAxis(.hidden)
                .frame(height: 42)
            }
        }
    }
}

struct ProgressBarWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let value = data.object?["value"]?.number ?? 0
        let label = data.object?["label"]?.string
        let caption = data.object?["caption"]?.string
        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let label { Text(label).font(.system(size: theme.font.caption1, weight: .medium))
                    .foregroundStyle(theme.colors.textMuted) }
                ProgressView(value: min(max(value / 100, 0), 1))
                    .tint(theme.colors.primary)
                if let caption { Text(caption).font(.system(size: theme.font.caption2))
                    .foregroundStyle(theme.colors.textMuted) }
            }
        }
    }
}

struct GaugeWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let value = data.object?["value"]?.number ?? 0
        let label = data.object?["label"]?.string
        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let label { Text(label).font(.system(size: theme.font.caption1))
                    .foregroundStyle(theme.colors.textMuted) }
                ZStack {
                    Circle()
                        .trim(from: 0.125, to: 0.875)
                        .stroke(theme.colors.surfaceAlt, style: .init(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(90))
                    Circle()
                        .trim(from: 0.125, to: 0.125 + 0.75 * min(max(value / 100, 0), 1))
                        .stroke(theme.colors.primary, style: .init(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(90))
                    Text("\(Int(value))")
                        .font(.system(size: theme.font.title2, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.colors.text)
                }
                .frame(height: 140)
            }
        }
    }
}
