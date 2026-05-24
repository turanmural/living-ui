import SwiftUI
import Observation

/// Tracks the one widget currently expanded into a full-screen modal-style
/// overlay. Drives the hero-style morph transition between the compact source
/// view (left in the page flow) and the expanded destination view (overlaid
/// in `LivingUIView`'s ZStack root). One expansion at a time — like Apple's
/// iOS App Store card-to-detail morph.
@MainActor
@Observable
public final class ExpansionStore {
    public var expanded: Item?

    public struct Item: Identifiable, Sendable, Hashable {
        public let id: String         // hero / matched-geometry id
        public let json: AnyJSONValue // the `expanded` JSON tree
        public let cornerRadius: Double
    }

    public init() {}

    public func expand(id: String, json: AnyJSONValue, cornerRadius: Double = 24) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            expanded = Item(id: id, json: json, cornerRadius: cornerRadius)
        }
    }

    public func dismiss() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            expanded = nil
        }
    }
}
