import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var isCreateTeamPresented = false

    var body: some View {
        List {
            Section {
                ForEach(store.myTeams) { team in
                    MyTeamRow(team: team)
                }

                Button {
                    isCreateTeamPresented = true
                } label: {
                    Label(L10n.addMyTeamButton, systemImage: "plus")
                        .foregroundStyle(colors.primary)
                }
            } header: {
                Text(L10n.settingsMyTeamSection)
            } footer: {
                if store.myTeams.isEmpty {
                    Text(L10n.settingsMyTeamEmpty)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.settingsTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.doneButton) { dismiss() }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $isCreateTeamPresented) {
            CreateMyTeamSheet()
        }
    }
}

private struct MyTeamRow: View {
    @Environment(\.appColors) private var colors

    let team: MyTeam

    var body: some View {
        HStack(spacing: 12) {
            Label(team.name, systemImage: "shield")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(colors.onSurface)
                .lineLimit(1)

            Spacer(minLength: 8)

            if team.isDefault {
                Text(L10n.defaultMyTeamBadge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(colors.onPrimaryContainer)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colors.primaryContainer, in: .capsule)
            }
        }
        .tint(colors.primary)
    }
}
