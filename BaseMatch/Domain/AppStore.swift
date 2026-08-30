import Foundation
import SwiftData
import SwiftUI

/// 移行元の Riverpod StateNotifier（LocalGameStore / MyTeamStore）に相当する単一ストア。
/// SwiftData の @Query は View 単位になるため、集計や絞り込みを共有できるよう
/// 全レコードをメモリ上に保持する（ローカル完結・件数が小さい前提）。
@Observable
@MainActor
final class AppStore {
    private(set) var games: [Game] = []
    private(set) var plateAppearances: [PlateAppearance] = []
    private(set) var pitchingAppearances: [PitchingAppearance] = []
    private(set) var myTeams: [MyTeam] = []
    private(set) var isLoaded = false
    var errorMessage: String?

    private let gameRepository: GameRepository
    private let myTeamRepository: MyTeamRepository

    init(context: ModelContext) {
        self.gameRepository = GameRepository(context: context)
        self.myTeamRepository = MyTeamRepository(context: context)
    }

    /// 日付降順（移行元の gamesProvider と同じ並び）。
    var sortedGames: [Game] {
        games.sorted { $0.date > $1.date }
    }

    var myTeamById: [String: MyTeam] {
        Dictionary(uniqueKeysWithValues: myTeams.map { ($0.id, $0) })
    }

    var defaultMyTeam: MyTeam? {
        myTeams.first(\.isDefault)
    }

    func game(id: String) -> Game? {
        games.first { $0.id == id }
    }

    func plateAppearances(gameId: String) -> [PlateAppearance] {
        plateAppearances.filter { $0.gameId == gameId }
    }

    func pitchingAppearances(gameId: String) -> [PitchingAppearance] {
        pitchingAppearances.filter { $0.gameId == gameId }
    }

    func plateAppearance(id: String) -> PlateAppearance? {
        plateAppearances.first { $0.id == id }
    }

    func pitchingAppearance(id: String) -> PitchingAppearance? {
        pitchingAppearances.first { $0.id == id }
    }

    func teamName(for game: Game) -> String {
        myTeamById[game.myTeamId]?.name ?? String(localized: L10n.unknownMyTeamLabel)
    }

    func load() {
        perform {
            games = try gameRepository.games()
            plateAppearances = try gameRepository.plateAppearances()
            pitchingAppearances = try gameRepository.pitchingAppearances()
            myTeams = try myTeamRepository.myTeams()
            isLoaded = true
        }
    }

    @discardableResult
    func createGame(
        date: Date,
        myTeamId: String,
        awayTeamName: String,
        location: String?,
        innings: Int?,
        homeScore: Int,
        awayScore: Int
    ) -> Game? {
        perform {
            let game = try gameRepository.createGame(
                date: date,
                myTeamId: myTeamId,
                awayTeamName: awayTeamName,
                location: location,
                innings: innings,
                homeScore: homeScore,
                awayScore: awayScore
            )
            games = try gameRepository.games()
            return game
        }
    }

    @discardableResult
    func updateGame(
        gameId: String,
        date: Date,
        myTeamId: String,
        awayTeamName: String,
        location: String?,
        innings: Int?,
        homeScore: Int,
        awayScore: Int
    ) -> Game? {
        perform {
            let game = try gameRepository.updateGame(
                gameId: gameId,
                date: date,
                myTeamId: myTeamId,
                awayTeamName: awayTeamName,
                location: location,
                innings: innings,
                homeScore: homeScore,
                awayScore: awayScore
            )
            games = try gameRepository.games()
            return game
        }
    }

    @discardableResult
    func addPlateAppearance(
        gameId: String,
        batterName: String,
        resultType: PlateAppearanceResultType,
        resultDetail: PlateAppearanceResultDetail,
        inning: Int?,
        rbi: Int?
    ) -> PlateAppearance? {
        perform {
            let appearance = try gameRepository.addPlateAppearance(
                gameId: gameId,
                batterName: batterName,
                resultType: resultType,
                resultDetail: resultDetail,
                inning: inning,
                rbi: rbi
            )
            plateAppearances = try gameRepository.plateAppearances()
            return appearance
        }
    }

    @discardableResult
    func addPitchingAppearance(
        gameId: String,
        pitcherName: String,
        outsPitched: Int,
        runs: Int,
        earnedRuns: Int,
        hitsAllowed: Int,
        walks: Int,
        strikeouts: Int,
        homeRunsAllowed: Int
    ) -> PitchingAppearance? {
        perform {
            let appearance = try gameRepository.addPitchingAppearance(
                gameId: gameId,
                pitcherName: pitcherName,
                outsPitched: outsPitched,
                runs: runs,
                earnedRuns: earnedRuns,
                hitsAllowed: hitsAllowed,
                walks: walks,
                strikeouts: strikeouts,
                homeRunsAllowed: homeRunsAllowed
            )
            pitchingAppearances = try gameRepository.pitchingAppearances()
            return appearance
        }
    }

    func finalizeGame(id: String) {
        perform {
            try gameRepository.finalizeGame(id: id)
            games = try gameRepository.games()
        }
    }

    func updatePlateAppearance(
        id: String,
        batterName: String,
        resultType: PlateAppearanceResultType,
        resultDetail: PlateAppearanceResultDetail,
        inning: Int?,
        rbi: Int?
    ) {
        perform {
            try gameRepository.updatePlateAppearance(
                id: id,
                batterName: batterName,
                resultType: resultType,
                resultDetail: resultDetail,
                inning: inning,
                rbi: rbi
            )
            plateAppearances = try gameRepository.plateAppearances()
        }
    }

    func updatePitchingAppearance(
        id: String,
        pitcherName: String,
        outsPitched: Int,
        runs: Int,
        earnedRuns: Int,
        hitsAllowed: Int,
        walks: Int,
        strikeouts: Int,
        homeRunsAllowed: Int
    ) {
        perform {
            try gameRepository.updatePitchingAppearance(
                id: id,
                pitcherName: pitcherName,
                outsPitched: outsPitched,
                runs: runs,
                earnedRuns: earnedRuns,
                hitsAllowed: hitsAllowed,
                walks: walks,
                strikeouts: strikeouts,
                homeRunsAllowed: homeRunsAllowed
            )
            pitchingAppearances = try gameRepository.pitchingAppearances()
        }
    }

    func deleteGame(id: String) {
        perform {
            try gameRepository.deleteGame(id: id)
            games = try gameRepository.games()
            plateAppearances = try gameRepository.plateAppearances()
            pitchingAppearances = try gameRepository.pitchingAppearances()
        }
    }

    func deletePlateAppearance(id: String) {
        perform {
            try gameRepository.deletePlateAppearance(id: id)
            plateAppearances = try gameRepository.plateAppearances()
        }
    }

    func deletePitchingAppearance(id: String) {
        perform {
            try gameRepository.deletePitchingAppearance(id: id)
            pitchingAppearances = try gameRepository.pitchingAppearances()
        }
    }

    @discardableResult
    func createMyTeam(name: String, colorKey: String? = nil, isDefault: Bool = false) -> MyTeam? {
        perform {
            let team = try myTeamRepository.createMyTeam(
                name: name,
                colorKey: colorKey,
                isDefault: isDefault
            )
            myTeams = try myTeamRepository.myTeams()
            return team
        }
    }

    func setDefaultMyTeam(id: String) {
        perform {
            try myTeamRepository.setDefaultMyTeam(id: id)
            myTeams = try myTeamRepository.myTeams()
        }
    }

    var seasonSummary: SeasonSummary {
        SeasonSummary.from(
            games: games,
            plateAppearances: plateAppearances,
            pitchingAppearances: pitchingAppearances
        )
    }

    private func perform(_ work: () throws -> Void) {
        do {
            try work()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func perform<T>(_ work: () throws -> T) -> T? {
        do {
            return try work()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

private extension Array {
    func first(_ keyPath: KeyPath<Element, Bool>) -> Element? {
        first { $0[keyPath: keyPath] }
    }
}
