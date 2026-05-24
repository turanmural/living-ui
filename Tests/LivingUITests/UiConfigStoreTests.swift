import XCTest
@testable import LivingUI

@MainActor
final class UiConfigStoreTests: XCTestCase {
    func testEmptyStoreReturnsFallbackPage() {
        let store = UiConfigStore()
        XCTAssertEqual(store.currentConfig.app.homePage.title, "")
        XCTAssertTrue(store.currentConfig.app.homePage.blocks.isEmpty)
    }

    func testJSONDecodesPagesAndBlocks() {
        let json = """
        {
          "version": 2,
          "theme": { "active": "warm" },
          "app": {
            "home": "home",
            "pages": {
              "home": {
                "title": "Today",
                "blocks": [
                  { "type": "heading", "id": "h", "text": "Hi" },
                  { "type": "stat", "id": "s", "label": "Income", "value": "$1.2M" }
                ]
              }
            }
          }
        }
        """
        let store = UiConfigStore()
        store.update(jsonString: json)
        XCTAssertEqual(store.currentConfig.app.homePage.title, "Today")
        XCTAssertEqual(store.currentConfig.app.homePage.blocks.count, 2)
        XCTAssertEqual(store.currentConfig.app.homePage.blocks.first?.type, "heading")
    }

    func testApplyActionMutatesStateInPlace() {
        let store = UiConfigStore()
        store.applyAction(.setState(path: "profile.name", value: .string("Aigul")))
        XCTAssertEqual(store.value(forPath: "profile.name")?.string, "Aigul")
    }

    func testHighlightFlow() {
        let store = UiConfigStore()
        store.highlight(blockIds: ["x", "y"])
        XCTAssertTrue(store.highlightedBlockIds.contains("x"))
        store.clearHighlight("x")
        XCTAssertFalse(store.highlightedBlockIds.contains("x"))
    }
}
