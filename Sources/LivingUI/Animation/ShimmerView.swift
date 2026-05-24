import SwiftUI

/// Animated linear-gradient shimmer used by skeleton placeholders while
/// streaming JSON is incomplete. Drop it as a `.mask(ShimmerView())` over any
/// shape or use the built-in `Shimmering` modifier.
public struct ShimmerView: View {
    @Environment(\.livingUITheme) private var theme
    var bandWidth: CGFloat = 120
    var duration: Double = 1.4

    public init(bandWidth: CGFloat = 120, duration: Double = 1.4) {
        self.bandWidth = bandWidth
        self.duration = duration
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            GeometryReader { geo in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let phase = (t.truncatingRemainder(dividingBy: duration)) / duration
                let xOffset = -geo.size.width + (geo.size.width + bandWidth) * 2 * CGFloat(phase)
                LinearGradient(
                    colors: [
                        theme.colors.surfaceAlt.opacity(0.0),
                        theme.colors.surfaceAlt.opacity(0.85),
                        theme.colors.surfaceAlt.opacity(0.0),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: bandWidth)
                .offset(x: xOffset)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .allowsHitTesting(false)
    }
}

/// `.shimmering()` modifier — wraps the view in a Shimmer overlay constrained
/// to its shape.
extension View {
    public func shimmering(active: Bool = true) -> some View {
        modifier(ShimmeringModifier(active: active))
    }
}

private struct ShimmeringModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    ShimmerView()
                        .blendMode(.plusLighter)
                        .mask(content)
                }
            }
    }
}
