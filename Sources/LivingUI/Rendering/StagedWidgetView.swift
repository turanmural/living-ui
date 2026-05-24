import SwiftUI

/// Three-phase reveal for a freshly-arrived widget:
///   1. 220ms — skeleton scales 0.98 → 1.0 + fades in
///   2. 1000ms — skeleton holds (shimmer animates beneath)
///   3. 340ms — content cross-fades + slides 6pt up; skeleton fades out
///
/// Driven by the parent passing `isNew: true` on the first render after a
/// streaming widget closes its JSON fence.
public struct StagedWidgetView<Content: View>: View {
    public let skeletonShape: SkeletonShape
    public let isNew: Bool
    public let staggerIndex: Int
    @ViewBuilder public let content: () -> Content

    @State private var phase: Phase = .skeleton
    private enum Phase { case skeleton, hold, reveal }

    public init(
        skeletonShape: SkeletonShape,
        isNew: Bool,
        staggerIndex: Int = 0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.skeletonShape = skeletonShape
        self.isNew = isNew
        self.staggerIndex = staggerIndex
        self.content = content
    }

    public var body: some View {
        ZStack {
            if phase != .reveal {
                SkeletonView(shape: skeletonShape)
                    .scaleEffect(phase == .skeleton ? 0.98 : 1.0)
                    .opacity(phase == .skeleton ? 0 : 1)
                    .transition(.opacity)
            }
            if phase == .reveal {
                content()
                    .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .animation(.easeOut(duration: 0.22), value: phase == .skeleton)
        .animation(.easeInOut(duration: 0.34), value: phase == .reveal)
        .task(id: isNew) {
            guard isNew else { phase = .reveal; return }
            phase = .skeleton
            try? await Task.sleep(nanoseconds: UInt64(50_000_000 + staggerIndex * 80_000_000))
            phase = .hold
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            phase = .reveal
        }
    }
}
