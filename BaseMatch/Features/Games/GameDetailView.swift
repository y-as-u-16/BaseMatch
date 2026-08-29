import SwiftUI

struct GameDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors

    private let gameId: String

    init(gameId: String) {
        self.gameId = gameId
    }

    var body: some View {
        Group {
            if let game = store.game(id: gameId) {
                content(for: game)
            } else {
                ContentUnavailableView(L10n.gameNotFound, systemImage: "questionmark.folder")
            }
        }
        .background(colors.groupedBackground)
        .navigationTitle(L10n.gameDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        // ホームの toolbarBackground(.hidden) が push 先まで伝播する。.automatic だと打ち消せないため .visible を使う。
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colors.groupedBackground, for: .navigationBar)
        .toolbar {
            if let game = store.game(id: gameId), game.status != .final_ {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: GameRoute.edit(gameId: game.id)) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel(L10n.editGameTitle)
                }
            }
        }
    }

    private func content(for game: Game) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                GameScoreHeader(game: game, myTeamName: store.teamName(for: game))

                plateAppearanceSection(gameId: game.id)
                pitchingSection(gameId: game.id)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        // Group 側に付けるとスクロールビューまで届かないため、ScrollView に直接指定する。
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colors.groupedBackground, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            GameDetailActionBar(gameId: game.id)
        }
    }

    private func plateAppearanceSection(gameId: String) -> some View {
        let appearances = store.plateAppearances(gameId: gameId)
        return RecordSection(
            title: L10n.plateAppearanceRecordsTitle,
            count: appearances.count,
            emptyText: L10n.emptyPlateAppearances
        ) {
            ForEach(Array(appearances.enumerated()), id: \.element.id) { index, appearance in
                RecordRow(
                    systemImage: appearance.resultDetail.systemImage,
                    tint: resultTint(for: appearance.resultType),
                    title: appearance.batterName,
                    subtitle: L10n.plateAppearanceListSubtitle(
                        appearance.inning?.description ?? "-",
                        appearance.rbi ?? 0
                    ),
                    trailing: appearance.resultDetail.localizedLabel,
                    trailingTint: resultTint(for: appearance.resultType),
                    showsDivider: index < appearances.count - 1
                )
            }
        }
    }

    private func pitchingSection(gameId: String) -> some View {
        let appearances = store.pitchingAppearances(gameId: gameId)
        return RecordSection(
            title: L10n.pitchingRecordsTitle,
            count: appearances.count,
            emptyText: L10n.emptyPitchingAppearances
        ) {
            ForEach(Array(appearances.enumerated()), id: \.element.id) { index, appearance in
                RecordRow(
                    systemImage: "figure.baseball",
                    tint: colors.secondary,
                    title: appearance.pitcherName,
                    subtitle: L10n.pitchingListSubtitle(
                        appearance.runs,
                        appearance.earnedRuns,
                        appearance.strikeouts
                    ),
                    trailing: L10n.inningsFromOuts(appearance.outsPitched),
                    trailingTint: colors.secondary,
                    showsDivider: index < appearances.count - 1
                )
            }
        }
    }

    private func resultTint(for type: PlateAppearanceResultType) -> Color {
        switch type {
        case .hit: colors.primary
        case .out: colors.lossColor
        case .walk, .error: colors.gold
        }
    }
}

private struct GameScoreHeader: View {
    @Environment(\.appColors) private var colors

    let game: Game
    let myTeamName: String

    private var homeScore: Int { game.homeScore ?? 0 }
    private var awayScore: Int { game.awayScore ?? 0 }

    private var result: GameRecordResult {
        .from(homeScore: homeScore, awayScore: awayScore)
    }

    var body: some View {
        PrimaryPanel {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    metaChip(systemImage: "calendar", label: game.date.slashDateLabel)
                    if let location = game.location?.normalizedOptional {
                        metaChip(systemImage: "mappin.and.ellipse", label: location)
                    }
                    Spacer(minLength: 0)
                }

                ScoreBoardView(
                    homeName: myTeamName,
                    homeScore: homeScore,
                    awayName: game.awayTeamName,
                    awayScore: awayScore,
                    resultLabel: result.label,
                    resultTint: result.color(colors),
                    onDarkBackground: true
                )
            }
        }
    }

    private func metaChip(systemImage: String, label: String) -> some View {
        Label(label, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.85))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.15), in: .capsule)
    }
}

private struct GameDetailActionBar: View {
    @Environment(\.appColors) private var colors

    let gameId: String

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: GameRoute.plateAppearanceInput(gameId: gameId)) {
                Label(L10n.addPlateAppearanceButton, systemImage: "figure.baseball")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(colors.onPrimary)
                    .padding(.horizontal, 18)
                    .background(Capsule(style: .continuous).fill(colors.primary.gradient))
                    .adaptiveInteractiveGlass(in: .capsule)
            }

            NavigationLink(value: GameRoute.pitchingInput(gameId: gameId)) {
                Label(L10n.addPitchingButton, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, 18)
                    .adaptiveInteractiveGlass(in: .capsule)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

private struct RecordSection<Content: View>: View {
    @Environment(\.appColors) private var colors

    let title: String
    let count: Int
    let emptyText: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                SectionHeaderBar(title: title)
                CountBadge(count: count)
            }

            if count == 0 {
                EmptyTextPanel(emptyText)
            } else {
                VStack(spacing: 0) {
                    content
                }
                .cardStyle(padding: 0)
            }
        }
    }
}

private struct RecordRow: View {
    @Environment(\.appColors) private var colors

    let systemImage: String
    let tint: Color
    let title: String
    let subtitle: String
    let trailing: String
    let trailingTint: Color
    let showsDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colors.onSurface)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(colors.onSurfaceVariant)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(trailingTint)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(trailingTint.opacity(0.14), in: .capsule)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if showsDivider {
                Divider()
                    .padding(.leading, 56)
            }
        }
        .listItemTransition()
    }
}
