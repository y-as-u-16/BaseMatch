import SwiftUI

/// go_router のパス定義に相当する画面遷移。
enum GameRoute: Hashable {
    case create(date: Date)
    case edit(gameId: String)
    case detail(gameId: String)
    case plateAppearanceInput(gameId: String)
    case pitchingInput(gameId: String)

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
        }
    }
}

/// 勝敗表示。移行元の GameRecordResult。
enum GameRecordResult {
    case win, draw, loss

    var label: String {
        switch self {
        case .win: "W"
        case .draw: "D"
        case .loss: "L"
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

    private var homeScore: Int { game.homeScore ?? 0 }
    private var awayScore: Int { game.awayScore ?? 0 }
    private var result: GameRecordResult {
        .from(homeScore: homeScore, awayScore: awayScore)
    }

    private var resultTint: Color {
        switch result {
        case .win: colors.winColor
        case .draw: colors.drawColor
        case .loss: colors.lossColor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(game.date.slashDateLabel)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(colors.onSurfaceVariant)

                Spacer(minLength: 0)

                Text(result.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(resultTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(resultTint.opacity(0.14), in: .capsule)

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
        .contentShape(.rect(cornerRadius: AppTheme.cardCornerRadius, style: .continuous))
    }
}
