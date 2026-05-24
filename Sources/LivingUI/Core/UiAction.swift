import Foundation

// MARK: - Local UI actions (mutate state without waking the agent)

/// The 6 mutations a user-driven block can perform on `UiConfigStore.state`
/// without sending a message to the LLM. Inspired by Redux-style atomic ops
/// but typed at the schema level.
public enum UiAction: Sendable, Hashable, Codable {
    case setState(path: String, value: AnyJSONValue)
    case toggleState(path: String)
    case incrementState(path: String, by: Double)
    case appendState(path: String, value: AnyJSONValue)
    case patchState(patch: [String: AnyJSONValue])
    case deleteState(path: String)

    private enum CodingKeys: String, CodingKey {
        case kind, path, value, by, patch
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try c.decode(String.self, forKey: .kind)
        switch kind {
        case "setState":
            self = .setState(
                path: try c.decode(String.self, forKey: .path),
                value: try c.decode(AnyJSONValue.self, forKey: .value)
            )
        case "toggleState":
            self = .toggleState(path: try c.decode(String.self, forKey: .path))
        case "incrementState":
            self = .incrementState(
                path: try c.decode(String.self, forKey: .path),
                by: (try? c.decode(Double.self, forKey: .by)) ?? 1
            )
        case "appendState":
            self = .appendState(
                path: try c.decode(String.self, forKey: .path),
                value: try c.decode(AnyJSONValue.self, forKey: .value)
            )
        case "patchState":
            self = .patchState(patch: try c.decode([String: AnyJSONValue].self, forKey: .patch))
        case "deleteState":
            self = .deleteState(path: try c.decode(String.self, forKey: .path))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: c,
                debugDescription: "Unknown UiAction kind: \(kind)")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .setState(let path, let value):
            try c.encode("setState", forKey: .kind)
            try c.encode(path, forKey: .path)
            try c.encode(value, forKey: .value)
        case .toggleState(let path):
            try c.encode("toggleState", forKey: .kind)
            try c.encode(path, forKey: .path)
        case .incrementState(let path, let by):
            try c.encode("incrementState", forKey: .kind)
            try c.encode(path, forKey: .path)
            try c.encode(by, forKey: .by)
        case .appendState(let path, let value):
            try c.encode("appendState", forKey: .kind)
            try c.encode(path, forKey: .path)
            try c.encode(value, forKey: .value)
        case .patchState(let patch):
            try c.encode("patchState", forKey: .kind)
            try c.encode(patch, forKey: .patch)
        case .deleteState(let path):
            try c.encode("deleteState", forKey: .kind)
            try c.encode(path, forKey: .path)
        }
    }
}

// MARK: - Apply UiAction to state (port of backend/src/uiconfig.ts logic)

public enum UiStateEngine {
    public static func apply(_ action: UiAction, to state: [String: AnyJSONValue]) -> [String: AnyJSONValue] {
        var next = state
        switch action {
        case .setState(let path, let value):
            setAtPath(&next, path: path, value: value)
        case .toggleState(let path):
            let current = getAtPath(next, path: path)
            let newValue: AnyJSONValue = (current?.bool ?? false) ? .bool(false) : .bool(true)
            setAtPath(&next, path: path, value: newValue)
        case .incrementState(let path, let by):
            let current = getAtPath(next, path: path)?.number ?? 0
            setAtPath(&next, path: path, value: .number(current + by))
        case .appendState(let path, let value):
            var arr = getAtPath(next, path: path)?.array ?? []
            arr.append(value)
            setAtPath(&next, path: path, value: .array(arr))
        case .patchState(let patch):
            for (k, v) in patch { next[k] = v }
        case .deleteState(let path):
            deleteAtPath(&next, path: path)
        }
        return next
    }

    private static func setAtPath(_ state: inout [String: AnyJSONValue], path: String, value: AnyJSONValue) {
        let segments = parsePath(path)
        guard !segments.isEmpty else { return }
        state = setRecursive(state: .object(state), segments: segments, value: value).object ?? state
    }

    private static func deleteAtPath(_ state: inout [String: AnyJSONValue], path: String) {
        let segments = parsePath(path)
        guard !segments.isEmpty else { return }
        state = deleteRecursive(state: .object(state), segments: segments).object ?? state
    }

    static func getAtPath(_ state: [String: AnyJSONValue], path: String) -> AnyJSONValue? {
        let segments = parsePath(path)
        var current: AnyJSONValue = .object(state)
        for seg in segments {
            switch seg {
            case .key(let k):
                guard case .object(let obj) = current, let v = obj[k] else { return nil }
                current = v
            case .index(let i):
                guard case .array(let arr) = current, arr.indices.contains(i) else { return nil }
                current = arr[i]
            }
        }
        return current
    }

    enum PathSegment { case key(String), index(Int) }

    static func parsePath(_ path: String) -> [PathSegment] {
        var out: [PathSegment] = []
        var buf = ""
        var i = path.startIndex
        while i < path.endIndex {
            let c = path[i]
            if c == "." {
                if !buf.isEmpty { out.append(.key(buf)); buf = "" }
            } else if c == "[" {
                if !buf.isEmpty { out.append(.key(buf)); buf = "" }
                var num = ""
                i = path.index(after: i)
                while i < path.endIndex, path[i] != "]" {
                    num.append(path[i])
                    i = path.index(after: i)
                }
                if let n = Int(num) { out.append(.index(n)) }
            } else {
                buf.append(c)
            }
            if i < path.endIndex { i = path.index(after: i) }
        }
        if !buf.isEmpty { out.append(.key(buf)) }
        return out
    }

    private static func setRecursive(state: AnyJSONValue, segments: [PathSegment], value: AnyJSONValue) -> AnyJSONValue {
        guard let head = segments.first else { return value }
        let tail = Array(segments.dropFirst())
        switch head {
        case .key(let k):
            var obj = state.object ?? [:]
            obj[k] = setRecursive(state: obj[k] ?? .null, segments: tail, value: value)
            return .object(obj)
        case .index(let i):
            var arr = state.array ?? []
            while arr.count <= i { arr.append(.null) }
            arr[i] = setRecursive(state: arr[i], segments: tail, value: value)
            return .array(arr)
        }
    }

    private static func deleteRecursive(state: AnyJSONValue, segments: [PathSegment]) -> AnyJSONValue {
        guard let head = segments.first else { return .null }
        let tail = Array(segments.dropFirst())
        if tail.isEmpty {
            switch head {
            case .key(let k):
                var obj = state.object ?? [:]
                obj.removeValue(forKey: k)
                return .object(obj)
            case .index(let i):
                var arr = state.array ?? []
                if arr.indices.contains(i) { arr.remove(at: i) }
                return .array(arr)
            }
        }
        switch head {
        case .key(let k):
            var obj = state.object ?? [:]
            if let inner = obj[k] {
                obj[k] = deleteRecursive(state: inner, segments: tail)
            }
            return .object(obj)
        case .index(let i):
            var arr = state.array ?? []
            if arr.indices.contains(i) {
                arr[i] = deleteRecursive(state: arr[i], segments: tail)
            }
            return .array(arr)
        }
    }
}
