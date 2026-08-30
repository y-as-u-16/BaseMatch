import SwiftUI

struct RenameSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringResource
    let fieldLabel: LocalizedStringResource
    let requiredMessage: LocalizedStringResource
    let currentName: String
    let onSubmit: (String) -> Void

    @State private var name: String
    @State private var errorMessage: LocalizedStringResource?
    @FocusState private var isNameFocused: Bool

    init(
        title: LocalizedStringResource,
        fieldLabel: LocalizedStringResource,
        requiredMessage: LocalizedStringResource,
        currentName: String,
        onSubmit: @escaping (String) -> Void
    ) {
        self.title = title
        self.fieldLabel = fieldLabel
        self.requiredMessage = requiredMessage
        self.currentName = currentName
        self.onSubmit = onSubmit
        _name = State(initialValue: currentName)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isUnchanged: Bool {
        trimmedName == currentName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // TextField のプレースホルダは LocalizedStringResource 版が iOS 26 以降のため String に変換する。
                    TextField(String(localized: fieldLabel), text: $name)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .accessibilityIdentifier("renameNameField")
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(colors.onErrorContainer)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancelButton) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.saveChangesButton, action: submit)
                        .disabled(trimmedName.isEmpty || isUnchanged)
                        .accessibilityIdentifier("renameSubmit")
                }
            }
        }
        .presentationDetents([.height(200)])
        // onAppear 時点ではシートの presentation が完了しておらずフォーカスが無視されるため、
        // 1 フレーム分遅らせる。
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            isNameFocused = true
        }
    }

    private func submit() {
        guard !trimmedName.isEmpty else {
            errorMessage = requiredMessage
            return
        }
        errorMessage = nil
        store.errorMessage = nil
        onSubmit(trimmedName)
        guard store.errorMessage == nil else {
            errorMessage = store.errorMessage.map { LocalizedStringResource(stringLiteral: $0) }
            return
        }
        dismiss()
    }
}
