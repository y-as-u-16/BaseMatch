import SwiftUI

struct PitchingInputView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    private let gameId: String?
    private let editRecordId: String?

    @State private var pitcherName = String(localized: L10n.defaultPlayerName)
    @State private var outsPitched = 3
    @State private var runs = 0
    @State private var earnedRuns = 0
    @State private var hitsAllowed = 0
    @State private var walks = 0
    @State private var strikeouts = 0
    @State private var homeRunsAllowed = 0
    @State private var alertMessage: LocalizedStringResource?
    @State private var isPopulated = false

    init(gameId: String) {
        self.gameId = gameId
        self.editRecordId = nil
    }

    init(editRecordId: String) {
        self.gameId = nil
        self.editRecordId = editRecordId
    }

    private var isEditMode: Bool { editRecordId != nil }

    private var editingRecord: PitchingAppearance? {
        editRecordId.flatMap { store.pitchingAppearance(id: $0) }
    }

    private var candidates: [String] {
        let targetGameId = gameId ?? editingRecord?.gameId
        let myTeamId = targetGameId.flatMap { store.game(id: $0)?.myTeamId }
        return store.playerNameSuggestions(myTeamId: myTeamId)
    }

    var body: some View {
        Group {
            if isEditMode, editingRecord == nil {
                notFoundBody
            } else {
                formBody
            }
        }
        .navigationTitle(isEditMode ? L10n.editPitchingTitle : L10n.pitchingInputTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        // ホームの toolbarBackground(.hidden) が push 先まで伝播する。.automatic だと打ち消せないため .visible を使う。
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colors.groupedBackground, for: .navigationBar)
        .onAppear(perform: populateIfNeeded)
        .alert(alertMessage ?? "", isPresented: isAlertPresented) {
            Button(L10n.cancelButton, role: .cancel) {}
        }
    }

    private var notFoundBody: some View {
        VStack {
            if store.isLoaded {
                ContentUnavailableView(L10n.recordNotFound, systemImage: "questionmark.folder")
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.groupedBackground)
    }

    private var formBody: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                summaryHeader
                pitcherCard
                inningsCard
                counterGrid
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(colors.groupedBackground)
        .safeAreaInset(edge: .bottom) { saveBar }
    }

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    private var summaryHeader: some View {
        PrimaryPanel {
            VStack(spacing: Spacing.xxs) {
                Text(L10n.pitchingInningsLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colors.onDarkVariant)

                StatValueText(
                    value: String(localized: L10n.inningsFromOuts(outsPitched)),
                    scale: .hero,
                    weight: .semibold,
                    color: colors.onDark
                )
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                Text(L10n.outsLabel(outsPitched))
                    .font(.footnote)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(colors.onDarkVariant)

                Text(L10n.pitchingInputSummary(
                    String(localized: L10n.inningsFromOuts(outsPitched)),
                    runs,
                    earnedRuns
                ))
                .font(.caption)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(colors.onDarkVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .animation(.smooth, value: outsPitched)
            .animation(.smooth, value: runs)
            .animation(.smooth, value: earnedRuns)
        }
    }

    private var pitcherCard: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "person")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(colors.primary)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(L10n.pitcherNameLabel)
                    .font(.caption)
                    .foregroundStyle(colors.onSurfaceVariant)

                TextField(String(localized: L10n.pitcherNameLabel), text: $pitcherName)
                    .font(.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            PlayerPickerMenu(candidates: candidates) { pitcherName = $0 }
        }
        .cardStyle()
    }

    private var inningsCard: some View {
        VStack(spacing: 12) {
            CounterRow(
                label: L10n.pitchingInningsLabel,
                valueLabel: L10n.inningsFromOuts(outsPitched),
                valueWidth: 88,
                onDecrease: { outsPitched = clampOuts(outsPitched - 1) },
                onIncrease: { outsPitched = clampOuts(outsPitched + 1) }
            )

            HStack(spacing: 8) {
                ActionButton(title: L10n.addOneThirdInningButton) {
                    outsPitched = clampOuts(outsPitched + 1)
                }
                ActionButton(title: L10n.addOneInningButton) {
                    outsPitched = clampOuts(outsPitched + 3)
                }
                ActionButton(title: L10n.resetOneInningButton) {
                    outsPitched = 3
                }
            }
        }
        .cardStyle()
    }

    private var counterGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(counters, id: \.systemImage) { counter in
                CompactCounterCard(
                    label: counter.label,
                    systemImage: counter.systemImage,
                    value: counter.value
                )
            }
        }
    }

    private var counters: [(label: LocalizedStringResource, systemImage: String, value: Binding<Int>)] {
        [
            (L10n.runsLabel, "arrow.down.circle", $runs),
            (L10n.earnedRunsLabel, "exclamationmark.circle", $earnedRuns),
            (L10n.hitsAllowedLabel, "baseball", $hitsAllowed),
            (L10n.walksAllowedLabel, "figure.walk", $walks),
            (L10n.strikeoutsLabel, "xmark.circle", $strikeouts),
            (L10n.homeRunsAllowedLabel, "baseball.fill", $homeRunsAllowed),
        ]
    }

    private var saveBar: some View {
        ActionButton(
            title: L10n.saveButton,
            systemImage: "checkmark",
            isProminent: true,
            action: save
        )
        .padding(.horizontal, 16)
        .padding(.vertical, Spacing.sm)
        .background(.bar)
    }

    private func clampOuts(_ value: Int) -> Int {
        min(max(value, 1), 99)
    }

    private func save() {
        let name = pitcherName.trimmed
        guard !name.isEmpty else {
            alertMessage = L10n.playerNameRequired
            return
        }

        if let editRecordId {
            store.updatePitchingAppearance(
                id: editRecordId,
                pitcherName: name,
                outsPitched: outsPitched,
                runs: runs,
                earnedRuns: earnedRuns,
                hitsAllowed: hitsAllowed,
                walks: walks,
                strikeouts: strikeouts,
                homeRunsAllowed: homeRunsAllowed
            )
        } else if let gameId {
            store.addPitchingAppearance(
                gameId: gameId,
                pitcherName: name,
                outsPitched: outsPitched,
                runs: runs,
                earnedRuns: earnedRuns,
                hitsAllowed: hitsAllowed,
                walks: walks,
                strikeouts: strikeouts,
                homeRunsAllowed: homeRunsAllowed
            )
        }
        dismiss()
    }

    private func populateIfNeeded() {
        guard !isPopulated else { return }

        guard let record = editingRecord else {
            // 新規入力はデフォルト選手から始める。毎回選び直させない。
            if let name = defaultName {
                isPopulated = true
                pitcherName = name
            }
            return
        }

        isPopulated = true
        pitcherName = record.pitcherName
        outsPitched = record.outsPitched
        runs = record.runs
        earnedRuns = record.earnedRuns
        hitsAllowed = record.hitsAllowed
        walks = record.walks
        strikeouts = record.strikeouts
        homeRunsAllowed = record.homeRunsAllowed
    }

    private var defaultName: String? {
        let myTeamId = gameId.flatMap { store.game(id: $0)?.myTeamId }
        return store.defaultPlayerName(myTeamId: myTeamId)
    }
}

private struct CompactCounterCard: View {
    @Environment(\.appColors) private var colors

    let label: LocalizedStringResource
    let systemImage: String
    @Binding var value: Int

    @State private var tapCount = 0

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Label(label, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(colors.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.xxs) {
                stepButton(systemImage: "minus") { value = max(0, value - 1) }

                StatValueText(
                    value: "\(value)",
                    scale: .standard,
                    weight: .semibold,
                    color: value > 0 ? colors.primary : colors.onSurfaceVariant
                )
                .frame(maxWidth: .infinity)

                stepButton(systemImage: "plus") { value = min(99, value + 1) }
            }
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            colors.cardBackground,
            in: .rect(cornerRadius: Radius.medium, style: .continuous)
        )
        .sensoryFeedback(.selection, trigger: tapCount)
    }

    private func stepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            tapCount += 1
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(colors.primary)
                .frame(width: 44, height: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(systemImage == "plus" ? L10n.incrementAccessibilityLabel(String(localized: label)) : L10n.decrementAccessibilityLabel(String(localized: label)))
    }
}
