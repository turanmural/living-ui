import SwiftUI

/// `.livingUIGlass()` modifier — adds Apple's `.ultraThinMaterial` blur in
/// a rounded rectangle, scaled to the active theme's surface tint and corner
/// radius. Falls back to a translucent fill on older OS versions.
extension View {
    public func livingUIGlass(cornerRadius: CGFloat = 18) -> some View {
        modifier(GlassEffectModifier(cornerRadius: cornerRadius))
    }
}

private struct GlassEffectModifier: ViewModifier {
    @Environment(\.livingUITheme) private var theme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.colors.surface.opacity(theme.isDark ? 0.5 : 0.78))
                    .background(.ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.colors.border.opacity(0.55), lineWidth: 0.6)
            }
    }
}
