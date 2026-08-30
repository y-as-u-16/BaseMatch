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
    @State private var homeScore = 0
    @State private var awayScore = 0
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
                        Text(team.isDefault ? "\(team.name)（\(L10n.defaultMyTeamBadge)）" : team.name)
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

    private var scoreSection: some View {
        Section {
            ScoreStepperRow(label: L10n.homeScoreLabel, value: $homeScore, range: Self.scoreRange)
            ScoreStepperRow(label: L10n.awayScoreLabel, value: $awayScore, range: Self.scoreRange)
        } header: {
            Text("\(L10n.homeScoreLabel) / \(L10n.awayScoreLabel)")
        }
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
        homeScore = game.homeScore ?? 0
        awayScore = game.awayScore ?? 0
        selectedMyTeamId = game.myTeamId
        selectedInnings = game.innings ?? 7
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

        if let editGameId {
            let updated = store.updateGame(
                gameId: editGameId,
                date: selectedDate,
                myTeamId: myTeamId,
                awayTeamName: trimmedAwayTeam,
                location: location.normalizedOptional,
                innings: selectedInnings,
                homeScore: homeScore,
                awayScore: awayScore
            )
            if updated != nil { dismiss() }
        } else {
            let created = store.createGame(
                date: selectedDate,
                myTeamId: myTeamId,
                awayTeamName: trimmedAwayTeam,
                location: location.normalizedOptional,
                innings: selectedInnings,
                homeScore: homeScore,
                awayScore: awayScore
            )
            if created != nil { dismiss() }
        }
    }
}

private struct ScoreStepperRow: View {
    @Environment(\.appColors) private var colors

    let label: LocalizedStringResource
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack {
                Text(label)
                Spacer(minLength: 12)
                StatValueText(value: "\(value)", size: 22, weight: .semibold, color: colors.primary)
            }
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}
