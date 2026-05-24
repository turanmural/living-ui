import Foundation

/// Streaming-aware parser for agent message text. Splits a string into:
/// - `.text` segments (plain markdown)
/// - `.widget` segments (` ```living-ui-widget ... ``` ` fenced JSON, fully parsed)
/// - `.loading` segments (an open fence with no closing `​```` ` yet — the agent
///   is still streaming the widget; UI can show a type-aware skeleton)
/// - `.invalid` segments (closed fence but JSON failed to parse)
///
/// Designed so a chat view can re-parse on every `text_delta` event and get a
/// stable, in-order list of segments that animates smoothly.
public enum Segment: Sendable, Hashable {
    case text(id: String, text: String)
    case widget(id: String, data: AnyJSONValue)
    case loading(id: String, hint: String?)
    case invalid(id: String, rawType: String, error: String)

    public var id: String {
        switch self {
        case .text(let id, _), .widget(let id, _),
             .loading(let id, _), .invalid(let id, _, _):
            return id
        }
    }
}

public enum SegmentParser {
    /// Default fence label — hosts can use `parse(_:fenceLabel:)` to override.
    public static let defaultFenceLabel = "living-ui-widget"

    public static func parse(_ source: String, fenceLabel: String = defaultFenceLabel) -> [Segment] {
        var out: [Segment] = []
        var cursor = source.startIndex
        var index = 0

        let openMarker = "```\(fenceLabel)"
        let closeMarker = "```"

        while cursor < source.endIndex {
            if let openRange = source.range(of: openMarker, range: cursor..<source.endIndex) {
                if openRange.lowerBound > cursor {
                    let before = String(source[cursor..<openRange.lowerBound])
                    if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        out.append(.text(id: "t-\(index)", text: before))
                        index += 1
                    }
                }
                let afterOpen = openRange.upperBound
                // Skip optional newline after the opening fence
                let bodyStart: String.Index = afterOpen
                if let closeRange = source.range(of: closeMarker, range: afterOpen..<source.endIndex) {
                    let raw = String(source[bodyStart..<closeRange.lowerBound])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let typeHint = extractType(raw: raw)
                    do {
                        let value = try parseJSON(raw)
                        out.append(.widget(id: "w-\(index)", data: value))
                    } catch {
                        out.append(.invalid(
                            id: "w-\(index)",
                            rawType: typeHint ?? "unknown",
                            error: (error as NSError).localizedDescription
                        ))
                    }
                    index += 1
                    cursor = closeRange.upperBound
                } else {
                    // Fence opened but not closed — streaming
                    let pending = String(source[bodyStart..<source.endIndex])
                    let hint = extractType(raw: pending)
                    out.append(.loading(id: "l-\(index)", hint: hint))
                    index += 1
                    cursor = source.endIndex
                }
            } else {
                let rest = String(source[cursor..<source.endIndex])
                if !rest.isEmpty {
                    out.append(.text(id: "t-\(index)", text: rest))
                    index += 1
                }
                cursor = source.endIndex
            }
        }

        return out
    }

    private static func extractType(raw: String) -> String? {
        // Cheap regex-style scan for `"type":"..."` in the partial JSON.
        if let typeRange = raw.range(of: "\"type\"") {
            let after = raw[typeRange.upperBound...]
            if let colon = after.firstIndex(of: ":") {
                let afterColon = after[after.index(after: colon)...]
                    .drop(while: { $0 == " " || $0 == "\t" })
                if afterColon.first == "\"" {
                    let body = afterColon.dropFirst()
                    if let endQuote = body.firstIndex(of: "\"") {
                        return String(body[..<endQuote])
                    }
                }
            }
        }
        return nil
    }

    private static func parseJSON(_ raw: String) throws -> AnyJSONValue {
        guard let data = raw.data(using: .utf8) else {
            throw NSError(domain: "LivingUI", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"])
        }
        let decoder = JSONDecoder()
        return try decoder.decode(AnyJSONValue.self, from: data)
    }
}
