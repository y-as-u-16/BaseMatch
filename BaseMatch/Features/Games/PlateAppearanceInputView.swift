import SwiftUI

struct PlateAppearanceInputView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    private let gameId: String?
    private let editRecordId: String?

    @State private var batterName = String(localized: L10n.defaultPlayerName)
    @State private var inning = 1
    @State private var rbi = 0
    @State private var selected: PlateAppearanceResultOption?
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

    private var editingRecord: PlateAppearance? {
        editRecordId.flatMap { store.plateAppearance(id: $0) }
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
        .navigationTitle(isEditMode ? L10n.editPlateAppearanceTitle : L10n.plateAppearanceInputTitle)
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
            VStack(spacing: 20) {
                summaryHeader
                batterCard
                resultSection(
                    title: L10n.hitSectionTitle,
                    options: PlateAppearanceResultOption.hitOptions,
                    tint: colors.primary
                )
                resultSection(
                    title: L10n.outSectionTitle,
                    options: PlateAppearanceResultOption.outOptions,
                    tint: colors.lossColor
                )
                resultSection(
                    title: L10n.onBaseSectionTitle,
                    options: PlateAppearanceResultOption.onBaseOptions,
                    tint: colors.gold
                )
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
        VStack(spacing: 8) {
            if let selected {
                Text(selected.detail.localizedLabel)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text(L10n.selectPlateAppearanceResultMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(L10n.plateAppearanceSummary(
                inning,
                String(localized: selected?.detail.localizedLabel ?? L10n.notSelectedLabel),
                rbi
            ))
            .font(.footnote)
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .modifier(PrimaryPanelBackground(isCompact: selected == nil))
        .animation(.smooth, value: selected)
        .animation(.smooth, value: inning)
        .animation(.smooth, value: rbi)
    }

    private var batterCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(colors.primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.batterNameLabel)
                        .font(.caption)
                        .foregroundStyle(colors.onSurfaceVariant)

                    TextField(String(localized: L10n.batterNameLabel), text: $batterName)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                PlayerPickerMenu(candidates: candidates) { batterName = $0 }
            }
            .padding(.vertical, 4)

            Divider()

            CounterRow(
                label: L10n.inningLabel,
                valueLabel: L10n.inningsShort(inning),
                onDecrease: { inning = max(1, inning - 1) },
                onIncrease: { inning = min(99, inning + 1) }
            )

            CounterRow(
                label: L10n.rbiLabel,
                valueLabel: "\(rbi)",
                onDecrease: { rbi = max(0, rbi - 1) },
                onIncrease: { rbi = min(99, rbi + 1) }
            )
        }
        .cardStyle()
    }

    private func resultSection(
        title: LocalizedStringResource,
        options: [PlateAppearanceResultOption],
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderBar(title: title)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: 10)],
                spacing: 10
            ) {
                ForEach(options) { option in
                    SelectionChip(
                        title: option.detail.localizedLabel,
                        systemImage: option.detail.systemImage,
                        tint: tint,
                        isSelected: selected == option,
                        action: { selected = option }
                    )
                    .accessibilityIdentifier("chip-\(option.detail.rawValue)")
                }
            }
        }
    }

    private var saveBar: some View {
        GlassCapsuleButton(
            title: L10n.saveButton,
            systemImage: "checkmark",
            isProminent: true,
            action: save
        )
        .disabled(selected == nil)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private func populateIfNeeded() {
        guard !isPopulated else { return }

        if let record = editingRecord {
            isPopulated = true
            batterName = record.batterName
            inning = record.inning ?? 1
            rbi = record.rbi ?? 0
            selected = PlateAppearanceResultOption.all.first { $0.detail == record.resultDetail }
            return
        }

        // 新規入力はデフォルト選手から始める。毎回選び直させない。
        if let name = defaultName {
            isPopulated = true
            batterName = name
        }
    }

    private var defaultName: String? {
        let myTeamId = gameId.flatMap { store.game(id: $0)?.myTeamId }
        return store.defaultPlayerName(myTeamId: myTeamId)
    }

    private func save() {
        guard let selected else { return }
        let name = batterName.trimmed
        guard !name.isEmpty else {
            alertMessage = L10n.playerNameRequired
            return
        }

        if let editRecordId {
            store.updatePlateAppearance(
                id: editRecordId,
                batterName: name,
                resultType: selected.type,
                resultDetail: selected.detail,
                inning: inning,
                rbi: rbi
            )
        } else if let gameId {
            store.addPlateAppearance(
                gameId: gameId,
                batterName: name,
                resultType: selected.type,
                resultDetail: selected.detail,
                inning: inning,
                rbi: rbi
            )
        }
        dismiss()
    }
}

/// PrimaryPanel は ViewBuilder 型のためモディファイア経由で使えず、同じ質感を再現する。
private struct PrimaryPanelBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    var isCompact = false

    private var verticalPadding: CGFloat { isCompact ? 14 : 22 }

    func body(content: Content) -> some View {
        content
            .padding(EdgeInsets(top: verticalPadding, leading: 20, bottom: verticalPadding - 2, trailing: 20))
            .background {
                HeroBackground(colorScheme: colorScheme)
                    .overlay(.black.opacity(colorScheme == .dark ? 0.1 : 0))
            }
            .clipShape(.rect(cornerRadius: AppTheme.heroCornerRadius, style: .continuous))
            .shadow(color: AppTheme.fieldGreen.opacity(colorScheme == .dark ? 0.35 : 0.22), radius: 16, y: 10)
    }
}
