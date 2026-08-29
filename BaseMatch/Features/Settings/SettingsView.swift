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
                    MyTeamRow(team: team) {
                        store.setDefaultMyTeam(id: team.id)
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
                    Text(L10n.setDefaultMyTeamHint)
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
