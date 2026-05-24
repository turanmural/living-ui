import Foundation
import SwiftUI

// MARK: - Block — a single piece of a page

/// Renderable element inside a `PageSpec.blocks` array. The discriminator is
/// the `type` field in JSON. Unknown types decode as `.unknown` and render
/// as a small debug card.
public struct Block: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var type: String
    public var raw: [String: AnyJSONValue]

    public init(id: String, type: String, raw: [String: AnyJSONValue] = [:]) {
        self.id = id
        self.type = type
        self.raw = raw
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: DynamicKey.self)
        var dict: [String: AnyJSONValue] = [:]
        for key in c.allKeys {
            if let v = try? c.decode(AnyJSONValue.self, forKey: key) {
                dict[key.stringValue] = v
            }
        }
        self.type = (dict["type"]?.string ?? "unknown")
        self.id = (dict["id"]?.string ?? UUID().uuidString)
        self.raw = dict
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: DynamicKey.self)
        for (k, v) in raw {
            try c.encode(v, forKey: DynamicKey(stringValue: k))
        }
    }
}

struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

// MARK: - AnyJSONValue codable

extension AnyJSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let arr = try? c.decode([AnyJSONValue].self) { self = .array(arr); return }
        if let obj = try? c.decode([String: AnyJSONValue].self) { self = .object(obj); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n): try c.encode(n)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var number: Double? { if case .number(let n) = self { return n }; return nil }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
    public var array: [AnyJSONValue]? { if case .array(let a) = self { return a }; return nil }
    public var object: [String: AnyJSONValue]? { if case .object(let o) = self { return o }; return nil }
}
