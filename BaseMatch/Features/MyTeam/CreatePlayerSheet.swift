import SwiftUI

struct CreatePlayerSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    let myTeamId: String

    @State private var name = ""
    @State private var errorMessage: LocalizedStringResource?
    @FocusState private var isNameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: L10n.playerNameLabel), text: $name)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(colors.onErrorContainer)
                    }
                }
            }
            .navigationTitle(L10n.addPlayerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancelButton) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.addButton, action: submit)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        // onAppear 時点ではシートの presentation が完了しておらずフォーカスが無視されるため、
        // 1 フレーム分遅らせる。
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            isNameFocused = true
        }
    }

    private func submit() {
        guard !trimmedName.isEmpty else {
            errorMessage = L10n.playerNameRequired
            return
        }
        errorMessage = nil
        guard store.createPlayer(name: trimmedName, myTeamId: myTeamId) != nil else {
            // 重複などはストアがエラーを保持しているのでそれを見せる。
            errorMessage = store.errorMessage.map { LocalizedStringResource(stringLiteral: $0) }
            return
        }
        dismiss()
    }
}
