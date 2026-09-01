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
                StatusBadge(title: isDraft ? L10n.homeDraftBadge : result.label, tint: badgeTint)

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
        .cardStyle()
        // 勝敗はバッジの文字でも示すため、この帯は色だけに依存しない補助。
        .overlay(alignment: .leading) {
            if showsResultAccent {
                Rectangle()
                    .fill(badgeTint)
                    .frame(width: 4)
                    .opacity(accentStrength)
            }
        }
        .clipShape(.rect(cornerRadius: Radius.medium, style: .continuous))
        .contentShape(.rect(cornerRadius: Radius.medium, style: .continuous))
    }
}
