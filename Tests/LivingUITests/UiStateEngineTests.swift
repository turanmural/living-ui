import XCTest
@testable import LivingUI

final class UiStateEngineTests: XCTestCase {
    func testSetStateSimple() {
        let next = UiStateEngine.apply(
            .setState(path: "profile.name", value: .string("Aigul")),
            to: [:]
        )
        XCTAssertEqual(UiStateEngine.getAtPath(next, path: "profile.name")?.string, "Aigul")
    }

    func testToggleStateCreatesTrue() {
        let next = UiStateEngine.apply(
            .toggleState(path: "tasks[0].done"),
            to: [:]
        )
        XCTAssertEqual(UiStateEngine.getAtPath(next, path: "tasks[0].done")?.bool, true)
    }

    func testToggleStateFlips() {
        var state: [String: AnyJSONValue] = [
            "tasks": .array([.object(["done": .bool(true)])])
        ]
        state = UiStateEngine.apply(.toggleState(path: "tasks[0].done"), to: state)
        XCTAssertEqual(UiStateEngine.getAtPath(state, path: "tasks[0].done")?.bool, false)
    }

    func testIncrementState() {
        var state: [String: AnyJSONValue] = ["counter": .number(2)]
        state = UiStateEngine.apply(.incrementState(path: "counter", by: 3), to: state)
        XCTAssertEqual(UiStateEngine.getAtPath(state, path: "counter")?.number, 5)
    }

    func testAppendStateCreatesArray() {
        let next = UiStateEngine.apply(
            .appendState(path: "ideas", value: .string("new")),
            to: [:]
        )
        XCTAssertEqual(UiStateEngine.getAtPath(next, path: "ideas[0]")?.string, "new")
    }

    func testPatchStateOverwritesTopLevel() {
        let next = UiStateEngine.apply(
            .patchState(patch: ["theme": .string("glass"), "fontScale": .number(1.2)]),
            to: ["theme": .string("warm")]
        )
        XCTAssertEqual(next["theme"]?.string, "glass")
        XCTAssertEqual(next["fontScale"]?.number, 1.2)
    }

    func testDeleteState() {
        var state: [String: AnyJSONValue] = ["draft": .string("hi"), "keep": .bool(true)]
        state = UiStateEngine.apply(.deleteState(path: "draft"), to: state)
        XCTAssertNil(state["draft"])
        XCTAssertNotNil(state["keep"])
    }

    func testPathParsingMixedArrayKey() {
        let segs = UiStateEngine.parsePath("tasks[2].title")
        XCTAssertEqual(segs.count, 3)
    }
}
