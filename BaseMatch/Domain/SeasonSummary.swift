import Foundation

struct SeasonSummary: Equatable, Sendable {
    let year: Int
    let games: Int
    let wins: Int
    let losses: Int
    let draws: Int
    let totalRuns: Int
    let battingAverage: String
    let era: String

    static func from(
        games: [Game],
        plateAppearances: [PlateAppearance],
        pitchingAppearances: [PitchingAppearance],
        now: Date = Date()
    ) -> Self {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let seasonGames = games.filter { calendar.component(.year, from: $0.date) == year }
        let seasonGameIds = Set(seasonGames.map(\.id))

        let batting = BattingStats.from(
            plateAppearances.filter { seasonGameIds.contains($0.gameId) }
        )
        let pitching = PitchingStats.from(
            pitchingAppearances.filter { seasonGameIds.contains($0.gameId) }
        )

        var wins = 0
        var losses = 0
        var draws = 0
        var totalRuns = 0
        for game in seasonGames {
            let home = game.homeScore ?? 0
            let away = game.awayScore ?? 0
            totalRuns += home
            if home > away {
                wins += 1
            } else if home < away {
                losses += 1
            } else {
                draws += 1
            }
        }

        return Self(
            year: year,
            games: seasonGames.count,
            wins: wins,
            losses: losses,
            draws: draws,
            totalRuns: totalRuns,
            battingAverage: batting.averageLabel,
            era: pitching.eraLabel
        )
    }
}
