import SwiftUI

// MARK: - Animation specs parsed from JSON
//
// Every primitive may carry an optional `animate`, `transition`, `loop`,
// `hero`, `effect`, or `stagger` field. They map to native SwiftUI primitives
// (KeyframeAnimator, matchedGeometryEffect, symbolEffect, phaseAnimator)
// so an agent can write After-Effects-style choreography in JSON.

public enum AnimationSpec {

    // MARK: - Entrance transition

    public enum Transition: String, Sendable {
        case fade, rise, slide, scale, morph, blur, sparkle
        public static func parse(_ s: String?) -> Transition? {
            guard let s, let t = Transition(rawValue: s) else { return nil }
            return t
        }
    }

    // MARK: - Looping ambient animation

    public struct Loop: Sendable {
        public enum Kind: String, Sendable { case pulse, breathe, wobble, rotate, shimmer, glow }
        public let kind: Kind
        public let duration: Double
        public let amplitude: Double

        public init?(_ json: AnyJSONValue?) {
            guard let obj = json?.object,
                  let k = obj["type"]?.string ?? obj["kind"]?.string,
                  let kind = Kind(rawValue: k) else { return nil }
            self.kind = kind
            self.duration = obj["duration"]?.number ?? 1.4
            self.amplitude = obj["amplitude"]?.number ?? 1.0
        }
    }

    // MARK: - SF Symbol effects

    public enum SymbolEffect: String, Sendable {
        case bounce, pulse, wiggle, scale, appear, disappear, replace
        public static func parse(_ s: String?) -> SymbolEffect? {
            guard let s, let e = SymbolEffect(rawValue: s) else { return nil }
            return e
        }
    }

    // MARK: - Keyframe track (After Effects style)

    public struct KeyframeProgram: Sendable {
        public let tracks: [Track]

        public struct Track: Sendable {
            public let property: Property
            public let keyframes: [Keyframe]
        }

        public struct Keyframe: Sendable {
            public let t: Double           // time in seconds (cumulative)
            public let value: Double
            public let curve: Curve

            public enum Curve: String, Sendable { case linear, ease, spring, move }
        }

        public enum Property: String, Sendable, Hashable {
            case opacity, scale, scaleX, scaleY
            case offsetX, offsetY
            case rotation
            case blur
            case brightness, saturation
        }

        public init?(_ json: AnyJSONValue?) {
            guard let tracksRaw = json?.object?["tracks"]?.array else { return nil }
            var parsed: [Track] = []
            for t in tracksRaw {
                guard let propStr = t.object?["property"]?.string,
                      let property = Property(rawValue: propStr) else { continue }
                let keysRaw = t.object?["keyframes"]?.array ?? []
                let keys: [Keyframe] = keysRaw.compactMap { k in
                    guard let time = k.object?["t"]?.number,
                          let value = k.object?["v"]?.number ?? k.object?["value"]?.number else { return nil }
                    let curveStr = k.object?["curve"]?.string ?? (k.object?["spring"]?.bool == true ? "spring" : "ease")
                    return Keyframe(
                        t: time, value: value,
                        curve: Keyframe.Curve(rawValue: curveStr) ?? .ease
                    )
                }
                if !keys.isEmpty { parsed.append(Track(property: property, keyframes: keys)) }
            }
            guard !parsed.isEmpty else { return nil }
            self.tracks = parsed
        }

        /// Total duration = max track end time
        public var totalDuration: Double {
            tracks.map { $0.keyframes.last?.t ?? 0 }.max() ?? 0
        }
    }
}

// MARK: - View modifiers consuming JSON specs

extension View {
    /// Apply all animation specs found in a primitive's JSON node:
    /// `transition`, `animate` (keyframes), `loop`, `hero`, `effect`, `stagger`.
    @ViewBuilder
    public func livingUIAnimations(from json: AnyJSONValue?) -> some View {
        if let obj = json?.object {
            self
                .modifier(EntranceTransitionModifier(spec: obj["transition"]?.string))
                .modifier(KeyframeAnimationModifier(spec: obj["animate"]))
                .modifier(LoopAnimationModifier(spec: obj["loop"]))
                .modifier(HeroModifier(heroId: obj["hero"]?.string))
                .modifier(StaggerEntranceModifier(
                    indexJSON: obj["staggerIndex"]?.number,
                    delayJSON: obj["staggerDelay"]?.number
                ))
        } else {
            self
        }
    }
}

// MARK: - Entrance transitions

private struct EntranceTransitionModifier: ViewModifier {
    let spec: String?
    @State private var appeared: Bool = false

    func body(content: Content) -> some View {
        let kind = AnimationSpec.Transition.parse(spec)
        return content
            .opacity(appeared || kind == nil ? 1 : 0)
            .scaleEffect(scaleFor(kind))
            .offset(y: offsetYFor(kind))
            .blur(radius: blurFor(kind))
            .onAppear {
                guard kind != nil, !appeared else { return }
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    appeared = true
                }
            }
    }

    private func scaleFor(_ kind: AnimationSpec.Transition?) -> CGFloat {
        guard let kind, !appeared else { return 1 }
        switch kind {
        case .scale, .sparkle: return 0.85
        case .morph:           return 1.05
        default:               return 1
        }
    }
    private func offsetYFor(_ kind: AnimationSpec.Transition?) -> CGFloat {
        guard let kind, !appeared else { return 0 }
        switch kind {
        case .rise:  return 12
        case .slide: return 24
        default:     return 0
        }
    }
    private func blurFor(_ kind: AnimationSpec.Transition?) -> CGFloat {
        guard let kind, !appeared else { return 0 }
        return kind == .blur ? 18 : 0
    }
}

// MARK: - Keyframe (After Effects style)

private struct KeyframeAnimationModifier: ViewModifier {
    let spec: AnyJSONValue?

    func body(content: Content) -> some View {
        guard let program = AnimationSpec.KeyframeProgram(spec) else {
            return AnyView(content)
        }
        // Apply each track via its own per-Double keyframeAnimator, layered
        // through ViewModifier composition. SwiftUI handles them independently
        // and they all start when the view first appears.
        var built: AnyView = AnyView(content)
        for track in program.tracks {
            built = AnyView(built.modifier(SingleTrackModifier(track: track)))
        }
        return built
    }
}

private struct SingleTrackModifier: ViewModifier {
    let track: AnimationSpec.KeyframeProgram.Track

    func body(content: Content) -> some View {
        let initialValue = track.keyframes.first?.value ?? defaultInitial(for: track.property)
        let property = track.property
        let frames = track.keyframes
        return content.keyframeAnimator(
            initialValue: initialValue,
            content: { view, value in
                AnyView(
                    Group {
                        switch property {
                        case .opacity:    view.opacity(value)
                        case .scale:      view.scaleEffect(value)
                        case .scaleX:     view.scaleEffect(x: value, y: 1, anchor: .center)
                        case .scaleY:     view.scaleEffect(x: 1, y: value, anchor: .center)
                        case .offsetX:    view.offset(x: value, y: 0)
                        case .offsetY:    view.offset(x: 0, y: value)
                        case .rotation:   view.rotationEffect(.degrees(value))
                        case .blur:       view.blur(radius: value)
                        case .brightness: view.brightness(value)
                        case .saturation: view.saturation(value)
                        }
                    }
                )
            },
            keyframes: { _ in
                for f in frames {
                    switch f.curve {
                    case .spring: SpringKeyframe(f.value, duration: f.t)
                    case .linear: LinearKeyframe(f.value, duration: f.t)
                    case .move:   MoveKeyframe(f.value)
                    case .ease:   CubicKeyframe(f.value, duration: f.t)
                    }
                }
            }
        )
    }

    private func defaultInitial(for property: AnimationSpec.KeyframeProgram.Property) -> Double {
        switch property {
        case .opacity, .scale, .scaleX, .scaleY, .saturation: return 1
        default: return 0
        }
    }
}

// MARK: - Loop (ambient looping)

private struct LoopAnimationModifier: ViewModifier {
    let spec: AnyJSONValue?

    func body(content: Content) -> some View {
        guard let loop = AnimationSpec.Loop(spec) else { return AnyView(content) }
        return AnyView(
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let period = max(0.2, loop.duration)
                let phase = sin(2 * .pi * t.truncatingRemainder(dividingBy: period) / period)
                let amplitude = loop.amplitude
                switch loop.kind {
                case .pulse:    content.scaleEffect(1.0 + 0.05 * phase * amplitude)
                case .breathe:  content.opacity(0.78 + 0.22 * (0.5 + 0.5 * phase) * amplitude)
                case .wobble:   content.rotationEffect(.degrees(4 * phase * amplitude))
                case .rotate:   content.rotationEffect(.degrees(360 * (t.truncatingRemainder(dividingBy: period) / period) * amplitude))
                case .shimmer:  content.brightness(0.06 * phase * amplitude)
                case .glow:     content.shadow(color: .yellow.opacity(0.4 * (0.5 + 0.5 * phase) * amplitude), radius: 16)
                }
            }
        )
    }
}

// MARK: - Hero (shared element via matched geometry)

/// Provides the `Namespace.ID` that powers `matchedGeometryEffect` across
/// LivingUIView renders. Hosts can override by passing their own namespace.
public struct HeroNamespaceProvider<Content: View>: View {
    @Namespace private var ns
    @ViewBuilder var content: (Namespace.ID) -> Content

    public init(@ViewBuilder content: @escaping (Namespace.ID) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(ns)
            .environment(\.livingUIHeroNamespace, ns)
    }
}

private struct HeroNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    public var livingUIHeroNamespace: Namespace.ID? {
        get { self[HeroNamespaceKey.self] }
        set { self[HeroNamespaceKey.self] = newValue }
    }
}

private struct HeroModifier: ViewModifier {
    @Environment(\.livingUIHeroNamespace) private var ns
    let heroId: String?

    func body(content: Content) -> some View {
        if let heroId, !heroId.isEmpty, let ns {
            content.matchedGeometryEffect(id: heroId, in: ns)
        } else {
            content
        }
    }
}

// MARK: - Stagger choreography

private struct StaggerEntranceModifier: ViewModifier {
    let indexJSON: Double?
    let delayJSON: Double?
    @State private var appeared: Bool = false

    func body(content: Content) -> some View {
        guard let idx = indexJSON, idx >= 0 else { return AnyView(content) }
        let perItem = delayJSON ?? 0.06
        let total = perItem * idx
        return AnyView(
            content
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + total) {
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            appeared = true
                        }
                    }
                }
        )
    }
}

// MARK: - Symbol effect helper (used by icon primitive directly)

extension View {
    /// Apply SF Symbol-aware repeating effects. iOS 17+ supports `.bounce` /
    /// `.pulse` / `.wiggle`; on macOS-host builds (which only have access to
    /// macOS 14 by default in this package) we fall back to a no-op so the
    /// shared module still compiles.
    @ViewBuilder
    public func livingUISymbolEffect(_ raw: String?) -> some View {
        #if os(iOS) || os(visionOS) || os(tvOS) || os(watchOS)
        let effect = AnimationSpec.SymbolEffect.parse(raw)
        switch effect {
        case .bounce:
            if #available(iOS 18.0, *) {
                self.symbolEffect(.bounce, options: .repeating)
            } else {
                self.symbolEffect(.pulse, options: .repeating)
            }
        case .pulse:
            self.symbolEffect(.pulse, options: .repeating)
        case .wiggle:
            if #available(iOS 18.0, *) {
                self.symbolEffect(.wiggle, options: .repeating)
            } else {
                self.symbolEffect(.pulse, options: .repeating)
            }
        default:
            self
        }
        #else
        self
        #endif
    }
}
