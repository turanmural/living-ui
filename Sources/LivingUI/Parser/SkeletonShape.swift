import SwiftUI

/// 14 type-aware skeleton shapes shown while a widget JSON is still streaming
/// (parser saw `"type":"chart"` but no closing fence yet). Map happens in
/// `SkeletonShape.shape(forType:)`.
public enum SkeletonShape: Sendable, Hashable {
    case kpi, chart, line, pie, table, list, calendar, form, action
    case kanban, container, media, map, timeline, metricGrid, finance, generic

    public static func shape(forType type: String?) -> SkeletonShape {
        guard let type else { return .generic }
        switch type {
        case "number", "kpi", "statTile", "stat", "badge", "streak", "goal": return .kpi
        case "metricGrid", "dashboard", "healthScore", "statRow": return .metricGrid
        case "chart", "lineChart": return .line
        case "pieChart", "donutChart", "gauge", "radialProgress", "expensePie": return .pie
        case "sparkline", "progressBar", "trendCard", "histogram": return .chart
        case "table", "sortableTable", "groupedList", "keyValue", "transactions",
             "expenseList", "incomeList", "comparisonTable", "priceList", "inventoryList": return .table
        case "list", "todo", "quickReply", "followup": return .list
        case "calendar", "weekCalendar", "dayAgenda", "event", "scheduleBlocks", "dateRange": return .calendar
        case "timeline", "gantt", "countdown", "progressMilestones": return .timeline
        case "input", "numberInput", "currencyInput", "dateInput", "timeInput",
             "dropdown", "multiSelect", "checkbox", "radio", "toggle", "slider",
             "rangeSlider", "colorPicker", "tagInput", "formGroup": return .form
        case "approval", "confirmAction", "actionCard", "cta", "voteCard",
             "rating", "reaction", "share": return .action
        case "kanbanBoard", "poll", "quiz": return .kanban
        case "tabs", "accordion", "carousel", "masonry", "grid", "columns",
             "modal", "popover": return .container
        case "image", "gallery", "video", "audio", "pdf", "document",
             "sticker", "gif", "lottie", "qr", "barcode", "richMedia": return .media
        case "mapPin", "route", "addressCard", "distance",
             "weatherCurrent", "weather": return .map
        case "kaspiBalance", "budgetBar", "incomeStream", "currencyConverter",
             "transferCard", "loanCard", "investmentCard", "taxCard",
             "subscriptions": return .finance
        default: return .generic
        }
    }
}

/// SwiftUI view that renders the shape outline + shimmer for a given skeleton kind.
public struct SkeletonView: View {
    @Environment(\.livingUITheme) private var theme
    public var shape: SkeletonShape

    public init(shape: SkeletonShape) { self.shape = shape }

    public var body: some View {
        Group {
            switch shape {
            case .kpi:        kpi
            case .metricGrid: metricGrid
            case .chart, .line: lineChart
            case .pie:        pie
            case .table, .list: list
            case .calendar:   calendar
            case .timeline:   timeline
            case .form:       form
            case .action:     action
            case .kanban:     kanban
            case .container:  container
            case .media:      media
            case .map:        media
            case .finance:    metricGrid
            case .generic:    generic
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18).fill(theme.colors.surface))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.colors.border.opacity(0.45), lineWidth: 0.5))
        .shimmering()
    }

    private func bar(width: CGFloat = .infinity, height: CGFloat = 12) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(theme.colors.surfaceAlt)
            .frame(maxWidth: width == .infinity ? .infinity : width, alignment: .leading)
            .frame(height: height)
    }

    private var kpi: some View {
        VStack(alignment: .leading, spacing: 8) {
            bar(width: 70, height: 10)
            bar(width: 130, height: 24)
            bar(width: 90, height: 10)
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 6) {
                    bar(width: 60, height: 9)
                    bar(width: 80, height: 18)
                }
            }
        }
    }

    private var lineChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            bar(width: 100, height: 10)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(0..<8, id: \.self) { i in
                    let heights: [CGFloat] = [40, 64, 28, 72, 52, 88, 36, 60]
                    RoundedRectangle(cornerRadius: 3).fill(theme.colors.surfaceAlt)
                        .frame(width: 14, height: heights[i % heights.count])
                }
            }
        }
    }

    private var pie: some View {
        HStack(spacing: 14) {
            Circle().fill(theme.colors.surfaceAlt).frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 6) {
                bar(width: 80, height: 9)
                bar(width: 60, height: 9)
                bar(width: 70, height: 9)
            }
        }
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 8) {
                    Circle().fill(theme.colors.surfaceAlt).frame(width: 12, height: 12)
                    bar(height: 12)
                }
            }
        }
    }

    private var calendar: some View {
        VStack(alignment: .leading, spacing: 8) {
            bar(width: 100, height: 12)
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 8) {
                    bar(width: 48, height: 10)
                    bar(height: 12)
                }
            }
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(theme.colors.surfaceAlt).frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 4) {
                        bar(width: 120, height: 10)
                        bar(width: 80, height: 8)
                    }
                }
            }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 4) {
                    bar(width: 60, height: 9)
                    RoundedRectangle(cornerRadius: 8).fill(theme.colors.surfaceAlt).frame(height: 36)
                }
            }
        }
    }

    private var action: some View {
        VStack(alignment: .leading, spacing: 10) {
            bar(width: 140, height: 14)
            bar(width: 200, height: 10)
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14).fill(theme.colors.surfaceAlt).frame(width: 84, height: 32)
                RoundedRectangle(cornerRadius: 14).fill(theme.colors.surfaceAlt).frame(width: 84, height: 32)
            }
        }
    }

    private var kanban: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(spacing: 6) {
                    bar(width: 60, height: 10)
                    RoundedRectangle(cornerRadius: 8).fill(theme.colors.surfaceAlt).frame(height: 48)
                    RoundedRectangle(cornerRadius: 8).fill(theme.colors.surfaceAlt).frame(height: 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var container: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 10).fill(theme.colors.surfaceAlt).frame(height: 28)
                }
            }
            RoundedRectangle(cornerRadius: 10).fill(theme.colors.surfaceAlt).frame(height: 80)
        }
    }

    private var media: some View {
        RoundedRectangle(cornerRadius: 12).fill(theme.colors.surfaceAlt).frame(height: 140)
    }

    private var generic: some View {
        VStack(alignment: .leading, spacing: 8) {
            bar(width: 120, height: 14)
            bar(height: 10)
            bar(width: 240, height: 10)
        }
    }
}
