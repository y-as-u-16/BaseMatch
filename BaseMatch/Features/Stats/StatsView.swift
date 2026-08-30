import SwiftUI

struct StatsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors

    @Binding var selection: AppTab
    @State private var period: StatsPeriod = .all
    @State private var playerFilter: String?

    /// 記録に出てくる選手名。絞り込みの選択肢。
    private var recordedPlayerNames: [String] {
        let names = store.plateAppearances.map(\.batterName)
            + store.pitchingAppearances.map(\.pitcherName)
        return Array(Set(names)).sorted()
    }

    private var hasAnyRecord: Bool {
        !store.plateAppearances.isEmpty || !store.pitchingAppearances.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if hasAnyRecord {
                    content
                } else {
                    EmptyStateView(
                        systemImage: "baseball",
                        title: L10n.statsEmptyTitle,
                        subtitle: L10n.statsEmptyMessage,
                        actionLabel: L10n.statsEmptyCta
                    ) {
                        selection = .record
                    }
                }
            }
            .background(colors.groupedBackground)
            .navigationTitle(L10n.statsTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var content: some View {
        let stats = periodStats(
            games: store.games,
            plateAppearances: store.plateAppearances,
            pitchingAppearances: store.pitchingAppearances,
            period: period
        )
        let battingRows = stats.batting.filter { playerFilter == nil || $0.playerName == playerFilter }
        let pitchingRows = stats.pitching.filter { playerFilter == nil || $0.playerName == playerFilter }

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StatsPeriodSelector(
                    period: $period,
                    availableMonths: availableMonths(store.games)
                )

                PlayerFilterSelector(
                    selected: $playerFilter,
                    candidates: recordedPlayerNames
                )

                statsSection(title: L10n.battingStatsTitle, isEmpty: battingRows.isEmpty, emptyLabel: L10n.noBattingStatsLabel) {
                    ForEach(battingRows) { row in
                        StatsPlayerCard(
                            playerName: row.playerName,
                            primaryLabel: L10n.seasonAverageMetricLabel,
                            primaryValue: row.stats.averageLabel,
                            metrics: [
                                StatsMiniMetric(label: L10n.statsHitsLabel, value: "\(row.stats.hits)"),
                                StatsMiniMetric(label: L10n.statsHomeRunsLabel, value: "\(row.stats.hr)"),
                                StatsMiniMetric(label: L10n.statsOpsLabel, value: row.stats.opsLabel),
                            ]
                        )
                    }
                }

                statsSection(title: L10n.pitchingStatsTitle, isEmpty: pitchingRows.isEmpty, emptyLabel: L10n.noPitchingStatsLabel) {
                    ForEach(pitchingRows) { row in
                        StatsPlayerCard(
                            playerName: row.playerName,
                            primaryLabel: L10n.seasonEraMetricLabel,
                            primaryValue: row.stats.eraLabel,
                            metrics: [
                                StatsMiniMetric(label: L10n.statsStrikeoutsLabel, value: "\(row.stats.strikeouts)"),
                                StatsMiniMetric(label: L10n.statsWhipLabel, value: row.stats.whipLabel),
                                StatsMiniMetric(label: L10n.statsAppearancesLabel, value: "\(row.stats.games)"),
                            ]
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .contentMargins(.bottom, AppTheme.floatingTabBarInset, for: .scrollContent)
    }

    @ViewBuilder
    private func statsSection(
        title: LocalizedStringResource,
        isEmpty: Bool,
        emptyLabel: LocalizedStringResource,
        @ViewBuilder rows: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderBar(title: title)

            if isEmpty {
                EmptyTextPanel(emptyLabel)
            } else {
                rows()
            }
        }
    }
}

private struct StatsMiniMetric: Identifiable {
    let label: LocalizedStringResource
    let value: String

    var id: String { String(localized: label) }
}

private struct StatsPeriodSelector: View {
    @Environment(\.appColors) private var colors

    @Binding var period: StatsPeriod
    let availableMonths: [DateComponents]

    private var monthLabel: LocalizedStringResource {
        switch period {
        case .all:
            return L10n.statsPeriodMonthPlaceholder
        case let .month(year, month):
            return L10n.statsPeriodMonth(year, month)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            SelectionChip(
                title: L10n.statsPeriodAll,
                systemImage: "infinity",
                isSelected: period.isAll
            ) {
                period = .all
            }

            if !availableMonths.isEmpty {
                Menu {
                    Picker(L10n.statsPeriodSectionLabel, selection: $period) {
                        ForEach(availableMonths, id: \.self) { components in
                            if let year = components.year, let month = components.month {
                                Text(L10n.statsPeriodMonth(year, month))
                                    .tag(StatsPeriod.month(year: year, month: month))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(monthLabel)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(period.isAll ? colors.onSurface : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        Capsule(style: .continuous)
                            .fill(period.isAll
                                ? AnyShapeStyle(Color(.tertiarySystemFill))
                                : AnyShapeStyle(colors.primary.gradient))
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: period)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.statsPeriodSectionLabel)
    }
}

private struct StatsPlayerCard: View {
    @Environment(\.appColors) private var colors
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let playerName: String
    let primaryLabel: LocalizedStringResource
    let primaryValue: String
    let metrics: [StatsMiniMetric]

    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(playerName)
                .font(.headline)
                .foregroundStyle(colors.onSurface)
                .lineLimit(1)

            headline

            Divider()

            metricRow
        }
        .cardStyle(padding: 18)
        .listItemTransition()
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 2) {
            StatValueText(value: primaryValue, size: 44, color: colors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(primaryLabel)
                .font(.caption)
                .foregroundStyle(colors.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var metricRow: some View {
        if isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(metrics) { metric in
                    HStack {
                        Text(metric.label)
                            .font(.caption)
                            .foregroundStyle(colors.onSurfaceVariant)
                        Spacer(minLength: 12)
                        StatValueText(value: metric.value, size: 17, weight: .semibold)
                    }
                }
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                ForEach(metrics) { metric in
                    VStack(spacing: 3) {
                        StatValueText(value: metric.value, size: 19, weight: .semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        Text(metric.label)
                            .font(.caption2)
                            .foregroundStyle(colors.onSurfaceVariant)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

/// 選手ごとの絞り込み。StatsPeriodSelector と同じ見た目に揃える。
private struct PlayerFilterSelector: View {
    @Environment(\.appColors) private var colors

    @Binding var selected: String?
    let candidates: [String]

    var body: some View {
        if candidates.count > 1 {
            HStack(spacing: 10) {
                SelectionChip(
                    title: L10n.statsFilterAllPlayers,
                    systemImage: "person.2",
                    isSelected: selected == nil
                ) {
                    selected = nil
                }

                Menu {
                    ForEach(candidates, id: \.self) { name in
                        Button(name) { selected = name }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person")
                        Text(selected ?? String(localized: L10n.playerSectionTitle))
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selected == nil ? colors.onSurface : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background {
                        Capsule(style: .continuous)
                            .fill(selected == nil
                                ? AnyShapeStyle(Color(.tertiarySystemFill))
                                : AnyShapeStyle(colors.primary.gradient))
                    }
                }
                .accessibilityIdentifier("playerFilter")
            }
            .sensoryFeedback(.selection, trigger: selected)
        }
    }
}
