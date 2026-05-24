import SwiftUI

// MARK: - Form widgets (8): input, numberInput, dateInput, dropdown, toggle,
// slider, checkbox, formGroup. All mutate ui_state.json via UiAction so the
// host's LLM doesn't have to wake up on every keystroke.

struct InputWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string
        let placeholder = data.object?["placeholder"]?.string ?? ""
        let path = data.object?["statePath"]?.string

        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let label { Text(label).font(.system(size: theme.font.caption1, weight: .medium))
                    .foregroundStyle(theme.colors.textMuted) }
                #if os(iOS) || os(visionOS) || os(tvOS)
                TextField(placeholder, text: binding(for: path))
                    .textFieldStyle(.roundedBorder)
                #else
                TextField(placeholder, text: binding(for: path))
                #endif
            }
        }
    }

    private func binding(for path: String?) -> Binding<String> {
        Binding(
            get: { store.value(forPath: path)?.string ?? "" },
            set: { v in if let p = path { store.applyAction(.setState(path: p, value: .string(v))) } }
        )
    }
}

struct NumberInputWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string
        let path = data.object?["statePath"]?.string

        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                if let label { Text(label).font(.system(size: theme.font.caption1, weight: .medium))
                    .foregroundStyle(theme.colors.textMuted) }
                #if os(iOS) || os(visionOS) || os(tvOS)
                TextField("0", text: textBinding(for: path))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                #else
                TextField("0", text: textBinding(for: path))
                #endif
            }
        }
    }

    private func textBinding(for path: String?) -> Binding<String> {
        Binding(
            get: {
                if let n = store.value(forPath: path)?.number { return String(format: "%g", n) }
                return ""
            },
            set: { s in
                guard let p = path else { return }
                if let n = Double(s.replacingOccurrences(of: ",", with: ".")) {
                    store.applyAction(.setState(path: p, value: .number(n)))
                }
            }
        )
    }
}

struct DateInputWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string ?? "Date"
        let path = data.object?["statePath"]?.string

        WidgetCard {
            HStack {
                Text(label).font(.system(size: theme.font.body))
                    .foregroundStyle(theme.colors.text)
                Spacer()
                DatePicker(label, selection: dateBinding(for: path),
                           displayedComponents: .date)
                    .labelsHidden()
            }
        }
    }

    private func dateBinding(for path: String?) -> Binding<Date> {
        Binding(
            get: {
                if let s = store.value(forPath: path)?.string,
                   let d = ISO8601DateFormatter().date(from: s) { return d }
                return Date()
            },
            set: { d in
                guard let p = path else { return }
                let s = ISO8601DateFormatter().string(from: d)
                store.applyAction(.setState(path: p, value: .string(s)))
            }
        )
    }
}

struct DropdownWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string ?? ""
        let path = data.object?["statePath"]?.string
        let options = data.object?["options"]?.array ?? []

        WidgetCard {
            HStack {
                Text(label).font(.system(size: theme.font.body))
                    .foregroundStyle(theme.colors.text)
                Spacer()
                Menu(selectedLabel(options: options, path: path)) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, opt in
                        Button(opt.object?["label"]?.string ?? "") {
                            if let p = path, let v = opt.object?["value"] {
                                store.applyAction(.setState(path: p, value: v))
                            }
                        }
                    }
                }
                .foregroundStyle(theme.colors.primary)
            }
        }
    }

    private func selectedLabel(options: [AnyJSONValue], path: String?) -> String {
        let current = store.value(forPath: path)
        for o in options {
            if let v = o.object?["value"], v == current {
                return o.object?["label"]?.string ?? ""
            }
        }
        return "—"
    }
}

struct ToggleWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string ?? ""
        let path = data.object?["statePath"]?.string

        WidgetCard {
            Toggle(label, isOn: Binding(
                get: { store.value(forPath: path)?.bool ?? false },
                set: { v in if let p = path { store.applyAction(.setState(path: p, value: .bool(v))) } }
            ))
            .font(.system(size: theme.font.body))
            .foregroundStyle(theme.colors.text)
            .tint(theme.colors.primary)
        }
    }
}

struct SliderWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string
        let min = data.object?["min"]?.number ?? 0
        let max = data.object?["max"]?.number ?? 100
        let path = data.object?["statePath"]?.string

        WidgetCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if let label { Text(label).font(.system(size: theme.font.caption1))
                        .foregroundStyle(theme.colors.textMuted) }
                    Spacer()
                    Text(String(format: "%g", store.value(forPath: path)?.number ?? min))
                        .font(.system(size: theme.font.caption1, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.colors.primary)
                }
                Slider(value: Binding(
                    get: { store.value(forPath: path)?.number ?? min },
                    set: { v in if let p = path { store.applyAction(.setState(path: p, value: .number(v))) } }
                ), in: min...max)
                .tint(theme.colors.primary)
            }
        }
    }
}

struct CheckboxWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    let data: AnyJSONValue

    var body: some View {
        let label = data.object?["label"]?.string ?? ""
        let path = data.object?["statePath"]?.string
        let checked = store.value(forPath: path)?.bool ?? false

        WidgetCard {
            Button {
                if let p = path { store.applyAction(.toggleState(path: p)) }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: checked ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundStyle(checked ? theme.colors.primary : theme.colors.textMuted)
                    Text(label).font(.system(size: theme.font.body))
                        .foregroundStyle(theme.colors.text)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct FormGroupWidgetView: View {
    @Environment(\.livingUITheme) private var theme
    @Environment(UiConfigStore.self) private var store
    @Environment(\.livingUIDispatcher) private var dispatcher
    let data: AnyJSONValue

    var body: some View {
        let title = data.object?["title"]?.string
        let subtitle = data.object?["subtitle"]?.string
        let fields = data.object?["fields"]?.array ?? []
        let submitLabel = data.object?["submitLabel"]?.string ?? "Жіберу"
        let actionId = data.object?["actionId"]?.string ?? "submit"
        let statePath = data.object?["statePath"]?.string

        WidgetCard {
            VStack(alignment: .leading, spacing: 12) {
                if let title { Text(title).font(.system(size: theme.font.subhead, weight: .bold))
                    .foregroundStyle(theme.colors.text) }
                if let subtitle { Text(subtitle).font(.system(size: theme.font.caption1))
                    .foregroundStyle(theme.colors.textMuted) }

                ForEach(Array(fields.enumerated()), id: \.offset) { _, field in
                    let type = field.object?["type"]?.string ?? ""
                    let name = field.object?["name"]?.string ?? ""
                    let scoped = statePath.map { "\($0).\(name)" } ?? name
                    let merged = field.merging(["statePath": .string(scoped)])
                    if let view = WidgetCatalog.shared.render(type: type, data: merged) {
                        view
                    }
                }

                Button {
                    let values = collectValues(fields: fields, statePath: statePath)
                    dispatcher.dispatch(.structuredAction(id: actionId, value: .object(values)))
                } label: {
                    Text(submitLabel)
                        .font(.system(size: theme.font.callout, weight: .bold))
                        .foregroundStyle(theme.colors.onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(theme.colors.primary))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func collectValues(fields: [AnyJSONValue], statePath: String?) -> [String: AnyJSONValue] {
        var out: [String: AnyJSONValue] = [:]
        for field in fields {
            let name = field.object?["name"]?.string ?? ""
            let scoped = statePath.map { "\($0).\(name)" } ?? name
            if let v = store.value(forPath: scoped) {
                out[name] = v
            }
        }
        return out
    }
}

private extension AnyJSONValue {
    func merging(_ other: [String: AnyJSONValue]) -> AnyJSONValue {
        guard case .object(var obj) = self else { return self }
        for (k, v) in other { obj[k] = v }
        return .object(obj)
    }
}
