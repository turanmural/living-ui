import SwiftUI

/// Visual tokens consumed by all built-in renderers. Override the whole theme
/// via `.environment(\.livingUITheme, myTheme)` to brand the rendered UI.
public struct LivingUITheme: Sendable {
    public var name: String
    public var isDark: Bool
    public var colors: Colors
    public var font: Fonts
    public var radii: Radii
    public var spacing: Spacing

    public init(
        name: String,
        isDark: Bool,
        colors: Colors,
        font: Fonts = .default,
        radii: Radii = .default,
        spacing: Spacing = .default
    ) {
        self.name = name
        self.isDark = isDark
        self.colors = colors
        self.font = font
        self.radii = radii
        self.spacing = spacing
    }

    public struct Colors: Sendable {
        public var bg: Color
        public var bgGradient: LinearGradient
        public var surface: Color
        public var surfaceAlt: Color
        public var text: Color
        public var textMuted: Color
        public var primary: Color
        public var accent: Color
        public var success: Color
        public var error: Color
        public var border: Color
        public var onPrimary: Color

        public init(
            bg: Color, bgGradient: LinearGradient, surface: Color, surfaceAlt: Color,
            text: Color, textMuted: Color, primary: Color, accent: Color,
            success: Color, error: Color, border: Color, onPrimary: Color
        ) {
            self.bg = bg; self.bgGradient = bgGradient
            self.surface = surface; self.surfaceAlt = surfaceAlt
            self.text = text; self.textMuted = textMuted
            self.primary = primary; self.accent = accent
            self.success = success; self.error = error
            self.border = border; self.onPrimary = onPrimary
        }
    }

    public struct Fonts: Sendable {
        public var caption2: CGFloat = 11
        public var caption1: CGFloat = 13
        public var body: CGFloat = 16
        public var callout: CGFloat = 17
        public var subhead: CGFloat = 15
        public var headline: CGFloat = 17
        public var title3: CGFloat = 20
        public var title2: CGFloat = 24
        public var title1: CGFloat = 28
        public static let `default` = Fonts()
    }

    public struct Radii: Sendable {
        public var sm: CGFloat = 8
        public var md: CGFloat = 12
        public var lg: CGFloat = 18
        public var xl: CGFloat = 28
        public static let `default` = Radii()
    }

    public struct Spacing: Sendable {
        public var xs: CGFloat = 4
        public var sm: CGFloat = 8
        public var md: CGFloat = 12
        public var lg: CGFloat = 16
        public var xl: CGFloat = 24
        public static let `default` = Spacing()
    }

    public static let warm = LivingUITheme(
        name: "warm",
        isDark: false,
        colors: .init(
            bg: Color(hex: "#F5EDE6"),
            bgGradient: LinearGradient(colors: [Color(hex: "#F5EDE6"), Color(hex: "#E9DDD0")],
                                       startPoint: .top, endPoint: .bottom),
            surface: Color(hex: "#FFFFFF"),
            surfaceAlt: Color(hex: "#EEE3D6"),
            text: Color(hex: "#221814"),
            textMuted: Color(hex: "#7B6A5E"),
            primary: Color(hex: "#E8745B"),
            accent: Color(hex: "#F1A86E"),
            success: Color(hex: "#3DA56A"),
            error: Color(hex: "#D14C4C"),
            border: Color(hex: "#CDB89C"),
            onPrimary: Color.white
        )
    )

    public static let glass = LivingUITheme(
        name: "glass",
        isDark: true,
        colors: .init(
            bg: Color(hex: "#0E0B1A"),
            bgGradient: LinearGradient(colors: [Color(hex: "#0E0B1A"), Color(hex: "#1C1438")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
            surface: Color.white.opacity(0.07),
            surfaceAlt: Color.white.opacity(0.04),
            text: Color.white.opacity(0.94),
            textMuted: Color.white.opacity(0.55),
            primary: Color(hex: "#A78BFA"),
            accent: Color(hex: "#C4B5FD"),
            success: Color(hex: "#4ADE80"),
            error: Color(hex: "#F87171"),
            border: Color.white.opacity(0.18),
            onPrimary: Color(hex: "#150A2A")
        )
    )

    public static func from(name: String) -> LivingUITheme {
        switch name { case "glass": return .glass; default: return .warm }
    }
}

// MARK: - Environment

private struct LivingUIThemeKey: EnvironmentKey {
    static let defaultValue: LivingUITheme = .warm
}

extension EnvironmentValues {
    public var livingUITheme: LivingUITheme {
        get { self[LivingUIThemeKey.self] }
        set { self[LivingUIThemeKey.self] = newValue }
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        var s = hex.replacingOccurrences(of: "#", with: "")
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
