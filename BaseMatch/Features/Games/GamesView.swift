import SwiftUI

struct GamesView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors

    @State private var path = NavigationPath()
    @State private var selectedDate = Date().dateKey
    @State private var focusedMonth = Date().monthKey

    private var gameCountsByDate: [Date: Int] {
        store.games.reduce(into: [:]) { counts, game in
            counts[game.date.dateKey, default: 0] += 1
        }
    }

    private var selectedGames: [Game] {
        store.games
            .filter { $0.date.dateKey == selectedDate }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 28) {
                    CalendarCard(
                        month: focusedMonth,
                        selectedDate: selectedDate,
                        gameCountsByDate: gameCountsByDate,
                        onSelect: { selectedDate = $0 },
                        onChangeMonth: changeMonth
                    )

                    SelectedDateGameSection(
                        selectedDate: selectedDate,
                        games: selectedGames
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .contentMargins(.bottom, AppTheme.floatingTabBarInset, for: .scrollContent)
            .background(colors.groupedBackground)
            .navigationTitle(L10n.recordTitle)
            // .large だとツールバーの「+」がタイトルの上へ浮くため、標準の同一行配置にする。
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: GameRoute.self) { $0.destination() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(GameRoute.create(date: selectedDate))
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(L10n.addGameButton)
                }
            }
        }
    }

    private func changeMonth(by offset: Int) {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .month, value: offset, to: focusedMonth) else {
            return
        }
        focusedMonth = next.monthKey
        // 移行元と同じく、月移動で選択日もその月の 1 日へ追随させる。
        selectedDate = focusedMonth
    }
}

private struct CalendarCard: View {
    let month: Date
    let selectedDate: Date
    let gameCountsByDate: [Date: Int]
    let onSelect: (Date) -> Void
    let onChangeMonth: (Int) -> Void

    var body: some View {
        VStack(spacing: 16) {
            CalendarMonthHeader(
                month: month,
                onPrevious: { onChangeMonth(-1) },
                onNext: { onChangeMonth(1) }
            )

            CalendarMonthGrid(
                month: month,
                selectedDate: selectedDate,
                gameCountsByDate: gameCountsByDate,
                onSelect: onSelect
            )
            .id(month)
            .transition(.opacity)
        }
        .cardStyle(padding: 16)
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    onChangeMonth(value.translation.width < 0 ? 1 : -1)
                }
        )
        .animation(.smooth, value: month)
    }
}

private struct CalendarMonthHeader: View {
    @Environment(\.appColors) private var colors

    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void

    private static let monthFormat = Date.FormatStyle(date: .omitted)
        .year()
        .month(.defaultDigits)
        .locale(Locale(identifier: "ja_JP"))

    var body: some View {
        HStack(spacing: 8) {
            Text(month.formatted(Self.monthFormat))
                .font(.title2.bold())
                .foregroundStyle(colors.onSurface)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            monthButton(systemImage: "chevron.left", label: L10n.previousMonthTooltip, action: onPrevious)
            monthButton(systemImage: "chevron.right", label: L10n.nextMonthTooltip, action: onNext)
        }
    }

    private func monthButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(colors.primary)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct CalendarMonthGrid: View {
    @Environment(\.appColors) private var colors

    let month: Date
    let selectedDate: Date
    let gameCountsByDate: [Date: Int]
    let onSelect: (Date) -> Void

    /// グリッドが日曜始まり固定のため、日曜始まりで並ぶ標準シンボルをそのまま使う。
    private static let weekdayLabels: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        return calendar.veryShortStandaloneWeekdaySymbols
    }()

    /// 日曜始まりの 7 列に揃えるため、前後の空きは nil で埋める。
    private var days: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }

        let leadingBlanks = calendar.component(.weekday, from: month) - 1
        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: month))
        }
        let trailingBlanks = (7 - cells.count % 7) % 7
        cells.append(contentsOf: Array(repeating: nil, count: trailingBlanks))
        return cells
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(Self.weekdayLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(Self.weekdayColor(index, colors: colors))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7),
                spacing: 4
            ) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        CalendarDayCell(
                            day: day,
                            gameCount: gameCountsByDate[day] ?? 0,
                            isSelected: day == selectedDate,
                            onTap: { onSelect(day) }
                        )
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }

    /// 日本のカレンダー慣習に合わせ、土日だけ文字色を変える。
    static func weekdayColor(_ index: Int, colors: AppColors) -> Color {
        switch index {
        case 0: Color(.systemRed)
        case 6: Color(.systemBlue)
        default: colors.onSurfaceVariant
        }
    }
}

private struct CalendarDayCell: View {
    @Environment(\.appColors) private var colors

    let day: Date
    let gameCount: Int
    let isSelected: Bool
    let onTap: () -> Void

    private var isToday: Bool { day == Date().dateKey }
    private var weekdayIndex: Int { Calendar.current.component(.weekday, from: day) - 1 }

    private var foreground: Color {
        if isSelected { return .white }
        if isToday { return colors.primary }
        switch weekdayIndex {
        case 0: return Color(.systemRed)
        case 6: return Color(.systemBlue)
        default: return colors.onSurface
        }
    }

    private var dotCount: Int { min(gameCount, 3) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.body)
                    .monospacedDigit()
                    .fontWeight(isToday || isSelected ? .semibold : .regular)
                    .foregroundStyle(foreground)
                    .frame(width: 34, height: 34)
                    .background {
                        if isSelected {
                            Circle().fill(colors.primary.gradient)
                        }
                    }

                HStack(spacing: 3) {
                    ForEach(0..<dotCount, id: \.self) { _ in
                        Circle()
                            .fill(isSelected ? colors.primary : colors.primary.opacity(0.75))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
        .accessibilityLabel(day.slashDateLabel)
        .accessibilityValue(gameCount > 0 ? L10n.seasonGamesCount(gameCount) : "")
    }
}

private struct SelectedDateGameSection: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors

    let selectedDate: Date
    let games: [Game]

    private static let dayFormat = Date.FormatStyle(date: .omitted)
        .year()
        .month(.defaultDigits)
        .day()
        .locale(Locale(identifier: "ja_JP"))

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    SectionHeaderBar(title: L10n.selectedDateGamesTitle)

                    Text(selectedDate.formatted(Self.dayFormat))
                        .font(.footnote)
                        .foregroundStyle(colors.onSurfaceVariant)
                }

                Spacer(minLength: 0)

                if !games.isEmpty {
                    CountBadge(count: games.count)
                }
            }

            if games.isEmpty {
                ContentUnavailableView {
                    Label(L10n.noGamesOnSelectedDate, systemImage: "calendar")
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(games) { game in
                    NavigationLink(value: GameRoute.detail(gameId: game.id)) {
                        GameRecordCard(game: game, title: cardTitle(for: game))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("gameCard")
                    .listItemTransition()
                }
            }
        }
        .animation(.smooth, value: selectedDate)
    }

    private func cardTitle(for game: Game) -> String {
        "\(store.teamName(for: game)) vs \(game.awayTeamName)"
    }
}

extension Date {
    /// カレンダーの基準となる、その月の 1 日 0 時。
    var monthKey: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? dateKey
    }
}
