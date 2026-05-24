import SwiftUI

// MARK: - Primitive layer
//
// 13 primitive widgets with full JSON styling. The library's "DivKit parity"
// surface — every visual decision (padding, color, font, alignment, border,
// shadow, frame) lives in JSON, so an agent can author arbitrary layouts
// without a code change.
//
// Common `style` object accepted by any primitive:
//
//   {
//     "fontSize": 24, "fontWeight": "bold", "color": "#FF6B35",
//     "alignment": "leading", "lineLimit": 2,
//     "padding": { "all": 12 } | { "horizontal": 16, "vertical": 8 } | { "top": 4, ... },
//     "background": "#F5EDE6", "cornerRadius": 12,
//     "border": { "color": "#CDB89C", "width": 0.6 },
//     "shadow": { "color": "#000", "opacity": 0.18, "radius": 8, "y": 4 },
//     "frame": { "width": 240, "height": 120, "maxWidth": .infinity, "minHeight": 44 },
//     "opacity": 0.92, "rotation": 8.5
//   }

// MARK: - VStack / HStack / ZStack containers

struct VStackPrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        let spacing = data.object?["spacing"]?.number ?? 8
        let alignment = horizontalAlignment(data.object?["alignment"]?.string)
        let stagger = data.object?["stagger"]?.number
        let children = data.object?["children"]?.array ?? []
        VStack(alignment: alignment, spacing: CGFloat(spacing)) {
            ForEach(Array(children.enumerated()), id: \.offset) { idx, c in
                renderPrimitiveChild(injectStagger(c, index: idx, perItem: stagger))
            }
        }
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

struct HStackPrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        let spacing = data.object?["spacing"]?.number ?? 8
        let alignment = verticalAlignment(data.object?["alignment"]?.string)
        let stagger = data.object?["stagger"]?.number
        let children = data.object?["children"]?.array ?? []
        HStack(alignment: alignment, spacing: CGFloat(spacing)) {
            ForEach(Array(children.enumerated()), id: \.offset) { idx, c in
                renderPrimitiveChild(injectStagger(c, index: idx, perItem: stagger))
            }
        }
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

struct ZStackPrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        let alignment = combinedAlignment(data.object?["alignment"]?.string)
        let children = data.object?["children"]?.array ?? []
        ZStack(alignment: alignment) {
            ForEach(Array(children.enumerated()), id: \.offset) { _, c in
                renderPrimitiveChild(c)
            }
        }
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

struct BoxPrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        let child = data.object?["child"] ?? data.object?["children"]?.array?.first
        Group {
            if let child { renderPrimitiveChild(child) } else { Color.clear }
        }
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

// MARK: - Atoms

struct TextPrimitive: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let text = data.object?["text"]?.string ?? ""
        let style = data.object?["style"]
        let fontSize = style?.object?["fontSize"]?.number ?? Double(theme.font.body)
        let weight = swiftFontWeight(style?.object?["fontWeight"]?.string)
        let color = resolveColor(style?.object?["color"]?.string, fallback: theme.colors.text)
        let lineLimit = style?.object?["lineLimit"]?.number.map { Int($0) }
        let alignment = textAlignment(style?.object?["alignment"]?.string)
        Text(text)
            .font(.system(size: CGFloat(fontSize), weight: weight))
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
            .applyPrimitiveStyle(style)
            .livingUIAnimations(from: data)
    }
}

struct IconPrimitive: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let name = data.object?["name"]?.string ?? "questionmark"
        let style = data.object?["style"]
        let size = style?.object?["fontSize"]?.number ?? data.object?["size"]?.number ?? 18
        let weight = swiftFontWeight(style?.object?["fontWeight"]?.string)
        let color = resolveColor(style?.object?["color"]?.string, fallback: theme.colors.primary)
        let effect = data.object?["effect"]?.string
        Image(systemName: name)
            .font(.system(size: CGFloat(size), weight: weight))
            .foregroundStyle(color)
            .livingUISymbolEffect(effect)
            .applyPrimitiveStyle(style)
            .livingUIAnimations(from: data)
    }
}

struct ImagePrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        let url = data.object?["url"]?.string ?? ""
        let height = data.object?["height"]?.number
        let width = data.object?["width"]?.number
        AsyncImage(url: URL(string: url)) { img in
            img.resizable().scaledToFill()
        } placeholder: {
            Rectangle().fill(Color.gray.opacity(0.18))
        }
        .frame(width: width.map { CGFloat($0) }, height: height.map { CGFloat($0) })
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

struct SpacerPrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        if let size = data.object?["size"]?.number {
            Color.clear.frame(width: CGFloat(size), height: CGFloat(size))
        } else {
            Spacer(minLength: 0)
        }
    }
}

struct DividerPrimitive: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let color = resolveColor(data.object?["color"]?.string, fallback: theme.colors.border)
        let thickness = data.object?["thickness"]?.number ?? 0.5
        Rectangle()
            .fill(color)
            .frame(height: CGFloat(thickness))
            .applyPrimitiveStyle(data.object?["style"])
    }
}

// MARK: - Compositions

struct CardPrimitive: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let style = (data.object?["style"]?.object ?? [:]).merging([
            "padding": .object(["all": .number(16)]),
            "background": data.object?["background"] ?? .string(themeSurfaceHex(theme: theme)),
            "cornerRadius": .number(18),
            "border": .object([
                "color": .string("#00000010"), "width": .number(0.5)
            ])
        ], uniquingKeysWith: { existing, _ in existing })
        let mergedStyle: AnyJSONValue = .object(style)
        let children = data.object?["children"]?.array ?? []
        let stagger = data.object?["stagger"]?.number
        VStack(alignment: .leading, spacing: data.object?["spacing"]?.number.map { CGFloat($0) } ?? 8) {
            ForEach(Array(children.enumerated()), id: \.offset) { idx, c in
                renderPrimitiveChild(injectStagger(c, index: idx, perItem: stagger))
            }
        }
        .applyPrimitiveStyle(mergedStyle)
        .livingUIAnimations(from: data)
    }

    private func themeSurfaceHex(theme: LivingUITheme) -> String {
        theme.isDark ? "#1A1428" : "#FFFFFF"
    }
}

struct PillPrimitive: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let text = data.object?["text"]?.string ?? ""
        let bg = resolveColor(data.object?["background"]?.string,
                              fallback: theme.colors.primary.opacity(0.18))
        let fg = resolveColor(data.object?["color"]?.string, fallback: theme.colors.primary)
        Text(text)
            .font(.system(size: theme.font.caption1, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(bg))
            .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

struct BadgePrimitive: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue
    var body: some View {
        let text = data.object?["text"]?.string ?? ""
        let icon = data.object?["icon"]?.string
        let bg = resolveColor(data.object?["background"]?.string,
                              fallback: theme.colors.accent.opacity(0.18))
        let fg = resolveColor(data.object?["color"]?.string, fallback: theme.colors.accent)
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.system(size: 10, weight: .bold)) }
            Text(text).font(.system(size: theme.font.caption2, weight: .bold))
        }
        .foregroundStyle(fg)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(bg))
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

struct ButtonPrimitive: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(\.livingUIDispatcher) private var dispatcher
    let data: AnyJSONValue
    var body: some View {
        let label = data.object?["label"]?.string ?? ""
        let icon = data.object?["icon"]?.string
        let action = data.object?["action"]
        let style = data.object?["style"]
        Button {
            fireAction(action, dispatcher: dispatcher)
        } label: {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon) }
                Text(label).font(.system(size: theme.font.callout, weight: .semibold))
            }
            .foregroundStyle(resolveColor(style?.object?["color"]?.string, fallback: theme.colors.onPrimary))
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Capsule().fill(resolveColor(
                style?.object?["background"]?.string,
                fallback: theme.colors.primary
            )))
            .applyPrimitiveStyle(style)
        }
        .buttonStyle(.plain)
        .livingUIAnimations(from: data)
    }
}

struct GridPrimitive: View {
    let data: AnyJSONValue
    var body: some View {
        let columns = Int(data.object?["columns"]?.number ?? 2)
        let spacing = data.object?["spacing"]?.number ?? 10
        let stagger = data.object?["stagger"]?.number
        let children = data.object?["children"]?.array ?? []
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: CGFloat(spacing)), count: columns),
            spacing: CGFloat(spacing)
        ) {
            ForEach(Array(children.enumerated()), id: \.offset) { idx, c in
                renderPrimitiveChild(injectStagger(c, index: idx, perItem: stagger))
            }
        }
        .applyPrimitiveStyle(data.object?["style"])
        .livingUIAnimations(from: data)
    }
}

// MARK: - Style application

extension View {
    @ViewBuilder
    fileprivate func applyPrimitiveStyle(_ style: AnyJSONValue?) -> some View {
        let obj = style?.object ?? [:]
        self
            .modifier(PaddingModifier(spec: obj["padding"]))
            .modifier(BackgroundModifier(spec: obj["background"], cornerRadius: obj["cornerRadius"]?.number))
            .modifier(BorderModifier(spec: obj["border"], cornerRadius: obj["cornerRadius"]?.number))
            .modifier(FrameModifier(spec: obj["frame"]))
            .modifier(ShadowModifier(spec: obj["shadow"]))
            .modifier(OpacityRotationModifier(opacity: obj["opacity"]?.number,
                                              rotation: obj["rotation"]?.number))
    }
}

private struct PaddingModifier: ViewModifier {
    let spec: AnyJSONValue?
    func body(content: Content) -> some View {
        guard let obj = spec?.object else { return AnyView(content) }
        let all = obj["all"]?.number
        let horizontal = obj["horizontal"]?.number ?? all
        let vertical = obj["vertical"]?.number ?? all
        let top = obj["top"]?.number ?? vertical
        let bottom = obj["bottom"]?.number ?? vertical
        let leading = obj["leading"]?.number ?? horizontal
        let trailing = obj["trailing"]?.number ?? horizontal
        return AnyView(
            content
                .padding(.top, top.map { CGFloat($0) } ?? 0)
                .padding(.bottom, bottom.map { CGFloat($0) } ?? 0)
                .padding(.leading, leading.map { CGFloat($0) } ?? 0)
                .padding(.trailing, trailing.map { CGFloat($0) } ?? 0)
        )
    }
}

private struct BackgroundModifier: ViewModifier {
    let spec: AnyJSONValue?
    let cornerRadius: Double?
    func body(content: Content) -> some View {
        guard let hex = spec?.string else { return AnyView(content) }
        let color = Color(hex: hex)
        let radius = CGFloat(cornerRadius ?? 0)
        return AnyView(
            content.background(
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(color)
            )
        )
    }
}

private struct BorderModifier: ViewModifier {
    let spec: AnyJSONValue?
    let cornerRadius: Double?
    func body(content: Content) -> some View {
        guard let obj = spec?.object,
              let colorHex = obj["color"]?.string else { return AnyView(content) }
        let width = obj["width"]?.number ?? 0.5
        let radius = CGFloat(cornerRadius ?? 0)
        return AnyView(
            content.overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color(hex: colorHex), lineWidth: CGFloat(width))
            )
        )
    }
}

private struct FrameModifier: ViewModifier {
    let spec: AnyJSONValue?
    func body(content: Content) -> some View {
        guard let obj = spec?.object else { return AnyView(content) }
        let width = obj["width"]?.number.map { CGFloat($0) }
        let height = obj["height"]?.number.map { CGFloat($0) }
        let maxWidth = obj["maxWidth"]?.number.map { CGFloat($0) }
        let minHeight = obj["minHeight"]?.number.map { CGFloat($0) }
        return AnyView(
            content.frame(
                width: width,
                height: height
            ).frame(
                maxWidth: maxWidth ?? (obj["maxWidth"]?.string == "infinity" ? .infinity : nil),
                minHeight: minHeight
            )
        )
    }
}

private struct ShadowModifier: ViewModifier {
    let spec: AnyJSONValue?
    func body(content: Content) -> some View {
        guard let obj = spec?.object else { return AnyView(content) }
        let colorHex = obj["color"]?.string ?? "#000000"
        let opacity = obj["opacity"]?.number ?? 0.2
        let radius = obj["radius"]?.number ?? 8
        let x = obj["x"]?.number ?? 0
        let y = obj["y"]?.number ?? 2
        return AnyView(
            content.shadow(
                color: Color(hex: colorHex).opacity(opacity),
                radius: CGFloat(radius), x: CGFloat(x), y: CGFloat(y)
            )
        )
    }
}

private struct OpacityRotationModifier: ViewModifier {
    let opacity: Double?
    let rotation: Double?
    func body(content: Content) -> some View {
        content
            .opacity(opacity ?? 1)
            .rotationEffect(.degrees(rotation ?? 0))
    }
}

// MARK: - Helpers

@MainActor
@ViewBuilder
private func renderPrimitiveChild(_ value: AnyJSONValue) -> some View {
    let type = value.object?["type"]?.string ?? ""
    if let view = WidgetCatalog.shared.render(type: type, data: value) {
        view
    } else {
        EmptyView()
    }
}

/// If the parent container has a `stagger` value (delay per child in seconds),
/// inject `staggerIndex` and `staggerDelay` into each child so its animation
/// modifier picks them up.
func injectStagger(_ child: AnyJSONValue, index: Int, perItem: Double?) -> AnyJSONValue {
    guard let perItem else { return child }
    guard case .object(var obj) = child else { return child }
    obj["staggerIndex"] = .number(Double(index))
    obj["staggerDelay"] = .number(perItem)
    return .object(obj)
}

private func resolveColor(_ hex: String?, fallback: Color) -> Color {
    guard let hex, !hex.isEmpty else { return fallback }
    // Support `rgba(r,g,b,a)` too (just for compat — main usage is hex)
    if hex.hasPrefix("rgba") {
        let nums = hex
            .replacingOccurrences(of: "rgba(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        if nums.count == 4 {
            return Color(red: nums[0] / 255, green: nums[1] / 255, blue: nums[2] / 255).opacity(nums[3])
        }
    }
    return Color(hex: hex)
}

private func swiftFontWeight(_ s: String?) -> Font.Weight {
    switch s {
    case "ultraLight": return .ultraLight
    case "thin":       return .thin
    case "light":      return .light
    case "regular":    return .regular
    case "medium":     return .medium
    case "semibold":   return .semibold
    case "bold":       return .bold
    case "heavy":      return .heavy
    case "black":      return .black
    default:           return .regular
    }
}

private func horizontalAlignment(_ s: String?) -> HorizontalAlignment {
    switch s {
    case "center": return .center
    case "trailing", "right": return .trailing
    default: return .leading
    }
}

private func verticalAlignment(_ s: String?) -> VerticalAlignment {
    switch s {
    case "top": return .top
    case "bottom": return .bottom
    case "firstTextBaseline": return .firstTextBaseline
    default: return .center
    }
}

private func combinedAlignment(_ s: String?) -> Alignment {
    switch s {
    case "topLeading": return .topLeading
    case "top": return .top
    case "topTrailing": return .topTrailing
    case "leading": return .leading
    case "trailing": return .trailing
    case "bottomLeading": return .bottomLeading
    case "bottom": return .bottom
    case "bottomTrailing": return .bottomTrailing
    default: return .center
    }
}

private func textAlignment(_ s: String?) -> TextAlignment {
    switch s {
    case "center": return .center
    case "trailing", "right": return .trailing
    default: return .leading
    }
}

@MainActor
private func fireAction(_ action: AnyJSONValue?, dispatcher: any LivingUIActionHandler) {
    guard let obj = action?.object else { return }
    if let kind = obj["kind"]?.string {
        switch kind {
        case "prompt": dispatcher.dispatch(.prompt(text: obj["text"]?.string ?? ""))
        case "navigate": dispatcher.dispatch(.navigate(page: obj["page"]?.string ?? ""))
        default: break
        }
    } else if let actionId = obj["actionId"]?.string {
        dispatcher.dispatch(.structuredAction(id: actionId, value: obj["value"]))
    }
}
