import SwiftUI

struct CreateGameView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    private let editGameId: String?

    @State private var selectedDate: Date
    @State private var selectedMyTeamId: String?
    @State private var awayTeamName = ""
    @State private var location = ""
    @State private var homeInningRuns: [Int] = []
    @State private var awayInningRuns: [Int] = []
    @State private var selectedInnings = 7

    @State private var isPopulated = false
    @State private var isCreateMyTeamPresented = false
    @State private var awayTeamNameError: LocalizedStringResource?
    @State private var myTeamError: LocalizedStringResource?
    @FocusState private var isTextFieldFocused: Bool

    private static let baseInningsOptions = [3, 5, 7, 9]
    private static let scoreRange = 0...99

    init(initialDate: Date) {
        self.editGameId = nil
        _selectedDate = State(initialValue: initialDate.dateKey)
    }

    init(editGameId: String) {
        self.editGameId = editGameId
        _selectedDate = State(initialValue: Date().dateKey)
    }

    private var isEditMode: Bool { editGameId != nil }

    private var title: LocalizedStringResource {
        isEditMode ? L10n.editGameTitle : L10n.createGameTitle
    }

    private var submitLabel: LocalizedStringResource {
        isEditMode ? L10n.saveChangesButton : L10n.createButton
    }

    private var editingGame: Game? {
        editGameId.flatMap { store.game(id: $0) }
    }

    private var effectiveMyTeamId: String? {
        guard !store.myTeams.isEmpty else { return nil }
        if let selectedMyTeamId, store.myTeams.contains(where: { $0.id == selectedMyTeamId }) {
            return selectedMyTeamId
        }
        return store.defaultMyTeam?.id ?? store.myTeams.first?.id
    }

    private var inningsOptions: [Int] {
        Self.baseInningsOptions.contains(selectedInnings)
            ? Self.baseInningsOptions
            : (Self.baseInningsOptions + [selectedInnings]).sorted()
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let lower = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1)) ?? Date()
        let upper = calendar.date(byAdding: .day, value: 365, to: Date().dateKey) ?? Date()
        return lower...upper
    }

    var body: some View {
        Group {
            if isEditMode, editingGame == nil {
                notFoundBody
            } else {
                formBody
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        // ホームの toolbarBackground(.hidden) が push 先まで伝播する。.automatic だと打ち消せないため .visible を使う。
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colors.groupedBackground, for: .navigationBar)
        .onAppear(perform: populateIfNeeded)
    }

    private var notFoundBody: some View {
        VStack {
            if store.isLoaded {
                ContentUnavailableView(
                    L10n.gameNotFound,
                    systemImage: "questionmark.folder"
                )
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.groupedBackground)
    }

    private var formBody: some View {
        Form {
            matchupSection
            myTeamSection
            scoreSection
            inningsSection
        }
        .scrollDismissesKeyboard(.interactively)
        // Group 側に付けるとスクロールビューまで届かないため、Form に直接指定する。
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colors.groupedBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(submitLabel, action: submit)
                    .fontWeight(.semibold)
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.doneButton) { isTextFieldFocused = false }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $isCreateMyTeamPresented) {
            CreateMyTeamSheet()
        }
    }

    private var matchupSection: some View {
        Section {
            DatePicker(
                L10n.gameDateLabel,
                selection: $selectedDate,
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)

            TextField(String(localized: L10n.awayTeamNameLabel), text: $awayTeamName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isTextFieldFocused)
                .onChange(of: awayTeamName) { _, _ in awayTeamNameError = nil }

            TextField(String(localized: L10n.locationOptionalLabel), text: $location)
                .textInputAutocapitalization(.never)
                .focused($isTextFieldFocused)
        } header: {
            Text(L10n.gameDateLabel)
        } footer: {
            if let awayTeamNameError {
                Text(awayTeamNameError)
                    .foregroundStyle(colors.onErrorContainer)
            }
        }
    }

    private var myTeamSection: some View {
        Section {
            if store.myTeams.isEmpty {
                Text(L10n.noMyTeamsForGameSubtitle)
                    .font(.footnote)
                    .foregroundStyle(colors.onSurfaceVariant)
            } else {
                Picker(L10n.myTeamSelectLabel, selection: myTeamSelection) {
                    ForEach(store.myTeams) { team in
                        Text(team.isDefault
                            ? "\(team.name)（\(String(localized: L10n.defaultMyTeamBadge))）"
                            : team.name)
                            .tag(team.id as String?)
                    }
                }
                .pickerStyle(.menu)
                .tint(colors.primary)
            }

            Button {
                isCreateMyTeamPresented = true
            } label: {
                Label(L10n.addMyTeamButton, systemImage: "plus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
            }
            .tint(colors.primary)
        } header: {
            Text(L10n.myTeamSelectLabel)
        } footer: {
            if let myTeamError {
                Text(myTeamError)
                    .foregroundStyle(colors.onErrorContainer)
            }
        }
    }

    private var myTeamSelection: Binding<String?> {
        Binding(
            get: { effectiveMyTeamId },
            set: {
                selectedMyTeamId = $0
                myTeamError = nil
            }
        )
    }

    private var homeScore: Int { homeInningRuns.reduce(0, +) }
    private var awayScore: Int { awayInningRuns.reduce(0, +) }

    private var hasInningScores: Bool {
        !homeInningRuns.isEmpty || !awayInningRuns.isEmpty
    }

    private var scoreSection: some View {
        Section {
            ForEach(0..<selectedInnings, id: \.self) { index in
                InningScoreRow(
                    inning: index + 1,
                    awayRuns: runsBinding(for: $awayInningRuns, index: index),
                    homeRuns: runsBinding(for: $homeInningRuns, index: index),
                    range: Self.scoreRange
                )
            }

            totalRow
        } header: {
            Text(L10n.inningScoresLabel)
        } footer: {
            Text(L10n.inningScoresHint)
        }
    }

    private var totalRow: some View {
        HStack {
            Text(L10n.totalScoreLabel)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 12)
            totalValue(label: L10n.awayScoreLabel, score: awayScore)
            totalValue(label: L10n.homeScoreLabel, score: homeScore)
        }
    }

    private func totalValue(label: LocalizedStringResource, score: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(colors.onSurfaceVariant)
                .lineLimit(1)
            StatValueText(value: "\(score)", size: 22, weight: .semibold, color: colors.primary)
        }
        .frame(width: 72)
    }

    /// イニング数を増やしたときに配列が短いままだと落ちるため、読み出し時に 0 で補う。
    private func runsBinding(for source: Binding<[Int]>, index: Int) -> Binding<Int> {
        Binding(
            get: { index < source.wrappedValue.count ? source.wrappedValue[index] : 0 },
            set: { newValue in
                var runs = source.wrappedValue
                if runs.count < selectedInnings {
                    runs.append(contentsOf: Array(repeating: 0, count: selectedInnings - runs.count))
                }
                runs[index] = newValue
                source.wrappedValue = runs
            }
        )
    }

    private var inningsSection: some View {
        Section {
            Picker(L10n.inningsCountLabel, selection: $selectedInnings) {
                ForEach(inningsOptions, id: \.self) { innings in
                    Text(L10n.inningsShort(innings)).tag(innings)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: selectedInnings) { _, newValue in
                trimInningRuns(to: newValue)
            }
        } header: {
            Text(L10n.inningsCountLabel)
        }
    }

    /// イニング数を減らしたら余った回の得点は捨てる。合計に紛れ込むのを防ぐ。
    private func trimInningRuns(to innings: Int) {
        if homeInningRuns.count > innings {
            homeInningRuns = Array(homeInningRuns.prefix(innings))
        }
        if awayInningRuns.count > innings {
            awayInningRuns = Array(awayInningRuns.prefix(innings))
        }
    }

    private func populateIfNeeded() {
        guard !isPopulated, let game = editingGame else { return }
        isPopulated = true
        selectedDate = game.date.dateKey
        awayTeamName = game.awayTeamName
        location = game.location ?? ""
        selectedMyTeamId = game.myTeamId
        selectedInnings = game.innings ?? 7
        // イニング別が未入力の試合は空のまま開く。合計を1回表に押し込むと嘘の記録になる。
        homeInningRuns = store.inningRuns(gameId: game.id, isHome: true)
        awayInningRuns = store.inningRuns(gameId: game.id, isHome: false)
    }

    private func submit() {
        let trimmedAwayTeam = awayTeamName.trimmed
        awayTeamNameError = trimmedAwayTeam.isEmpty ? L10n.awayTeamNameRequired : nil

        guard let myTeamId = effectiveMyTeamId else {
            myTeamError = L10n.selectMyTeamRequired
            return
        }
        myTeamError = nil

        guard awayTeamNameError == nil else { return }

        // イニング別が空なら合計は既存値を保つ。0 で上書きすると旧データの記録が消える。
        let submittedHomeScore = hasInningScores ? homeScore : (editingGame?.homeScore ?? 0)
        let submittedAwayScore = hasInningScores ? awayScore : (editingGame?.awayScore ?? 0)

        if let editGameId {
            let updated = store.updateGame(
                gameId: editGameId,
                date: selectedDate,
                myTeamId: myTeamId,
                awayTeamName: trimmedAwayTeam,
                location: location.normalizedOptional,
                innings: selectedInnings,
                homeScore: submittedHomeScore,
                awayScore: submittedAwayScore
            )
            guard updated != nil else { return }
            if hasInningScores {
                store.replaceInningScores(
                    gameId: editGameId,
                    home: paddedRuns(homeInningRuns),
                    away: paddedRuns(awayInningRuns)
                )
            }
            dismiss()
        } else {
            let created = store.createGame(
                date: selectedDate,
                myTeamId: myTeamId,
                awayTeamName: trimmedAwayTeam,
                location: location.normalizedOptional,
                innings: selectedInnings,
                homeScore: submittedHomeScore,
                awayScore: submittedAwayScore
            )
            guard let created else { return }
            if hasInningScores {
                store.replaceInningScores(
                    gameId: created.id,
                    home: paddedRuns(homeInningRuns),
                    away: paddedRuns(awayInningRuns)
                )
            }
            dismiss()
        }
    }

    /// 表裏で長さがずれるとラインスコアの列が揃わないため、選んだイニング数まで 0 で埋める。
    private func paddedRuns(_ runs: [Int]) -> [Int] {
        guard runs.count < selectedInnings else { return Array(runs.prefix(selectedInnings)) }
        return runs + Array(repeating: 0, count: selectedInnings - runs.count)
    }
}

private struct InningScoreRow: View {
    @Environment(\.appColors) private var colors

    let inning: Int
    @Binding var awayRuns: Int
    @Binding var homeRuns: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Text(L10n.inningNumberLabel(inning))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(colors.onSurface)
                .monospacedDigit()
                .frame(width: 52, alignment: .leading)

            halfStepper(half: L10n.topHalfLabel, value: $awayRuns)
            halfStepper(half: L10n.bottomHalfLabel, value: $homeRuns)
        }
    }

    private func halfStepper(half: LocalizedStringResource, value: Binding<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack(spacing: 6) {
                Text(half)
                    .font(.caption)
                    .foregroundStyle(colors.onSurfaceVariant)
                StatValueText(
                    value: "\(value.wrappedValue)",
                    size: 20,
                    weight: .semibold,
                    color: colors.primary
                )
            }
        }
        .sensoryFeedback(.selection, trigger: value.wrappedValue)
        .accessibilityLabel(
            Text(L10n.inningRunsAccessibilityLabel(inning, String(localized: half)))
        )
    }
}
