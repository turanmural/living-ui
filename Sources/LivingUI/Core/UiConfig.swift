import Foundation
import Observation
import SwiftUI

// MARK: - UiConfig schema

public struct UiConfig: Sendable, Hashable {
    public var version: Int
    public var theme: ThemeSpec
    public var layout: LayoutSpec
    public var app: AppSpec
    public var state: [String: AnyJSONValue]

    public init(
        version: Int = 2,
        theme: ThemeSpec = .init(),
        layout: LayoutSpec = .init(),
        app: AppSpec = .init(),
        state: [String: AnyJSONValue] = [:]
    ) {
        self.version = version
        self.theme = theme
        self.layout = layout
        self.app = app
        self.state = state
    }
}

public struct ThemeSpec: Sendable, Hashable {
    public var active: String  // "warm" | "jarvis" | "glass" | "custom"
    public init(active: String = "warm") { self.active = active }
}

public struct LayoutSpec: Sendable, Hashable {
    public var fontScale: Double
    public init(fontScale: Double = 1.0) { self.fontScale = fontScale }
}

public struct AppSpec: Sendable, Hashable {
    public var home: String
    public var nav: [NavItem]
    public var pages: [String: PageSpec]

    public init(home: String = "home", nav: [NavItem] = [], pages: [String: PageSpec] = [:]) {
        self.home = home
        self.nav = nav
        self.pages = pages
    }

    public var homePage: PageSpec {
        pages[home] ?? PageSpec(title: "", blocks: [])
    }
}

public struct NavItem: Sendable, Hashable, Identifiable {
    public var label: String
    public var icon: String?
    public var page: String
    public var id: String { page }
    public init(label: String, icon: String? = nil, page: String) {
        self.label = label
        self.icon = icon
        self.page = page
    }
}

public struct PageSpec: Sendable, Hashable {
    public var title: String
    public var blocks: [Block]
    public init(title: String, blocks: [Block]) {
        self.title = title
        self.blocks = blocks
    }
}
