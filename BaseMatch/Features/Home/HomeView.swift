import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors

    @Binding var selection: AppTab
    @State private var path = NavigationPath()
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
                ScrollView {
                VStack(spacing: Spacing.lg) {
                    HomeHero(summary: store.seasonSummary, topInset: proxy.safeAreaInsets.top)

                    VStack(spacing: Spacing.lg) {
                        HomePrimaryActions(
                            onRecord: { path.append(GameRoute.create(date: Date())) },
                            onStats: { selection = .stats }
                        )

                        if let highlight = store.defaultPlayerHighlight {
                            HomePlayerHighlightSection(highlight: highlight)
                        }

                        HomeRecentGamesSection(games: Array(store.sortedGames.prefix(3)))
                    }
                    .padding(.horizontal, Spacing.md)
                }
                // ignoresSafeArea が下側の安全余白も打ち消すため、タブバー分を内容側で確保する。
                .padding(.bottom, AppTheme.floatingTabBarInset)
            }
                // 画面上端は必ずヒーローの濃色。GeometryReader の初回レイアウトでは
                // safeAreaInsets が 0 でヒーローが縮み、下地の明色が覗いてしまう。
                .background(alignment: .top) {
                    colors.primary
                        .frame(height: proxy.size.height / 2)
                        .frame(maxWidth: .infinity)
                }
                .background(colors.groupedBackground)
                // ヒーローの背景だけを端まで伸ばす。前景はセーフエリア分の余白で守る。
                .ignoresSafeArea(edges: .top)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    // ヒーローの濃色地に載るため、システム標準の accent 色では沈む。
                    .tint(colors.onDark)
                    .accessibilityLabel(L10n.settingsTooltipOpen)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(for: GameRoute.self) { $0.destination() }
            .sheet(isPresented: $isSettingsPresented) {
                NavigationStack { SettingsView() }
            }
        }
    }
}

struct HomeHero: View {
    @Environment(\.appColors) private var colors

    let summary: SeasonSummary
    var topInset: CGFloat = 0

    var body: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xxs) {
                Text(L10n.seasonSummarySubtitle(summary.year))
                    .font(.subheadline)
                    .foregroundStyle(colors.onDarkVariant)

                Text(L10n.homeHeadline)
                    .font(.largeTitle.bold())
                    .foregroundStyle(colors.onDark)
            }
            .multilineTextAlignment(.center)

            HeroScoreboard(summary: summary)
        }
        .padding(.horizontal, Spacing.md)
        // ステータスバーと、その下に重なるツールバー（設定ギア）の両方を避ける。
        .padding(.top, topInset + 56)
        .padding(.bottom, Spacing.lg)
        .frame(maxWidth: .infinity)
        .background {
            // 引き下げ時に隙間が出ないよう、背景だけ上方向へ伸ばす。
            colors.primary
                .padding(.top, -600)
        }
    }
}

/// 今季の5項目をヒーローに集約する。5つを1行に並べると桁が潰れるため、
/// チーム成績（試合数・勝敗）と内訳（得点・打率・防御率）の2段に分ける。
private struct HeroScoreboard: View {
    @Environment(\.appColors) private var colors

    let summary: SeasonSummary

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                statChip(
                    label: L10n.seasonGamesMetricLabel,
                    value: "\(summary.games)",
                    scale: .prominent
                )

                statChip(
                    label: L10n.seasonRecordMetricLabel,
                    value: String(localized: L10n.seasonRecordLabel(
                        summary.wins, summary.losses, summary.draws
                    )),
                    scale: .prominent
                )
            }

            Divider()
                .overlay(colors.onDarkSeparator)

            HStack(alignment: .top, spacing: Spacing.xs) {
                statChip(
                    label: L10n.seasonRunsMetricLabel,
                    value: "\(summary.totalRuns)",
                    scale: .standard
                )

                statChip(
                    label: L10n.seasonAverageMetricLabel,
                    value: summary.battingAverage,
                    scale: .standard
                )

                statChip(
                    label: L10n.seasonEraMetricLabel,
                    value: summary.era,
                    scale: .standard
                )
            }
        }
        .accessibilityIdentifier("heroScoreboard")
    }

    private func statChip(
        label: LocalizedStringResource,
        value: String,
        scale: StatValueText.Scale
    ) -> some View {
        VStack(spacing: Spacing.xxs) {
            StatValueText(value: value, scale: scale, weight: .semibold, color: colors.onDark)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.caption)
                .foregroundStyle(colors.onDarkVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct HomePrimaryActions: View {
    let onRecord: () -> Void
    let onStats: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ActionButton(
                title: L10n.recordGameButton,
                systemImage: "plus",
                isProminent: true,
                action: onRecord
            )

            ActionButton(
                title: L10n.viewStatsButton,
                systemImage: "chart.bar",
                action: onStats
            )
        }
    }
}

/// デフォルト選手の今季成績。数字だけでなく連続安打を添えて動機づけにする。
struct HomePlayerHighlightSection: View {
    @Environment(\.appColors) private var colors
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let highlight: PlayerHighlight

    private var isLargeText: Bool { dynamicTypeSize >= .accessibility1 }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeaderBar(title: L10n.homePlayerSectionTitle)

            VStack(alignment: .leading, spacing: Spacing.md) {
                playerRow

                averageFeature

                Divider()
                    .overlay(colors.outlineVariant)

                supportingMetrics

                // 1試合では「連続」と言えないため、2試合以上のときだけ出す。
                if highlight.hitStreak >= 2 {
                    streakChip
                }
            }
            .cardStyle()
            .accessibilityIdentifier("playerHighlight")
        }
    }

    private var playerRow: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(colors.primary)

            Text(highlight.playerName)
                .font(.headline)
                .foregroundStyle(colors.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// 打率をカードの主役に据える。3秒で読める1つの数字を作るため他項目より大きくする。
    private var averageFeature: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
            StatValueText(
                value: highlight.batting.averageLabel,
                scale: .hero,
                weight: .bold,
                color: colors.primary
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Text(L10n.seasonAverageMetricLabel)
                .font(.subheadline)
                .foregroundStyle(colors.onSurfaceVariant)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var supportingMetrics: some View {
        HStack(spacing: 0) {
            metricColumn(
                label: L10n.homePlayerHitsLabel,
                value: "\(highlight.batting.hits)"
            )

            metricDivider

            metricColumn(
                label: L10n.homePlayerHomeRunsLabel,
                value: "\(highlight.batting.hr)"
            )

            metricDivider

            metricColumn(
                label: L10n.homePlayerOpsLabel,
                value: highlight.batting.opsLabel
            )
        }
    }

    private var metricDivider: some View {
        Divider()
            .overlay(colors.outlineVariant)
            .frame(height: 28)
    }

    private var streakChip: some View {
        Label(
            String(localized: L10n.homePlayerHitStreak(highlight.hitStreak)),
            systemImage: "flame.fill"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(colors.gold)
    }

    private func metricColumn(
        label: LocalizedStringResource,
        value: String
    ) -> some View {
        VStack(spacing: Spacing.xxs) {
            StatValueText(
                value: value,
                scale: .standard,
                weight: .semibold,
                color: colors.onSurface
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Text(label)
                .font(.caption)
                .foregroundStyle(colors.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct HomeRecentGamesSection: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors

    let games: [Game]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeaderBar(title: L10n.recentGamesTitle)

            if games.isEmpty {
                ContentUnavailableView {
                    Label(L10n.homeEmptyGames, systemImage: "baseball")
                        .symbolRenderingMode(.hierarchical)
                }
                .cardStyle()
            } else {
                ForEach(games) { game in
                    NavigationLink(value: GameRoute.detail(gameId: game.id)) {
                        GameRecordCard(
                            game: game,
                            title: cardTitle(for: game),
                            showsResultAccent: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("recentGameCard")
                }
            }
        }
    }

    private func cardTitle(for game: Game) -> String {
        "\(store.teamName(for: game)) vs \(game.awayTeamName)"
    }
}
