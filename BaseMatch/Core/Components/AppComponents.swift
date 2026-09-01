import SwiftUI

/// ヒーロー／サマリー用の濃色パネル。ブランド色のベタ塗りで、装飾は重ねない。
struct PrimaryPanel<Content: View>: View {
    @Environment(\.appColors) private var colors

    var padding = EdgeInsets(top: Spacing.md, leading: Spacing.md, bottom: Spacing.md, trailing: Spacing.md)
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colors.primary, in: .rect(cornerRadius: Radius.large, style: .continuous))
    }
}

/// セクション見出し。List/Form の header と同じ重みに揃える。
struct SectionHeaderBar: View {
    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(.headline)
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
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: Radius.small, style: .continuous))
            .contentTransition(.numericText())
            .animation(.smooth, value: count)
    }
}

/// 勝敗・打席結果などの状態バッジ。画面ごとに散っていた Capsule 実装を集約する。
struct StatusBadge: View {
    let title: LocalizedStringResource
    var tint: Color
    /// 濃色面に載せるときは、地の色を透かさずベタ塗りにする。
    var onDarkBackground = false

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(onDarkBackground ? Color.white : tint)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(
                onDarkBackground ? Color.white.opacity(0.2) : tint.opacity(0.15),
                in: .rect(cornerRadius: Radius.small, style: .continuous)
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
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(colors.primary)
            }
        }
    }
}

/// 主要アクション。塗りつぶしの角丸で、押下は不透明度だけで返す。
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.appColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? colors.onPrimary : Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                isEnabled ? colors.primary : Color(.tertiarySystemFill),
                in: .rect(cornerRadius: Radius.medium, style: .continuous)
            )
            .contentShape(.rect(cornerRadius: Radius.medium, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// 副次アクション。面を持たず、文字色だけで主要アクションと差をつける。
struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.appColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    var height: CGFloat = 50
    var foreground: Color?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? (foreground ?? colors.primary) : Color(.tertiaryLabel))
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                Color(.tertiarySystemFill),
                in: .rect(cornerRadius: Radius.medium, style: .continuous)
            )
            .contentShape(.rect(cornerRadius: Radius.medium, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
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
        HStack(spacing: Spacing.sm) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(colors.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Spacing.xxs) {
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
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            Color(.tertiarySystemFill),
            in: .rect(cornerRadius: Radius.medium, style: .continuous)
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
/// 固定 pt をやめ Dynamic Type に追随させるため、段階は `Scale` で選ぶ。
struct StatValueText: View {
    enum Scale {
        /// 画面の主役になる 1 つの数値。
        case hero
        /// セクション内で目立たせる数値。
        case prominent
        /// 一覧に並ぶ数値。
        case standard
        /// 補足の数値。
        case compact

        var font: Font {
            switch self {
            case .hero: .largeTitle
            case .prominent: .title
            case .standard: .title3
            case .compact: .headline
            }
        }
    }

    let value: String
    var scale: Scale = .prominent
    var weight: Font.Weight = .bold
    var color: Color?

    var body: some View {
        Text(value)
            .font(scale.font.weight(weight))
            .fontDesign(.rounded)
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(color ?? Color(.label))
            .animation(.smooth, value: value)
    }
}

/// 選択肢のチップ。選択は塗りつぶしで示し、形の変化は付けない。
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
            HStack(spacing: Spacing.xxs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? colors.onPrimary : colors.onSurface)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                isSelected ? activeTint : Color(.tertiarySystemFill),
                in: .rect(cornerRadius: Radius.small, style: .continuous)
            )
            .contentShape(.rect(cornerRadius: Radius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// 下部固定アクションやクイック操作に使うボタン。
struct ActionButton: View {
    @Environment(\.appColors) private var colors

    let title: LocalizedStringResource
    var systemImage: String?
    var isProminent = false
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xxs) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(ActionButtonStyle(isProminent: isProminent, tint: tint ?? colors.primary))
    }
}

private struct ActionButtonStyle: ButtonStyle {
    @Environment(\.appColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    let isProminent: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        let foreground: Color = if !isEnabled {
            Color(.tertiaryLabel)
        } else if isProminent {
            colors.onPrimary
        } else {
            tint
        }

        return configuration.label
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.md)
            .background(
                isProminent
                    ? (isEnabled ? tint : Color(.tertiarySystemFill))
                    : Color(.tertiarySystemFill),
                in: .rect(cornerRadius: Radius.medium, style: .continuous)
            )
            .contentShape(.rect(cornerRadius: Radius.medium, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
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
    var resultLabel: LocalizedStringResource?
    var resultTint: Color?
    var compact = false
    var onDarkBackground = false

    private var primaryText: Color { onDarkBackground ? colors.onDark : colors.onSurface }
    private var secondaryText: Color {
        onDarkBackground ? colors.onDarkVariant : colors.onSurfaceVariant
    }

    var body: some View {
        VStack(spacing: compact ? Spacing.xs : Spacing.sm) {
            HStack(alignment: .center, spacing: Spacing.sm) {
                teamColumn(name: homeName, score: homeScore)

                Text(verbatim: "–")
                    .font(compact ? .title3 : .title)
                    .fontDesign(.rounded)
                    .foregroundStyle(secondaryText)

                teamColumn(name: awayName, score: awayScore)
            }

            if let resultLabel {
                StatusBadge(
                    title: resultLabel,
                    tint: resultTint ?? colors.primary,
                    onDarkBackground: onDarkBackground
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func teamColumn(name: String, score: Int) -> some View {
        VStack(spacing: compact ? Spacing.xxs : Spacing.xs) {
            Text(name)
                .font(.caption)
                .foregroundStyle(secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            StatValueText(
                value: "\(score)",
                scale: compact ? .standard : .hero,
                weight: .semibold,
                color: primaryText
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ViewModifier

/// 影ではなく背景色の差で面を分ける。ダークだけ、輪郭が消えないよう境界線を足す。
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
    }
}

extension View {
    func cardStyle(
        cornerRadius: CGFloat = Radius.medium,
        padding: CGFloat = Spacing.md
    ) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius, padding: padding))
    }
}

/// 登録済みの選手と過去に入力した名前から選ぶメニュー。
/// 直接入力も残すため、TextField は置き換えず横に並べる。
struct PlayerPickerMenu: View {
    @Environment(\.appColors) private var colors

    let candidates: [String]
    let onSelect: (String) -> Void

    var body: some View {
        if candidates.isEmpty {
            EmptyView()
        } else {
            Menu {
                ForEach(candidates, id: \.self) { name in
                    Button(name) { onSelect(name) }
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(colors.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel(L10n.playerSectionTitle)
            .accessibilityIdentifier("playerPicker")
        }
    }
}

extension Binding {
    /// Optional の有無を isPresented に橋渡しする。
    /// 削除確認のたびに同じ get/set を書いていたため共通化した。
    static func isPresent<Wrapped>(_ value: Binding<Wrapped?>) -> Binding<Bool> {
        Binding<Bool>(
            get: { value.wrappedValue != nil },
            set: { if !$0 { value.wrappedValue = nil } }
        )
    }
}
