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

                LabeledContent(L10n.settingsVersion, value: Self.appVersion)
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

    private static let privacyPolicyURL = URL(
        string: "https://github.com/y-as-u-16/BaseMatch/blob/main/PRIVACY.md"
    )!

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
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
