import SwiftUI

/// Subtle amber-pulse overlay marking blocks the agent (or an overnight
/// regeneration) just added/changed. Auto-clears from the store after 1.2s
/// so the highlight is single-use per render.
struct HairlineTraceModifier: ViewModifier {
    @Environment(UiConfigStore.self) private var store
    let blockId: String

    func body(content: Content) -> some View {
        let isHighlighted = store.highlightedBlockIds.contains(blockId)
        content
            .overlay {
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.livingUIAmber, lineWidth: 1.4)
                        .shadow(color: Color.livingUIAmber.opacity(0.5), radius: 14, x: 0, y: 0)
                        .transition(.opacity)
                }
            }
            .task(id: isHighlighted) {
                if isHighlighted {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    store.clearHighlight(blockId)
                }
            }
            .animation(.snappy, value: isHighlighted)
    }
}

extension View {
    /// Apply hairline-trace highlight if the block id is currently flagged.
    public func hairlineTrace(blockId: String) -> some View {
        modifier(HairlineTraceModifier(blockId: blockId))
    }
}

extension Color {
    static var livingUIAmber: Color { Color(red: 1.0, green: 0.74, blue: 0.27) }
}
