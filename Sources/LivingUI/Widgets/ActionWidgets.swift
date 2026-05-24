import SwiftUI

// MARK: - Action widgets (4): approval, confirmAction, quickReply, cta

struct ApprovalWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(\.livingUIDispatcher) private var dispatcher
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string ?? ""
        let description = data.object?["description"]?.string
        let actionId = data.object?["actionId"]?.string ?? "approve"
        let yes = data.object?["yesLabel"]?.string ?? "Иә"
        let no = data.object?["noLabel"]?.string ?? "Жоқ"

        WidgetCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                    .foregroundStyle(theme.colors.text)
                if let description {
                    Text(description).font(.system(size: theme.font.body))
                        .foregroundStyle(theme.colors.textMuted)
                }
                HStack(spacing: 8) {
                    Button { dispatcher.dispatch(.structuredAction(id: actionId, value: .bool(false))) } label: {
                        Text(no)
                            .font(.system(size: theme.font.callout, weight: .semibold))
                            .foregroundStyle(theme.colors.text)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Capsule().fill(theme.colors.surfaceAlt.opacity(0.7)))
                    }.buttonStyle(.plain)
                    Button { dispatcher.dispatch(.structuredAction(id: actionId, value: .bool(true))) } label: {
                        Text(yes)
                            .font(.system(size: theme.font.callout, weight: .bold))
                            .foregroundStyle(theme.colors.onPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Capsule().fill(theme.colors.primary))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

struct ConfirmActionWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(\.livingUIDispatcher) private var dispatcher
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string ?? ""
        let description = data.object?["description"]?.string
        let actionId = data.object?["actionId"]?.string ?? "confirm"
        let confirm = data.object?["confirmLabel"]?.string ?? "Растау"
        let cancel = data.object?["cancelLabel"]?.string ?? "Болдырмау"

        WidgetCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(theme.colors.accent)
                    Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                        .foregroundStyle(theme.colors.text)
                }
                if let description {
                    Text(description).font(.system(size: theme.font.body))
                        .foregroundStyle(theme.colors.textMuted)
                }
                HStack(spacing: 8) {
                    Button { dispatcher.dispatch(.structuredAction(id: actionId, value: .bool(false))) } label: {
                        Text(cancel)
                            .font(.system(size: theme.font.callout, weight: .semibold))
                            .foregroundStyle(theme.colors.text)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Capsule().fill(theme.colors.surfaceAlt))
                    }.buttonStyle(.plain)
                    Button { dispatcher.dispatch(.structuredAction(id: actionId, value: .bool(true))) } label: {
                        Text(confirm)
                            .font(.system(size: theme.font.callout, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(Capsule().fill(theme.colors.accent))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

struct QuickReplyWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(\.livingUIDispatcher) private var dispatcher
    let data: AnyJSONValue

    var body: some View {
        let suggestions = data.object?["suggestions"]?.array ?? []
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { _, s in
                    let text = s.string ?? s.object?["text"]?.string ?? ""
                    Button { dispatcher.dispatch(.prompt(text: text)) } label: {
                        Text(text)
                            .font(.system(size: theme.font.callout, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(theme.colors.primary.opacity(0.14)))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct CtaWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(\.livingUIDispatcher) private var dispatcher
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string ?? ""
        let description = data.object?["description"]?.string
        let label = data.object?["ctaLabel"]?.string ?? "Жалғастыру"
        let actionId = data.object?["actionId"]?.string ?? "cta"
        WidgetCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.system(size: theme.font.title3, weight: .bold))
                    .foregroundStyle(theme.colors.text)
                if let description {
                    Text(description).font(.system(size: theme.font.body))
                        .foregroundStyle(theme.colors.textMuted)
                }
                Button { dispatcher.dispatch(.structuredAction(id: actionId, value: nil)) } label: {
                    Text(label)
                        .font(.system(size: theme.font.callout, weight: .bold))
                        .foregroundStyle(theme.colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(
                            colors: [theme.colors.primary, theme.colors.accent],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )))
                }.buttonStyle(.plain)
            }
        }
    }
}
