import SwiftUI

// MARK: - Feedback widgets (4): toast, infoBanner, errorCard, emptyState

struct ToastWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let message = data.object?["message"]?.string ?? ""
        let kind = data.object?["kind"]?.string ?? "info"
        let icon: String = {
            switch kind {
            case "success": return "checkmark.circle.fill"
            case "error":   return "xmark.octagon.fill"
            case "warning": return "exclamationmark.triangle.fill"
            default:        return "info.circle.fill"
            }
        }()
        let color: Color = {
            switch kind {
            case "success": return theme.colors.success
            case "error":   return theme.colors.error
            case "warning": return theme.colors.accent
            default:        return theme.colors.primary
            }
        }()
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(color)
            Text(message)
                .font(.system(size: theme.font.body))
                .foregroundStyle(theme.colors.text)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.4), lineWidth: 0.6))
    }
}

struct InfoBannerWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string
        let body = data.object?["body"]?.string ?? data.object?["message"]?.string
        let icon = data.object?["icon"]?.string ?? "lightbulb.fill"

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(theme.colors.accent)
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title).font(.system(size: theme.font.callout, weight: .bold))
                        .foregroundStyle(theme.colors.text)
                }
                if let body {
                    Text(body).font(.system(size: theme.font.body))
                        .foregroundStyle(theme.colors.textMuted)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.colors.accent.opacity(0.1)))
    }
}

struct ErrorCardWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string ?? "Қате"
        let body = data.object?["body"]?.string ?? data.object?["message"]?.string

        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 20))
                .foregroundStyle(theme.colors.error)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: theme.font.callout, weight: .bold))
                    .foregroundStyle(theme.colors.text)
                if let body {
                    Text(body).font(.system(size: theme.font.body))
                        .foregroundStyle(theme.colors.textMuted)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.colors.error.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.colors.error.opacity(0.4), lineWidth: 0.6))
    }
}

struct EmptyStateWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string ?? "Бос"
        let body = data.object?["body"]?.string
        let icon = data.object?["icon"]?.string ?? "tray"

        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(theme.colors.textMuted.opacity(0.6))
            Text(title)
                .font(.system(size: theme.font.callout, weight: .semibold))
                .foregroundStyle(theme.colors.text)
            if let body {
                Text(body).font(.system(size: theme.font.caption1))
                    .foregroundStyle(theme.colors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
