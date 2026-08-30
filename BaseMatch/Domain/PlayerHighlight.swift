import Foundation

/// ホーム画面に出す個人のハイライト。
/// 数字の羅列より「いま何が起きているか」が伝わる一言を優先する。
struct PlayerHighlight: Equatable, Sendable {
    let playerName: String
    let batting: BattingStats
    let hitStreak: Int

    /// 打席が1つも無い選手はホームに出しても意味がない。
    var hasRecords: Bool { batting.pa > 0 }

    static func make(
        playerName: String,
        games: [Game],
        plateAppearances: [PlateAppearance],
        now: Date = Date()
    ) -> Self {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let seasonGames = games
            .filter { calendar.component(.year, from: $0.date) == year }
            .sorted { $0.date < $1.date }
        let seasonGameIds = Set(seasonGames.map(\.id))

        let mine = plateAppearances.filter {
            $0.batterName == playerName && seasonGameIds.contains($0.gameId)
        }

        return Self(
            playerName: playerName,
            batting: BattingStats.from(mine),
            hitStreak: hitStreak(games: seasonGames, appearances: mine)
        )
    }

    /// 直近の試合からさかのぼり、安打のある試合が続いた数を返す。
    /// 出場していない試合は連続を切らさず読み飛ばす。
    private static func hitStreak(
        games: [Game],
        appearances: [PlateAppearance]
    ) -> Int {
        let byGame = Dictionary(grouping: appearances, by: \.gameId)
        var streak = 0

        for game in games.reversed() {
            guard let inGame = byGame[game.id], !inGame.isEmpty else { continue }
            guard inGame.contains(where: { $0.resultType == .hit }) else { break }
            streak += 1
        }
        return streak
    }
}
