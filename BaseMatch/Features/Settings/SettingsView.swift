import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    @State private var isCreateTeamPresented = false
    @State private var teamForNewPlayer: MyTeam?
    @State private var playerToDelete: Player?
    @State private var teamToRename: MyTeam?
    @State private var teamToDelete: MyTeam?
    @State private var playerToRename: Player?

    private var canDeleteMyTeam: Bool {
        store.myTeams.count > 1
    }

    var body: some View {
        @Bindable var settings = settings

        return List {
            Section {
                ForEach(store.myTeams) { team in
                    MyTeamRow(team: team) {
                        store.setDefaultMyTeam(id: team.id)
                    }
                    .contextMenu {
                        Button(L10n.renameMyTeamAction, systemImage: "pencil") {
                            teamToRename = team
                        }
                        .accessibilityIdentifier("renameTeam")

                        if canDeleteMyTeam {
                            Button(L10n.deleteButton, systemImage: "trash", role: .destructive) {
                                teamToDelete = team
                            }
                            .accessibilityIdentifier("deleteTeam")
                        }
                    }
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
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.setDefaultMyTeamHint)
                        if !canDeleteMyTeam {
                            Text(L10n.deleteMyTeamLastHint)
                        }
                    }
                }
            }

            ForEach(store.myTeams) { team in
                Section {
                    ForEach(store.players(myTeamId: team.id)) { player in
                        PlayerRow(player: player)
                            .contextMenu {
                                Button(L10n.renamePlayerAction, systemImage: "pencil") {
                                    playerToRename = player
                                }
                                .accessibilityIdentifier("renamePlayer")

                                if !player.isDefault {
                                    Button(L10n.setDefaultPlayerAction, systemImage: "star") {
                                        store.setDefaultPlayer(id: player.id, myTeamId: team.id)
                                    }
                                    .accessibilityIdentifier("setDefaultPlayer")
                                }

                                Button(L10n.deleteButton, systemImage: "trash", role: .destructive) {
                                    playerToDelete = player
                                }
                                .accessibilityIdentifier("deletePlayer")
                            }
                    }

                    Button {
                        teamForNewPlayer = team
                    } label: {
                        Label(L10n.addPlayerButton, systemImage: "person.badge.plus")
                            .foregroundStyle(colors.primary)
                    }
                } header: {
                    Text("\(team.name) — \(String(localized: L10n.playerSectionTitle))")
                } footer: {
                    if store.players(myTeamId: team.id).isEmpty {
                        Text(L10n.playerEmptyHint)
                    } else {
                        Text(L10n.setDefaultPlayerHint)
                    }
                }
            }

            Section(L10n.settingsAppearanceSection) {
                Picker(L10n.settingsLanguage, selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }

                Picker(L10n.settingsTheme, selection: $settings.theme) {
                    ForEach(AppThemeMode.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
            }

            // App Review Guideline 5.1.1(i) がアプリ内からのアクセスを必須としている。
            Section(L10n.settingsAboutSection) {
                Link(destination: Self.privacyPolicyURL) {
                    HStack {
                        Label(L10n.settingsPrivacyPolicy, systemImage: "hand.raised")
                            .foregroundStyle(colors.onSurface)
                        Spacer(minLength: 8)
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundStyle(colors.onSurfaceTertiary)
                    }
                }
                .tint(colors.primary)

                LabeledContent {
                    Text(Self.appVersion)
                } label: {
                    Text(L10n.settingsVersion)
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
        .sheet(item: $teamForNewPlayer) { team in
            CreatePlayerSheet(myTeamId: team.id)
        }
        .sheet(item: $teamToRename) { team in
            RenameSheet(
                title: L10n.renameMyTeamTitle,
                fieldLabel: L10n.myTeamNameLabel,
                requiredMessage: L10n.myTeamNameRequired,
                currentName: team.name
            ) { newName in
                store.renameMyTeam(id: team.id, name: newName)
            }
        }
        .sheet(item: $playerToRename) { player in
            RenameSheet(
                title: L10n.renamePlayerTitle,
                fieldLabel: L10n.playerNameLabel,
                requiredMessage: L10n.playerNameRequired,
                currentName: player.name
            ) { newName in
                store.renamePlayer(id: player.id, name: newName, myTeamId: player.myTeamId)
            }
        }
        .confirmationDialog(
            L10n.deleteMyTeamTitle,
            isPresented: .init(
                get: { teamToDelete != nil },
                set: { if !$0 { teamToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.deleteButton, role: .destructive) {
                if let target = teamToDelete {
                    store.deleteMyTeam(id: target.id)
                }
                teamToDelete = nil
            }
            Button(L10n.cancelButton, role: .cancel) { teamToDelete = nil }
        } message: {
            Text(L10n.deleteMyTeamMessage)
        }
        .confirmationDialog(
            L10n.deletePlayerTitle,
            isPresented: .init(
                get: { playerToDelete != nil },
                set: { if !$0 { playerToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(L10n.deleteButton, role: .destructive) {
                if let target = playerToDelete {
                    store.deletePlayer(id: target.id)
                }
                playerToDelete = nil
            }
            Button(L10n.cancelButton, role: .cancel) { playerToDelete = nil }
        } message: {
            Text(L10n.deletePlayerMessage)
        }
    }

    private static let privacyPolicyURL = URL(
        string: "https://github.com/y-as-u-16/BaseMatch/blob/main/PRIVACY.md"
    )!

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }
}

private struct PlayerRow: View {
    @Environment(\.appColors) private var colors

    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text(player.name)
                .foregroundStyle(colors.onSurface)
                .lineLimit(1)

            Spacer(minLength: 8)

            if player.isDefault {
                Text(L10n.defaultPlayerBadge)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(colors.onPrimaryContainer)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colors.primaryContainer, in: .capsule)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(.rect)
        .animation(.smooth(duration: 0.25), value: player.isDefault)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(player.isDefault ? [.isSelected] : [])
    }
}

private struct MyTeamRow: View {
    @Environment(\.appColors) private var colors

    let team: MyTeam
    let onSetDefault: () -> Void

    var body: some View {
        Button(action: onSetDefault) {
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
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // .disabled は行全体を淡色化してしまい、選択中の行がかえって
        // 使えないように見える。押せるままにして再選択を無視する。
        .allowsHitTesting(!team.isDefault)
        .animation(.smooth(duration: 0.25), value: team.isDefault)
        .sensoryFeedback(.selection, trigger: team.isDefault)
        .accessibilityAddTraits(team.isDefault ? [.isSelected] : [])
        .accessibilityHint(team.isDefault ? "" : L10n.setDefaultMyTeamAccessibility)
        .tint(colors.primary)
    }
}
