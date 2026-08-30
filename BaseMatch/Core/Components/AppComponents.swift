import SwiftUI

/// グループ化セル相当のカード。枠線を持たず、余白と1段の影で階層を作る。
struct AppPanel<Content: View>: View {
    @Environment(\.appColors) private var colors

    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    /// 旧 Material 実装との互換のため引数は残すが、枠線は描かない。
    var borderOpacity: Double = 0.5
    var shadowOpacity: Double = 0.045
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.cardBackground, in: .rect(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .strokeBorder(colors.cardBorder, lineWidth: colors.cardBorderWidth)
            }
            .shadow(color: colors.cardShadow.opacity(shadowOpacity > 0 ? 1 : 0), radius: 10, y: 4)
    }
}

/// ヒーロー／サマリー用の濃色パネル。fieldGreen → leatherBrown のメッシュで深みを出す。
struct PrimaryPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(EdgeInsets(top: 22, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                HeroBackground(colorScheme: colorScheme)
                    .overlay(.black.opacity(colorScheme == .dark ? 0.1 : 0))
            }
            .clipShape(.rect(cornerRadius: AppTheme.heroCornerRadius, style: .continuous))
            .shadow(color: AppTheme.fieldGreen.opacity(colorScheme == .dark ? 0.35 : 0.22), radius: 16, y: 10)
    }
}

struct SectionHeaderBar: View {
    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(.title3.bold())
            .foregroundStyle(Color(.label))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.footnote.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(Color(.secondaryLabel))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(.tertiarySystemFill), in: .capsule)
            .contentTransition(.numericText())
            .animation(.smooth, value: count)
    }
}

struct EmptyTextPanel: View {
    let text: LocalizedStringResource

    init(_ text: LocalizedStringResource) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 28)
            .padding(.horizontal, 16)
            .background(
                Color(.secondarySystemGroupedBackground),
                in: .rect(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
            )
    }
}

struct EmptyStateView: View {
    @Environment(\.appColors) private var colors

    let systemImage: String
    let title: LocalizedStringResource
    var subtitle: LocalizedStringResource?
    var actionLabel: LocalizedStringResource?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .symbolRenderingMode(.hierarchical)
        } description: {
            if let subtitle {
                Text(subtitle)
            }
        } actions: {
            if let actionLabel, let action {
                if #available(iOS 26, *) {
                    Button(actionLabel, action: action)
                        .buttonStyle(.glassProminent)
                        .tint(colors.primary)
                } else {
                    Button(actionLabel, action: action)
                        .buttonStyle(PrimaryActionButtonStyle(height: 44))
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
}

/// 主要アクション。Capsule のプロミネントグラスに押下スケールと Haptics を足す。
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.appColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? colors.onPrimary : Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, minHeight: height)
            .background {
                Capsule(style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(colors.primary.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
            }
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// 副次アクション。グラス素材で背景に馴染ませる。
struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.appColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    var height: CGFloat = 52
    var foreground: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? (foreground ?? colors.primary) : Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, minHeight: height)
            .adaptiveInteractiveGlass(in: .capsule)
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// 打席入力・投球入力で使う ± ステッパー行。タップ標的を 44pt 以上に確保する。
struct CounterRow: View {
    @Environment(\.appColors) private var colors

    let label: LocalizedStringResource
    let valueLabel: LocalizedStringResource
    var valueWidth: CGFloat = 72
    var emphasizeValue = true
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    @State private var tapCount = 0

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                stepperButton(systemImage: "minus", action: onDecrease)

                Text(valueLabel)
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(emphasizeValue ? colors.primary : colors.onSurface)
                    .frame(minWidth: valueWidth)
                    .animation(.smooth, value: valueLabel)

                stepperButton(systemImage: "plus", action: onIncrease)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Color(.tertiarySystemFill),
            in: .rect(cornerRadius: AppTheme.controlCornerRadius, style: .continuous)
        )
        .sensoryFeedback(.selection, trigger: tapCount)
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            tapCount += 1
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(colors.primary)
                .frame(width: 44, height: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(systemImage == "plus" ? L10n.incrementAccessibilityLabel(String(localized: label)) : L10n.decrementAccessibilityLabel(String(localized: label)))
    }
}

// MARK: - 追加部品

/// 打率・防御率など、主役になる数値の表示。
struct StatValueText: View {
    let value: String
    var size: CGFloat = 34
    var weight: Font.Weight = .bold
    var color: Color?

    var body: some View {
        Text(value)
            .font(.system(size: size, weight: weight, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(color ?? Color(.label))
            .animation(.smooth, value: value)
    }
}

/// 選択肢の Capsule チップ。選択時に Haptics と軽いスケールが付く。
struct SelectionChip: View {
    @Environment(\.appColors) private var colors

    let title: LocalizedStringResource
    var systemImage: String?
    var tint: Color?
    let isSelected: Bool
    let action: () -> Void

    private var activeTint: Color { tint ?? colors.primary }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .symbolEffect(.bounce, value: isSelected)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : colors.onSurface)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                Capsule(style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(activeTint.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
            }
            .contentShape(.capsule)
            .scaleEffect(isSelected ? 1.03 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// グラス素材の Capsule ボタン。下部固定アクションやクイック操作に使う。
struct GlassCapsuleButton: View {
    let title: LocalizedStringResource
    var systemImage: String?
    var isProminent = false
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(GlassCapsuleButtonStyle(isProminent: isProminent, tint: tint))
    }
}

private struct GlassCapsuleButtonStyle: ButtonStyle {
    @Environment(\.appColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    let isProminent: Bool
    let tint: Color?

    func makeBody(configuration: Configuration) -> some View {
        let accent = tint ?? colors.primary
        let foreground: AnyShapeStyle = isEnabled
            ? AnyShapeStyle(isProminent ? AnyShapeStyle(colors.onPrimary) : AnyShapeStyle(accent))
            : AnyShapeStyle(Color(.tertiaryLabel))
        return configuration.label
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .background {
                if isProminent {
                    Capsule(style: .continuous)
                        .fill(isEnabled ? AnyShapeStyle(accent.gradient) : AnyShapeStyle(Color(.tertiarySystemFill)))
                }
            }
            .adaptiveInteractiveGlass(in: .capsule)
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// HOME / AWAY のスコア表示。試合カードと試合詳細で共用する。
struct ScoreBoardView: View {
    @Environment(\.appColors) private var colors

    let homeName: String
    let homeScore: Int
    let awayName: String
    let awayScore: Int
    var resultLabel: String?
    var resultTint: Color?
    var compact = false
    var onDarkBackground = false

    private var primaryText: Color { onDarkBackground ? .white : colors.onSurface }
    private var secondaryText: Color {
        onDarkBackground ? .white.opacity(0.75) : colors.onSurfaceVariant
    }

    var body: some View {
        VStack(spacing: compact ? 8 : 14) {
            HStack(alignment: .center, spacing: 12) {
                teamColumn(name: homeName, score: homeScore)

                Text("-")
                    .font(.system(size: compact ? 20 : 28, weight: .light, design: .rounded))
                    .foregroundStyle(secondaryText)

                teamColumn(name: awayName, score: awayScore)
            }

            if let resultLabel {
                Text(resultLabel)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(onDarkBackground ? .white : (resultTint ?? colors.primary))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background {
                        Capsule(style: .continuous)
                            .fill(onDarkBackground
                                ? AnyShapeStyle(.white.opacity(0.22))
                                : AnyShapeStyle((resultTint ?? colors.primary).opacity(0.14)))
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func teamColumn(name: String, score: Int) -> some View {
        VStack(spacing: compact ? 2 : 6) {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            StatValueText(
                value: "\(score)",
                size: compact ? 26 : 44,
                weight: .semibold,
                color: primaryText
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewModifier

private struct CardStyleModifier: ViewModifier {
    @Environment(\.appColors) private var colors

    let cornerRadius: CGFloat
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                colors.cardBackground,
                in: .rect(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(colors.cardBorder, lineWidth: colors.cardBorderWidth)
            }
            .shadow(color: colors.cardShadow, radius: 10, y: 4)
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = AppTheme.cardCornerRadius,
        padding: CGFloat = 16
    ) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius, padding: padding))
    }

    /// スクロール入場の軽いフェード＋スケール。リスト項目に使う。
    func listItemTransition() -> some View {
        scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.4)
                .scaleEffect(phase.isIdentity ? 1 : 0.96)
        }
    }
}
