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
                        HomePrimaryActions(
                            onRecord: { path.append(GameRoute.create(date: Date())) },
                            onStats: { selection = .stats }
                        )

                        SeasonSummaryCard(summary: store.seasonSummary)

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

            HeroScoreboard(
                gamesValue: "\(summary.games)",
                recordValue: "\(summary.wins)-\(summary.losses)-\(summary.draws)"
            )
        }
        .padding(.horizontal, 24)
        // ステータスバーと、その下に重なるツールバー（設定ギア）の両方を避ける。
        .padding(.top, topInset + 56)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            ZStack {
                AppTheme.heroMesh(for: colorScheme)
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
    let label: String

    var body: some View {
        Label(label, systemImage: "calendar")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .glassEffect(.regular, in: .capsule)
    }
}

private struct HeroScoreboard: View {
    let gamesValue: String
    let recordValue: String

    var body: some View {
        HStack(spacing: 0) {
            statChip(label: L10n.seasonGamesMetricLabel, value: gamesValue)

            Divider()
                .overlay(.white.opacity(0.2))
                .frame(height: 44)

            statChip(label: L10n.seasonRecordMetricLabel, value: recordValue)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: AppTheme.heroCornerRadius, style: .continuous))
    }

    private func statChip(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            StatValueText(value: value, size: 30, weight: .semibold, color: .white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
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

struct SeasonSummaryCard: View {
    @Environment(\.appColors) private var colors
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let summary: SeasonSummary

    private var metrics: [SeasonMetric] {
        // 試合数と勝敗はヒーローのスコアボードが担うため、ここでは重複させない。
        [
            SeasonMetric(
                label: L10n.seasonRunsMetricLabel,
                value: "\(summary.totalRuns)"
            ),
            SeasonMetric(
                label: L10n.seasonAverageMetricLabel,
                value: summary.battingAverage,
                emphasized: true
            ),
            SeasonMetric(
                label: L10n.seasonEraMetricLabel,
                value: summary.era,
                emphasized: true
            ),
        ]
    }

    private var columnCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 2 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.seasonSummaryTitle)
                    .font(.title3.bold())
                    .foregroundStyle(colors.onSurface)

                Text(L10n.seasonSummarySubtitle(summary.year))
                    .font(.footnote)
                    .foregroundStyle(colors.onSurfaceVariant)
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 12, alignment: .leading),
                    count: columnCount
                ),
                alignment: .leading,
                spacing: 20
            ) {
                ForEach(metrics) { metric in
                    SeasonMetricTile(metric: metric)
                }
            }
        }
        .cardStyle(padding: 20)
    }
}

private struct SeasonMetric: Identifiable {
    let label: String
    let value: String
    var emphasized = false

    var id: String { label }
}

private struct SeasonMetricTile: View {
    @Environment(\.appColors) private var colors

    let metric: SeasonMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            StatValueText(
                value: metric.value,
                size: 28,
                weight: .semibold,
                color: metric.emphasized ? colors.primary : colors.onSurface
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            Text(metric.label)
                .font(.caption)
                .foregroundStyle(colors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
