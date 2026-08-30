import SwiftUI

/// go_router のパス定義に相当する画面遷移。
enum GameRoute: Hashable {
    case create(date: Date)
    case edit(gameId: String)
    case detail(gameId: String)
    case plateAppearanceInput(gameId: String)
    case pitchingInput(gameId: String)
    case plateAppearanceEdit(recordId: String)
    case pitchingEdit(recordId: String)

    @ViewBuilder
    func destination() -> some View {
        switch self {
        case let .create(date):
            CreateGameView(initialDate: date)
        case let .edit(gameId):
            CreateGameView(editGameId: gameId)
        case let .detail(gameId):
            GameDetailView(gameId: gameId)
        case let .plateAppearanceInput(gameId):
            PlateAppearanceInputView(gameId: gameId)
        case let .pitchingInput(gameId):
            PitchingInputView(gameId: gameId)
        case let .plateAppearanceEdit(recordId):
            PlateAppearanceInputView(editRecordId: recordId)
        case let .pitchingEdit(recordId):
            PitchingInputView(editRecordId: recordId)
        }
    }
}

/// 勝敗表示。移行元の GameRecordResult。
enum GameRecordResult {
    case win, draw, loss

    var label: LocalizedStringResource {
        switch self {
        case .win: L10n.gameResultWin
        case .draw: L10n.gameResultDraw
        case .loss: L10n.gameResultLoss
        }
    }

    static func from(homeScore: Int, awayScore: Int) -> Self {
        if homeScore == awayScore { return .draw }
        return homeScore > awayScore ? .win : .loss
    }

    func color(_ colors: AppColors) -> Color {
        switch self {
        case .win: colors.primary
        case .draw: colors.tertiary
        case .loss: colors.outline
        }
    }

    func containerColor(_ colors: AppColors) -> Color {
        switch self {
        case .win: colors.primaryContainer
        case .draw: colors.tertiaryContainer
        case .loss: colors.surfaceContainerHighest
        }
    }

    func onContainerColor(_ colors: AppColors) -> Color {
        switch self {
        case .win: colors.onPrimaryContainer
        case .draw: colors.onTertiaryContainer
        case .loss: colors.onSurfaceVariant
        }
    }
}

/// ホームと記録タブで共有する試合カード。
struct GameRecordCard: View {
    @Environment(\.appColors) private var colors

    let game: Game
    let title: String
    var showsResultAccent = false

    private var homeScore: Int { game.homeScore ?? 0 }
    private var awayScore: Int { game.awayScore ?? 0 }
    private var result: GameRecordResult {
        .from(homeScore: homeScore, awayScore: awayScore)
    }

    private var isDraft: Bool { game.status == .draft }

    private var badgeTint: Color {
        guard !isDraft else { return colors.tertiary }
        switch result {
        case .win: return colors.winColor
        case .draw: return colors.drawColor
        case .loss: return colors.lossColor
        }
    }

    /// 負けは中立色のため、強く出すと画面が濁る。効いている結果だけ濃く出す。
    private var accentStrength: Double {
        !isDraft && result == .loss ? 0.45 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(game.date.slashDateLabel)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(colors.onSurfaceVariant)

                Spacer(minLength: 0)

                // 記録途中の試合に勝敗を出すと確定済みに見えてしまう。
                Text(isDraft ? L10n.homeDraftBadge : result.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(badgeTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background {
                        Capsule(style: .continuous)
                            .fill(badgeTint.opacity(0.14))
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(badgeTint.opacity(0.28), lineWidth: 0.5)
                            }
                    }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colors.onSurfaceTertiary)
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(colors.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            ScoreBoardView(
                homeName: "HOME",
                homeScore: homeScore,
                awayName: "AWAY",
                awayScore: awayScore,
                compact: true
            )

            if let location = game.location?.normalizedOptional {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(colors.onSurfaceVariant)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .padding(.leading, showsResultAccent ? 6 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardSurface }
        .clipShape(.rect(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .strokeBorder(colors.cardBorder, lineWidth: colors.cardBorderWidth)
        }
        .shadow(color: colors.cardShadow, radius: 10, y: 4)
        .contentShape(.rect(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }

    /// 勝敗を文字より先に伝える左端の帯と、平坦さを消すための淡い色被り。
    @ViewBuilder
    private var cardSurface: some View {
        if showsResultAccent {
            colors.cardBackground
                .overlay {
                    LinearGradient(
                        colors: [badgeTint.opacity(accentStrength * 0.14), .clear],
                        startPoint: .leading,
                        endPoint: UnitPoint(x: 0.5, y: 0.5)
                    )
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(badgeTint.gradient)
                        .frame(width: 6)
                        .opacity(accentStrength)
                }
        } else {
            colors.cardBackground
        }
    }
}
