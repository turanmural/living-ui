import SwiftUI

/// Pluggable registry for `widget` blocks. The built-in renderers (number,
/// chart, calendar, todo) are registered automatically; hosts call
/// `WidgetCatalog.shared.register(type:render:)` to add their own.
///
/// ```swift
/// WidgetCatalog.shared.register(type: "kaspiBalance") { data in
///     AnyView(KaspiBalanceView(json: data))
/// }
/// ```
@MainActor
public final class WidgetCatalog {
    public static let shared = WidgetCatalog()

    private var renderers: [String: (AnyJSONValue) -> AnyView] = [:]

    private init() {
        registerBuiltins()
    }

    public func register(type: String, render: @escaping (AnyJSONValue) -> AnyView) {
        renderers[type] = render
    }

    public func unregister(type: String) {
        renderers.removeValue(forKey: type)
    }

    public func render(type: String, data: AnyJSONValue) -> AnyView? {
        renderers[type]?(data)
    }

    public var registeredTypes: [String] { Array(renderers.keys).sorted() }

    // MARK: - Built-in widgets
    // Run `python3 tools/metrics.py` for an up-to-date count.

    private func registerBuiltins() {
        // KPI / number (1 widget, 3 variants: single/grid/score)
        register(type: "number") { AnyView(NumberWidgetView(data: $0)) }

        // Simple containers / display
        register(type: "chart") { AnyView(ChartWidgetView(data: $0)) }
        register(type: "todo") { AnyView(TodoWidgetView(data: $0)) }
        register(type: "calendar") { AnyView(CalendarWidgetView(data: $0)) }

        // Form (8)
        register(type: "input") { AnyView(InputWidgetView(data: $0)) }
        register(type: "numberInput") { AnyView(NumberInputWidgetView(data: $0)) }
        register(type: "dateInput") { AnyView(DateInputWidgetView(data: $0)) }
        register(type: "dropdown") { AnyView(DropdownWidgetView(data: $0)) }
        register(type: "toggle") { AnyView(ToggleWidgetView(data: $0)) }
        register(type: "slider") { AnyView(SliderWidgetView(data: $0)) }
        register(type: "checkbox") { AnyView(CheckboxWidgetView(data: $0)) }
        register(type: "formGroup") { AnyView(FormGroupWidgetView(data: $0)) }

        // Layout (5)
        register(type: "tabs") { AnyView(TabsWidgetView(data: $0)) }
        register(type: "accordion") { AnyView(AccordionWidgetView(data: $0)) }
        register(type: "carousel") { AnyView(CarouselWidgetView(data: $0)) }
        register(type: "grid") { AnyView(GridWidgetView(data: $0)) }
        register(type: "columns") { AnyView(ColumnsWidgetView(data: $0)) }

        // DataViz (6)
        register(type: "lineChart") { AnyView(LineChartWidgetView(data: $0)) }
        register(type: "pieChart") { AnyView(PieChartWidgetView(data: $0)) }
        register(type: "donutChart") { AnyView(DonutChartWidgetView(data: $0)) }
        register(type: "sparkline") { AnyView(SparklineWidgetView(data: $0)) }
        register(type: "progressBar") { AnyView(ProgressBarWidgetView(data: $0)) }
        register(type: "gauge") { AnyView(GaugeWidgetView(data: $0)) }

        // Time (3)
        register(type: "countdown") { AnyView(CountdownWidgetView(data: $0)) }
        register(type: "timeline") { AnyView(TimelineWidgetView(data: $0)) }
        register(type: "dayAgenda") { AnyView(DayAgendaWidgetView(data: $0)) }

        // Action (4)
        register(type: "approval") { AnyView(ApprovalWidgetView(data: $0)) }
        register(type: "confirmAction") { AnyView(ConfirmActionWidgetView(data: $0)) }
        register(type: "quickReply") { AnyView(QuickReplyWidgetView(data: $0)) }
        register(type: "cta") { AnyView(CtaWidgetView(data: $0)) }

        // Feedback (4)
        register(type: "toast") { AnyView(ToastWidgetView(data: $0)) }
        register(type: "infoBanner") { AnyView(InfoBannerWidgetView(data: $0)) }
        register(type: "errorCard") { AnyView(ErrorCardWidgetView(data: $0)) }
        register(type: "emptyState") { AnyView(EmptyStateWidgetView(data: $0)) }

        // Morphing / shared-element widgets (4) — interactive transitions
        register(type: "expandable") { AnyView(ExpandableWidgetView(data: $0)) }
        register(type: "morph") { AnyView(MorphWidgetView(data: $0)) }
        register(type: "flip") { AnyView(FlipWidgetView(data: $0)) }
        register(type: "interactive") { AnyView(InteractiveWidgetView(data: $0)) }

        // Primitives (13) — JSON-driven layout, no Swift needed for new arrangements
        register(type: "vstack") { AnyView(VStackPrimitive(data: $0)) }
        register(type: "hstack") { AnyView(HStackPrimitive(data: $0)) }
        register(type: "zstack") { AnyView(ZStackPrimitive(data: $0)) }
        register(type: "box") { AnyView(BoxPrimitive(data: $0)) }
        register(type: "text") { AnyView(TextPrimitive(data: $0)) }
        register(type: "icon") { AnyView(IconPrimitive(data: $0)) }
        register(type: "image") { AnyView(ImagePrimitive(data: $0)) }
        register(type: "spacer") { AnyView(SpacerPrimitive(data: $0)) }
        register(type: "divider") { AnyView(DividerPrimitive(data: $0)) }
        register(type: "card") { AnyView(CardPrimitive(data: $0)) }
        register(type: "pill") { AnyView(PillPrimitive(data: $0)) }
        register(type: "badge") { AnyView(BadgePrimitive(data: $0)) }
        register(type: "button") { AnyView(ButtonPrimitive(data: $0)) }
    }
}
