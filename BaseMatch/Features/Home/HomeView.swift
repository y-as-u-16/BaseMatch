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
                VStack(spacing: 28) {
                    HomeHero(summary: store.seasonSummary, topInset: proxy.safeAreaInsets.top)

                    VStack(spacing: 28) {
                        if let draft = store.draftGames.first {
                            HomeDraftGameSection(
                                game: draft,
                                title: draftTitle(for: draft),
                                remainingCount: store.draftGames.count - 1
                            )
                        }

                        HomePrimaryActions(
                            onRecord: { path.append(GameRoute.create(date: Date())) },
                            onStats: { selection = .stats }
                        )

                        if let highlight = store.defaultPlayerHighlight {
                            HomePlayerHighlightSection(highlight: highlight)
                        }

                        HomeRecentGamesSection(games: Array(store.sortedGames.prefix(3)))
                    }
                    .padding(.horizontal, 16)
                }
                // ignoresSafeArea が下側の安全余白も打ち消すため、タブバー分を内容側で確保する。
                .padding(.bottom, AppTheme.floatingTabBarInset)
            }
                .background(colors.groupedBackground)
                // ヒーローの背景だけを端まで伸ばす。前景はセーフエリア分の余白で守る。
                .ignoresSafeArea(edges: .top)
                // スクロールでヒーローがバー下を通るとき、時刻と設定ギアを読ませるための下地。
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.clear)
                        .background(.ultraThinMaterial)
                        .mask(LinearGradient(
                            colors: [.black, .black, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: proxy.safeAreaInsets.top + 52)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                            .symbolRenderingMode(.hierarchical)
                    }
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

    private func draftTitle(for game: Game) -> String {
        "\(store.teamName(for: game)) vs \(game.awayTeamName)"
    }
}

struct HomeHero: View {
    @Environment(\.colorScheme) private var colorScheme

    let summary: SeasonSummary
    var topInset: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            SeasonPill(label: L10n.seasonSummarySubtitle(summary.year))

            VStack(spacing: 10) {
                Text(L10n.homeHeadline)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text(L10n.homeDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineSpacing(3)
            }
            .multilineTextAlignment(.center)

            HeroScoreboard(summary: summary)
        }
        .padding(.horizontal, 24)
        // ステータスバーと、その下に重なるツールバー（設定ギア）の両方を避ける。
        .padding(.top, topInset + 56)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            ZStack {
                HeroBackground(colorScheme: colorScheme)
                BallparkLines(
                    lineColor: .white.opacity(0.16),
                    accentColor: .white.opacity(0.07)
                )
            }
            // 引き下げ時に隙間が出ないよう、背景だけ上方向へ余分に伸ばす。
            .padding(.top, -400)
        }
        .scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .scaleEffect(phase.value < 0 ? 1 - phase.value * 0.12 : 1, anchor: .bottom)
                .opacity(phase.value < 0 ? 1 + phase.value * 0.5 : 1)
        }
    }
}

/// 移行元の CustomPainter（ダイヤモンドと外野の弧）を Canvas で再現。
private struct BallparkLines: View {
    let lineColor: Color
    let accentColor: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width * 0.78, y: size.height * 0.60)
            let base = min(size.width, size.height) * 0.16

            let accentCenter = CGPoint(x: center.x + base * 0.08, y: center.y + base * 0.08)
            let accentRadius = base * 1.9
            context.fill(
                Path(ellipseIn: CGRect(
                    x: accentCenter.x - accentRadius,
                    y: accentCenter.y - accentRadius,
                    width: accentRadius * 2,
                    height: accentRadius * 2
                )),
                with: .color(accentColor)
            )

            var diamond = Path()
            diamond.move(to: CGPoint(x: center.x, y: center.y - base))
            diamond.addLine(to: CGPoint(x: center.x + base, y: center.y))
            diamond.addLine(to: CGPoint(x: center.x, y: center.y + base))
            diamond.addLine(to: CGPoint(x: center.x - base, y: center.y))
            diamond.closeSubpath()
            context.stroke(diamond, with: .color(lineColor), lineWidth: 1.2)

            var arc = Path()
            arc.addArc(
                center: center,
                radius: base * 2.35,
                startAngle: .radians(3.40),
                endAngle: .radians(3.40 + 2.30),
                clockwise: false
            )
            context.stroke(arc, with: .color(lineColor), lineWidth: 1.2)
        }
        .allowsHitTesting(false)
    }
}

private struct SeasonPill: View {
    let label: LocalizedStringResource

    var body: some View {
        Label(label, systemImage: "calendar")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .adaptiveGlass(in: .capsule)
    }
}

/// 今季の5項目をヒーローに集約する。5つを1行に並べると桁が潰れるため、
/// チーム成績（試合数・勝敗）と内訳（得点・打率・防御率）の2段に分ける。
private struct HeroScoreboard: View {
    let summary: SeasonSummary

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                statChip(
                    label: L10n.seasonGamesMetricLabel,
                    value: "\(summary.games)",
                    size: 30
                )

                heroDivider

                statChip(
                    label: L10n.seasonRecordMetricLabel,
                    value: "\(summary.wins)-\(summary.losses)-\(summary.draws)",
                    size: 30
                )
            }

            Divider()
                .overlay(.white.opacity(0.2))

            HStack(spacing: 0) {
                statChip(
                    label: L10n.seasonRunsMetricLabel,
                    value: "\(summary.totalRuns)",
                    size: 22
                )

                heroDivider

                statChip(
                    label: L10n.seasonAverageMetricLabel,
                    value: summary.battingAverage,
                    size: 22
                )

                heroDivider

                statChip(
                    label: L10n.seasonEraMetricLabel,
                    value: summary.era,
                    size: 22
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .adaptiveGlass(in: .rect(cornerRadius: AppTheme.heroCornerRadius, style: .continuous))
        .accessibilityIdentifier("heroScoreboard")
    }

    private var heroDivider: some View {
        Divider()
            .overlay(.white.opacity(0.2))
            .frame(height: 36)
    }

    private func statChip(
        label: LocalizedStringResource,
        value: String,
        size: CGFloat
    ) -> some View {
        VStack(spacing: 4) {
            StatValueText(value: value, size: size, weight: .semibold, color: .white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
    }
}

struct HomePrimaryActions: View {
    let onRecord: () -> Void
    let onStats: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            GlassCapsuleButton(
                title: L10n.recordGameButton,
                systemImage: "plus",
                isProminent: true,
                action: onRecord
            )

            GlassCapsuleButton(
                title: L10n.viewStatsButton,
                systemImage: "chart.bar",
                action: onStats
            )
        }
    }
}

/// 記録の途中で止まっている試合。ホームで最も目立たせ、続きへ直行させる。
struct HomeDraftGameSection: View {
    @Environment(\.appColors) private var colors

    let game: Game
    let title: String
    let remainingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderBar(title: L10n.homeDraftSectionTitle)

            NavigationLink(value: GameRoute.detail(gameId: game.id)) {
                DraftGameCard(game: game, title: title)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("draftGameCard")

            if remainingCount > 0 {
                Text(L10n.homeDraftMoreCount(remainingCount))
                    .font(.footnote)
                    .foregroundStyle(colors.onSurfaceVariant)
                    .padding(.leading, 4)
            }
        }
    }
}

private struct DraftGameCard: View {
    @Environment(\.appColors) private var colors

    let game: Game
    let title: String

    var body: some View {
        PrimaryPanel(padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)) {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Label(L10n.homeDraftBadge, systemImage: "record.circle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colors.tertiary.gradient, in: .capsule)
                    .symbolEffect(.pulse)

                Spacer(minLength: 0)

                Text(game.date.slashDateLabel)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.75))
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            ScoreBoardView(
                homeName: "HOME",
                homeScore: game.homeScore ?? 0,
                awayName: "AWAY",
                awayScore: game.awayScore ?? 0,
                compact: true,
                onDarkBackground: true
            )

            HStack(spacing: 6) {
                Text(L10n.homeDraftResume)
                Image(systemName: "chevron.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .adaptiveGlass(in: .capsule)
        }
    }
}

/// デフォルト選手の今季成績。数字だけでなく連続安打を添えて動機づけにする。
struct HomePlayerHighlightSection: View {
    @Environment(\.appColors) private var colors

    let highlight: PlayerHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderBar(title: L10n.homePlayerSectionTitle)

            VStack(alignment: .leading, spacing: 16) {
                Text(highlight.playerName)
                    .font(.headline)
                    .foregroundStyle(colors.onSurface)
                    .lineLimit(1)

                HStack(spacing: 0) {
                    metricColumn(
                        label: L10n.seasonAverageMetricLabel,
                        value: highlight.batting.averageLabel,
                        emphasized: true
                    )
                    metricColumn(
                        label: L10n.homePlayerHitsLabel,
                        value: "\(highlight.batting.hits)"
                    )
                    metricColumn(
                        label: L10n.homePlayerHomeRunsLabel,
                        value: "\(highlight.batting.hr)"
                    )
                    metricColumn(
                        label: L10n.homePlayerOpsLabel,
                        value: highlight.batting.opsLabel,
                        emphasized: true
                    )
                }

                // 1試合では「連続」と言えないため、2試合以上のときだけ出す。
                if highlight.hitStreak >= 2 {
                    Label(
                        String(localized: L10n.homePlayerHitStreak(highlight.hitStreak)),
                        systemImage: "flame.fill"
                    )
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(colors.gold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colors.gold.opacity(0.14), in: .capsule)
                }
            }
            .cardStyle(padding: 20)
            .accessibilityIdentifier("playerHighlight")
        }
    }

    private func metricColumn(
        label: LocalizedStringResource,
        value: String,
        emphasized: Bool = false
    ) -> some View {
        VStack(spacing: 4) {
            StatValueText(
                value: value,
                size: 24,
                weight: .semibold,
                color: emphasized ? colors.primary : colors.onSurface
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Text(label)
                .font(.caption)
                .foregroundStyle(colors.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderBar(title: L10n.recentGamesTitle)

            if games.isEmpty {
                EmptyTextPanel(L10n.homeEmptyGames)
            } else {
                ForEach(games) { game in
                    NavigationLink(value: GameRoute.detail(gameId: game.id)) {
                        GameRecordCard(game: game, title: cardTitle(for: game))
                    }
                    .buttonStyle(.plain)
                    .listItemTransition()
                }
            }
        }
    }

    private func cardTitle(for game: Game) -> String {
        "\(store.teamName(for: game)) vs \(game.awayTeamName)"
    }
}
