import SwiftUI

struct GameDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    private let gameId: String

    @State private var isDeleteGamePresented = false
    @State private var plateAppearanceToDelete: PlateAppearance?
    @State private var pitchingToDelete: PitchingAppearance?

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
            if let game = store.game(id: gameId) {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: GameRoute.edit(gameId: game.id)) {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel(L10n.editGameTitle)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        isDeleteGamePresented = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel(L10n.deleteGameTitle)
                    .accessibilityIdentifier("deleteGame")
                }
            }
        }
        .confirmationDialog(
            L10n.deleteGameTitle,
            isPresented: $isDeleteGamePresented,
            titleVisibility: .visible
        ) {
            Button(L10n.deleteButton, role: .destructive) {
                store.deleteGame(id: gameId)
                dismiss()
            }
            Button(L10n.cancelButton, role: .cancel) {}
        } message: {
            Text(L10n.deleteGameMessage)
        }
        .confirmationDialog(
            L10n.deletePlateAppearanceTitle,
            isPresented: .isPresent($plateAppearanceToDelete),
            titleVisibility: .visible
        ) {
            Button(L10n.deleteButton, role: .destructive) {
                if let target = plateAppearanceToDelete {
                    store.deletePlateAppearance(id: target.id)
                }
                plateAppearanceToDelete = nil
            }
            Button(L10n.cancelButton, role: .cancel) { plateAppearanceToDelete = nil }
        } message: {
            Text(L10n.deleteCannotUndo)
        }
        .confirmationDialog(
            L10n.deletePitchingTitle,
            isPresented: .isPresent($pitchingToDelete),
            titleVisibility: .visible
        ) {
            Button(L10n.deleteButton, role: .destructive) {
                if let target = pitchingToDelete {
                    store.deletePitchingAppearance(id: target.id)
                }
                pitchingToDelete = nil
            }
            Button(L10n.cancelButton, role: .cancel) { pitchingToDelete = nil }
        } message: {
            Text(L10n.deleteCannotUndo)
        }
    }

    private func content(for game: Game) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                GameScoreHeader(game: game, myTeamName: store.teamName(for: game))

                lineScoreSection(for: game)

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

    @ViewBuilder
    private func lineScoreSection(for game: Game) -> some View {
        let homeRuns = store.inningRuns(gameId: game.id, isHome: true)
        let awayRuns = store.inningRuns(gameId: game.id, isHome: false)
        let myTeamName = store.teamName(for: game)

        if !homeRuns.isEmpty || !awayRuns.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeaderBar(title: L10n.lineScoreTitle)

                // ラインスコアは先攻が上段。自チームが先攻なら上下が入れ替わる。
                LineScoreView(
                    homeName: game.isMyTeamHome ? myTeamName : game.awayTeamName,
                    homeRuns: homeRuns,
                    awayName: game.isMyTeamHome ? game.awayTeamName : myTeamName,
                    awayRuns: awayRuns
                )
            }
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
                // RecordSection は List ではなく VStack のため swipeActions が使えない。
                .contextMenu {
                    NavigationLink(value: GameRoute.plateAppearanceEdit(recordId: appearance.id)) {
                        Label(L10n.editButton, systemImage: "pencil")
                    }
                    Button(L10n.deleteButton, systemImage: "trash", role: .destructive) {
                        plateAppearanceToDelete = appearance
                    }
                }
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
                .contextMenu {
                    NavigationLink(value: GameRoute.pitchingEdit(recordId: appearance.id)) {
                        Label(L10n.editButton, systemImage: "pencil")
                    }
                    Button(L10n.deleteButton, systemImage: "trash", role: .destructive) {
                        pitchingToDelete = appearance
                    }
                }
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

    private var myTeamScore: Int { game.myTeamScore ?? 0 }
    private var opponentScore: Int { game.opponentScore ?? 0 }

    private var result: GameRecordResult { .from(game: game) }

    var body: some View {
        PrimaryPanel {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    metaChip(systemImage: "calendar", label: game.date.slashDateLabel)
                    metaChip(
                        systemImage: game.isMyTeamHome ? "2.circle" : "1.circle",
                        label: String(localized: game.isMyTeamHome
                            ? L10n.detailMyTeamBattingSecond
                            : L10n.detailMyTeamBattingFirst)
                    )
                    if let location = game.location?.normalizedOptional {
                        metaChip(systemImage: "mappin.and.ellipse", label: location)
                    }
                    Spacer(minLength: 0)
                }

                ScoreBoardView(
                    homeName: myTeamName,
                    homeScore: myTeamScore,
                    awayName: game.awayTeamName,
                    awayScore: opponentScore,
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
            .foregroundStyle(colors.onDarkVariant)
            .lineLimit(1)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(colors.onDarkFill, in: .rect(cornerRadius: Radius.small, style: .continuous))
    }
}

/// ラインスコア。チーム名と合計は固定し、イニング列だけ横スクロールさせる。
/// 9回だと横幅が足りず、名前が読めないまま数字だけ流れるのを避ける。
private struct LineScoreView: View {
    @Environment(\.appColors) private var colors

    let homeName: String
    let homeRuns: [Int]
    let awayName: String
    let awayRuns: [Int]

    private static let rowHeight: CGFloat = 28

    /// 9回まではスクロールさせず一画面に収める。隠れた列があると気づかれない。
    private var nameWidth: CGFloat { inningCount <= 7 ? 76 : 60 }

    private var inningCount: Int { max(homeRuns.count, awayRuns.count) }

    var body: some View {
        HStack(spacing: 0) {
            teamNameColumn

            VStack(alignment: .leading, spacing: 0) {
                inningRow(values: (1...max(inningCount, 1)).map { "\($0)" }, isHeader: true)
                inningRow(values: paddedValues(awayRuns), isHeader: false)
                inningRow(values: paddedValues(homeRuns), isHeader: false)
            }
            .frame(maxWidth: .infinity)

            Divider()

            totalColumn
        }
        .cardStyle(padding: 12)
    }

    private var teamNameColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            cell { Color.clear }
            nameCell(awayName)
            nameCell(homeName)
        }
        .padding(.trailing, 8)
    }

    private func nameCell(_ name: String) -> some View {
        cell {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: nameWidth)
    }

    private var totalColumn: some View {
        VStack(spacing: 0) {
            cell {
                Text(L10n.lineScoreTotalHeader)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(colors.onSurfaceVariant)
            }
            totalCell(awayRuns.reduce(0, +))
            totalCell(homeRuns.reduce(0, +))
        }
        .frame(width: 40)
        .padding(.leading, 4)
    }

    private func totalCell(_ total: Int) -> some View {
        cell {
            Text("\(total)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(colors.primary)
        }
    }

    private func inningRow(values: [String], isHeader: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                cell {
                    Text(value)
                        .font(isHeader ? .caption2.weight(.semibold) : .subheadline)
                        .monospacedDigit()
                        .foregroundStyle(isHeader ? colors.onSurfaceVariant : colors.onSurface)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    /// 表裏で回数が違っても列がずれないよう、短い側を "-" で埋める。
    private func paddedValues(_ runs: [Int]) -> [String] {
        let values = runs.map { "\($0)" }
        guard values.count < inningCount else { return values }
        return values + Array(repeating: "-", count: inningCount - values.count)
    }

    private func cell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(height: Self.rowHeight)
    }
}

private struct GameDetailActionBar: View {
    @Environment(\.appColors) private var colors

    let gameId: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            NavigationLink(value: GameRoute.plateAppearanceInput(gameId: gameId)) {
                Label(L10n.addPlateAppearanceButton, systemImage: "figure.baseball")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(colors.onPrimary)
                    .padding(.horizontal, Spacing.md)
                    .background(colors.primary, in: .rect(cornerRadius: Radius.medium, style: .continuous))
            }
            .accessibilityIdentifier("addPlateAppearance")

            NavigationLink(value: GameRoute.pitchingInput(gameId: gameId)) {
                Label(L10n.addPitchingButton, systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(colors.primary)
                    .padding(.horizontal, Spacing.md)
                    .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: Radius.medium, style: .continuous))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.bar)
    }
}

private struct RecordSection<Content: View>: View {
    @Environment(\.appColors) private var colors

    let title: LocalizedStringResource
    let count: Int
    let emptyText: LocalizedStringResource
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                SectionHeaderBar(title: title)
                CountBadge(count: count)
            }

            if count == 0 {
                ContentUnavailableView {
                    Label(emptyText, systemImage: "list.bullet")
                        .symbolRenderingMode(.hierarchical)
                }
                .cardStyle()
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
    let subtitle: LocalizedStringResource
    let trailing: LocalizedStringResource
    let trailingTint: Color
    let showsDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.body)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
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

                StatusBadge(title: trailing, tint: trailingTint)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            if showsDivider {
                // アイコン幅 28 + 左余白 16 + 間隔 12 に合わせ、本文の頭で区切る。
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}
