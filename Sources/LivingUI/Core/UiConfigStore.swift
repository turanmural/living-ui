import Foundation
import Observation

/// Reactive store that holds the current `UiConfig`, applies streaming JSON
/// fragments, and tracks per-block highlight state for the "Жіп" hairline trace
/// (Phase 2.5 in Shymyr).
///
/// Lifecycle:
///   1. Create `let store = UiConfigStore()`
///   2. Call `store.update(jsonString:)` whenever your source has a complete JSON
///   3. Call `store.applyAction(_:)` from your view code when the user fires
///      a local UI action (setState/toggle/…); state mutates and triggers redraw
@MainActor
@Observable
public final class UiConfigStore {
    public private(set) var currentConfig: UiConfig
    public private(set) var rawJSON: String?
    public private(set) var highlightedBlockIds: Set<String> = []

    public init(initial: UiConfig = UiConfig()) {
        self.currentConfig = initial
    }

    /// Replace the full config from a JSON string. Best for whole snapshots.
    public func update(jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        decodeAndApply(data: data, rawJSON: jsonString)
    }

    /// Replace the full config from a raw object (e.g. already-parsed dictionary).
    public func update(object: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object) else { return }
        let raw = String(data: data, encoding: .utf8)
        decodeAndApply(data: data, rawJSON: raw)
    }

    /// Local action — mutates `currentConfig.state` in place without network.
    public func applyAction(_ action: UiAction) {
        let nextState = UiStateEngine.apply(action, to: currentConfig.state)
        currentConfig.state = nextState
    }

    /// Mark a block as highlighted (e.g. server-side diff said it changed).
    /// Views read this via `View.hairlineTrace(blockId:)`.
    public func highlight(blockIds: [String]) {
        for id in blockIds { highlightedBlockIds.insert(id) }
    }

    public func clearHighlight(_ id: String) {
        highlightedBlockIds.remove(id)
    }

    private func decodeAndApply(data: Data, rawJSON: String?) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        currentConfig = Self.decode(json: obj)
        self.rawJSON = rawJSON
    }

    static func decode(json: [String: Any]) -> UiConfig {
        let version = json["version"] as? Int ?? 2
        let themeActive = ((json["theme"] as? [String: Any])?["active"] as? String) ?? "warm"
        let fontScale = ((json["layout"] as? [String: Any])?["fontScale"] as? Double) ?? 1.0
        let appDict = json["app"] as? [String: Any] ?? [:]
        let home = appDict["home"] as? String ?? "home"
        let navArr = appDict["nav"] as? [[String: Any]] ?? []
        let nav: [NavItem] = navArr.map {
            NavItem(label: $0["label"] as? String ?? "",
                    icon: $0["icon"] as? String,
                    page: $0["page"] as? String ?? "")
        }
        let pagesDict = appDict["pages"] as? [String: Any] ?? [:]
        var pages: [String: PageSpec] = [:]
        for (k, v) in pagesDict {
            guard let pd = v as? [String: Any] else { continue }
            let title = pd["title"] as? String ?? ""
            let blocksArr = pd["blocks"] as? [[String: Any]] ?? []
            let blocks = blocksArr.compactMap { Self.decodeBlock($0) }
            pages[k] = PageSpec(title: title, blocks: blocks)
        }
        let stateDict = json["state"] as? [String: Any] ?? [:]
        let state = stateDict.compactMapValues { Self.encodeAsAnyJSON($0) }
        return UiConfig(
            version: version,
            theme: ThemeSpec(active: themeActive),
            layout: LayoutSpec(fontScale: fontScale),
            app: AppSpec(home: home, nav: nav, pages: pages),
            state: state
        )
    }

    private static func decodeBlock(_ dict: [String: Any]) -> Block? {
        let id = dict["id"] as? String ?? UUID().uuidString
        let type = dict["type"] as? String ?? "unknown"
        let raw = dict.compactMapValues { Self.encodeAsAnyJSON($0) }
        return Block(id: id, type: type, raw: raw)
    }

    private static func encodeAsAnyJSON(_ value: Any) -> AnyJSONValue? {
        if value is NSNull { return .null }
        if let b = value as? Bool { return .bool(b) }
        if let n = value as? NSNumber {
            // Distinguish Bool-bridged NSNumber from real numbers
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
                return .bool(n.boolValue)
            }
            return .number(n.doubleValue)
        }
        if let s = value as? String { return .string(s) }
        if let arr = value as? [Any] { return .array(arr.compactMap { encodeAsAnyJSON($0) }) }
        if let obj = value as? [String: Any] { return .object(obj.compactMapValues { encodeAsAnyJSON($0) }) }
        return nil
    }
}
