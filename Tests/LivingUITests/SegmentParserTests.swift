import XCTest
@testable import LivingUI

final class SegmentParserTests: XCTestCase {
    func testPlainText() {
        let segs = SegmentParser.parse("Hello plain")
        XCTAssertEqual(segs.count, 1)
        if case .text(_, let t) = segs[0] {
            XCTAssertEqual(t, "Hello plain")
        } else { XCTFail("expected text") }
    }

    func testValidWidget() {
        let raw = """
        Result:
        ```living-ui-widget
        {"type":"number","variant":"single","label":"Balance","value":"$125"}
        ```
        bye
        """
        let segs = SegmentParser.parse(raw)
        XCTAssertEqual(segs.count, 3)
        if case .widget(_, let data) = segs[1] {
            XCTAssertEqual(data.object?["type"]?.string, "number")
            XCTAssertEqual(data.object?["label"]?.string, "Balance")
        } else { XCTFail("expected widget") }
    }

    func testUnclosedReturnsLoadingHint() {
        let raw = """
        ```living-ui-widget
        {"type":"chart","data":[
        """
        let segs = SegmentParser.parse(raw)
        XCTAssertEqual(segs.count, 1)
        if case .loading(_, let hint) = segs[0] {
            XCTAssertEqual(hint, "chart")
        } else { XCTFail("expected loading") }
    }

    func testInvalidJSONReturnsInvalid() {
        let raw = """
        ```living-ui-widget
        {"type":"number","value":not-json}
        ```
        """
        let segs = SegmentParser.parse(raw)
        XCTAssertEqual(segs.count, 1)
        if case .invalid(_, let rawType, _) = segs[0] {
            XCTAssertEqual(rawType, "number")
        } else { XCTFail("expected invalid") }
    }

    func testMultipleWidgets() {
        let raw = """
        ```living-ui-widget
        {"type":"number","value":"1"}
        ```
        between
        ```living-ui-widget
        {"type":"number","value":"2"}
        ```
        """
        let segs = SegmentParser.parse(raw)
        // widget, text, widget
        XCTAssertEqual(segs.count, 3)
    }
}
