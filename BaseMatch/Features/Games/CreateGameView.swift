import SwiftUI

struct CreateGameView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let editGameId: String?

    @State private var selectedDate: Date
    @State private var selectedMyTeamId: String?
    @State private var awayTeamName = ""
    @State private var location = ""
    @State private var inningRuns = InningRunsDraft()
    @State private var selectedInnings = 7
    @State private var isMyTeamHome = true

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

    /// Stepper を横に2つ並べると大きい文字で潰れるため、そこから縦積みに切り替える。
    private var isStackedLayout: Bool { dynamicTypeSize >= .accessibility1 }

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
            battingOrderSection
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

    /// 自チームの表示名。未選択時もラベルの幅が崩れないよう既定名で埋める。
    private var myTeamDisplayName: String {
        effectiveMyTeamId
            .flatMap { id in store.myTeams.first { $0.id == id }?.name }
            ?? String(localized: L10n.myTeamScoreboardLabel)
    }

    private var opponentDisplayName: String {
        let trimmed = awayTeamName.trimmed
        return trimmed.isEmpty ? String(localized: L10n.opponentScoreboardLabel) : trimmed
    }

    private var battingFirstTeamName: String {
        isMyTeamHome ? opponentDisplayName : myTeamDisplayName
    }

    private var battingSecondTeamName: String {
        isMyTeamHome ? myTeamDisplayName : opponentDisplayName
    }

    private var battingOrderSection: some View {
        Section {
            Picker(L10n.battingOrderLabel, selection: battingOrderSelection) {
                Text(L10n.myTeamBattingFirstLabel).tag(false)
                Text(L10n.myTeamBattingSecondLabel).tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityLabel(Text(L10n.battingOrderLabel))

            // どちらの枠にどのチームが入るかを名前で示す。表・裏だけだと
            // 自チームがどちらなのか読み取れず、逆に記録される。
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.sm) {
                    battingOrderSlot(half: L10n.topHalfLabel, teamName: battingFirstTeamName)

                    Divider()

                    battingOrderSlot(half: L10n.bottomHalfLabel, teamName: battingSecondTeamName)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    battingOrderSlot(half: L10n.topHalfLabel, teamName: battingFirstTeamName)
                    battingOrderSlot(half: L10n.bottomHalfLabel, teamName: battingSecondTeamName)
                }
            }
            .frame(maxWidth: .infinity)
        } header: {
            Text(L10n.battingOrderLabel)
        } footer: {
            Text(L10n.battingOrderHint)
        }
    }

    private func battingOrderSlot(half: LocalizedStringResource, teamName: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(half)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(colors.onSurfaceVariant)

            Text(teamName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(colors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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

    private var homeScore: Int { inningRuns.homeTotal }
    private var awayScore: Int { inningRuns.awayTotal }

    private var hasInningScores: Bool { !inningRuns.isEmpty }

    private var scoreSection: some View {
        Section {
            // 大きい文字では各行がチーム名を持つため、ヘッダーは重複になる。
            if !isStackedLayout {
                inningScoreHeaderRow
            }

            ForEach(0..<selectedInnings, id: \.self) { index in
                InningScoreRow(
                    inning: index + 1,
                    awayRuns: runsBinding(isHome: false, index: index),
                    homeRuns: runsBinding(isHome: true, index: index),
                    battingFirstTeamName: battingFirstTeamName,
                    battingSecondTeamName: battingSecondTeamName,
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

    /// 各回のステッパーだけだと、どちらの列が自チームか分からなくなる。
    private var inningScoreHeaderRow: some View {
        HStack(spacing: Spacing.sm) {
            Color.clear.frame(width: 52, height: 1)

            inningScoreHeaderCell(half: L10n.topHalfLabel, teamName: battingFirstTeamName)
            inningScoreHeaderCell(half: L10n.bottomHalfLabel, teamName: battingSecondTeamName)
        }
        .accessibilityHidden(true)
    }

    private func inningScoreHeaderCell(
        half: LocalizedStringResource,
        teamName: String
    ) -> some View {
        VStack(spacing: 0) {
            Text(half)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(colors.onSurfaceVariant)
            Text(teamName)
                .font(.caption2)
                .foregroundStyle(colors.onSurfaceTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private var totalRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(L10n.totalScoreLabel)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 12)
                totalValue(name: battingFirstTeamName, score: awayScore)
                totalValue(name: battingSecondTeamName, score: homeScore)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(L10n.totalScoreLabel)
                    .font(.subheadline.weight(.semibold))
                totalValue(name: battingFirstTeamName, score: awayScore)
                totalValue(name: battingSecondTeamName, score: homeScore)
            }
        }
    }

    private func totalValue(name: String, score: Int) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(name)
                .font(.caption2)
                .foregroundStyle(colors.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            StatValueText(value: "\(score)", scale: .standard, weight: .semibold, color: colors.primary)
        }
        .frame(minWidth: 60)
    }

    private func runsBinding(isHome: Bool, index: Int) -> Binding<Int> {
        Binding(
            get: { inningRuns.runs(isHome: isHome, inningIndex: index) },
            set: { newValue in
                inningRuns.setRuns(
                    newValue,
                    isHome: isHome,
                    inningIndex: index,
                    innings: selectedInnings
                )
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
                inningRuns.trim(to: newValue)
            }
        } header: {
            Text(L10n.inningsCountLabel)
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
        isMyTeamHome = game.isMyTeamHome
        // イニング別が未入力の試合は空のまま開く。合計を1回表に押し込むと嘘の記録になる。
        inningRuns = InningRunsDraft(
            home: store.inningRuns(gameId: game.id, isHome: true),
            away: store.inningRuns(gameId: game.id, isHome: false)
        )
    }

    /// 表・裏の枠は固定なので、先攻・後攻を変えたら入力済みの得点も入れ替える。
    /// そうしないと自チームの得点が相手のものとして保存される。
    /// onChange ではなく setter で捕まえるのは、既存試合の読み込みでの代入と
    /// ユーザー操作を区別するため。
    private var battingOrderSelection: Binding<Bool> {
        Binding(
            get: { isMyTeamHome },
            set: { newValue in
                guard newValue != isMyTeamHome else { return }
                isMyTeamHome = newValue
                inningRuns.swapHalves()
            }
        )
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
        let padded = inningRuns.padded(to: selectedInnings)

        if let editGameId {
            let updated = store.updateGame(
                gameId: editGameId,
                date: selectedDate,
                myTeamId: myTeamId,
                awayTeamName: trimmedAwayTeam,
                location: location.normalizedOptional,
                innings: selectedInnings,
                homeScore: submittedHomeScore,
                awayScore: submittedAwayScore,
                isMyTeamHome: isMyTeamHome
            )
            guard updated != nil else { return }
            if hasInningScores {
                store.replaceInningScores(
                    gameId: editGameId,
                    home: padded.home,
                    away: padded.away
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
                awayScore: submittedAwayScore,
                isMyTeamHome: isMyTeamHome
            )
            guard let created else { return }
            if hasInningScores {
                store.replaceInningScores(
                    gameId: created.id,
                    home: padded.home,
                    away: padded.away
                )
            }
            dismiss()
        }
    }

}

private struct InningScoreRow: View {
    @Environment(\.appColors) private var colors
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let inning: Int
    @Binding var awayRuns: Int
    @Binding var homeRuns: Int
    let battingFirstTeamName: String
    let battingSecondTeamName: String
    let range: ClosedRange<Int>

    /// Stepper の +/- は文字サイズに応じて広がる。2つを横に並べたままだと
    /// 数字が潰れて読めなくなるため、大きい文字では縦に積む。
    private var isStacked: Bool { dynamicTypeSize >= .accessibility1 }

    var body: some View {
        if isStacked {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                inningLabel

                halfStepper(
                    half: L10n.topHalfLabel,
                    teamName: battingFirstTeamName,
                    value: $awayRuns,
                    showsTeamName: true
                )
                halfStepper(
                    half: L10n.bottomHalfLabel,
                    teamName: battingSecondTeamName,
                    value: $homeRuns,
                    showsTeamName: true
                )
            }
        } else {
            HStack(spacing: Spacing.sm) {
                inningLabel
                    .frame(minWidth: 52, alignment: .leading)

                halfStepper(
                    half: L10n.topHalfLabel,
                    teamName: battingFirstTeamName,
                    value: $awayRuns,
                    showsTeamName: false
                )
                halfStepper(
                    half: L10n.bottomHalfLabel,
                    teamName: battingSecondTeamName,
                    value: $homeRuns,
                    showsTeamName: false
                )
            }
        }
    }

    private var inningLabel: some View {
        Text(L10n.inningNumberLabel(inning))
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(colors.onSurface)
            .monospacedDigit()
    }

    /// 縦積みのときは列ヘッダーが遠くなるため、各行にチーム名を出す。
    private func halfStepper(
        half: LocalizedStringResource,
        teamName: String,
        value: Binding<Int>,
        showsTeamName: Bool
    ) -> some View {
        Stepper(value: value, in: range) {
            HStack(spacing: Spacing.xxs) {
                Text(showsTeamName ? "\(String(localized: half))　\(teamName)" : String(localized: half))
                    .font(.caption)
                    .foregroundStyle(colors.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                StatValueText(
                    value: "\(value.wrappedValue)",
                    scale: .compact,
                    weight: .semibold,
                    color: colors.primary
                )
            }
        }
        .sensoryFeedback(.selection, trigger: value.wrappedValue)
        .accessibilityLabel(
            Text(L10n.inningHalfTeamAccessibilityLabel(
                inning,
                String(localized: half),
                teamName
            ))
        )
    }
}
