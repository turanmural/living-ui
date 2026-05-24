import SwiftUI

/// Optional background view that gently breathes at 14 cycles/min (idle) or
/// 8 cycles/min (when the agent is actively streaming). Use it behind chat or
/// space surfaces to give the impression of a living, attentive companion.
public struct BreathingBackground: View {
    @Environment(\.livingUITheme) private var theme
    public var isThinking: Bool

    public init(isThinking: Bool = false) {
        self.isThinking = isThinking
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period: Double = isThinking ? (60.0 / 8.0) : (60.0 / 14.0)
            let phase = (sin(2 * .pi * t.truncatingRemainder(dividingBy: period) / period) + 1) / 2

            theme.colors.bgGradient
                .saturation(1.0 + 0.04 * phase)
                .brightness(0.03 * phase)
                .ignoresSafeArea()
        }
    }
}
