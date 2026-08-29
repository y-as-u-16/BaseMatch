import SwiftUI

struct PlateAppearanceInputView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.appColors) private var colors
    @Environment(\.dismiss) private var dismiss

    private let gameId: String

    @State private var batterName = "自分"
    @State private var inning = 1
    @State private var rbi = 0
    @State private var selected: PlateAppearanceResultOption?
    @State private var alertMessage: String?

    init(gameId: String) {
        self.gameId = gameId
    }

    var body: some View {
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
        .navigationTitle(L10n.plateAppearanceInputTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        // ホームの toolbarBackground(.hidden) が push 先まで伝播する。.automatic だと打ち消せないため .visible を使う。
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colors.groupedBackground, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { saveBar }
        .alert(alertMessage ?? "", isPresented: isAlertPresented) {
            Button(L10n.cancelButton, role: .cancel) {}
        }
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
                Text(selected.detail.label)
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
                selected?.detail.label ?? L10n.notSelectedLabel,
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

                    TextField(L10n.batterNameLabel, text: $batterName)
                        .font(.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
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
        title: String,
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
                        title: option.detail.label,
                        systemImage: option.detail.systemImage,
                        tint: tint,
                        isSelected: selected == option,
                        action: { selected = option }
                    )
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

    private func save() {
        guard let selected else { return }
        let name = batterName.trimmed
        guard !name.isEmpty else {
            alertMessage = L10n.playerNameRequired
            return
        }

        store.addPlateAppearance(
            gameId: gameId,
            batterName: name,
            resultType: selected.type,
            resultDetail: selected.detail,
            inning: inning,
            rbi: rbi
        )
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
                AppTheme.heroMesh(for: colorScheme)
                    .overlay(.black.opacity(colorScheme == .dark ? 0.1 : 0))
            }
            .clipShape(.rect(cornerRadius: AppTheme.heroCornerRadius, style: .continuous))
            .shadow(color: AppTheme.fieldGreen.opacity(colorScheme == .dark ? 0.35 : 0.22), radius: 16, y: 10)
    }
}
