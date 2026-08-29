import Foundation
import SwiftData

@MainActor
struct GameRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func games() throws -> [Game] {
        try context.fetch(FetchDescriptor<Game>())
    }

    func plateAppearances() throws -> [PlateAppearance] {
        try context.fetch(FetchDescriptor<PlateAppearance>())
    }

    func pitchingAppearances() throws -> [PitchingAppearance] {
        try context.fetch(FetchDescriptor<PitchingAppearance>())
    }

    func game(id: String) throws -> Game? {
        var descriptor = FetchDescriptor<Game>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func createGame(
        date: Date,
        myTeamId: String,
        awayTeamName: String,
        location: String? = nil,
        innings: Int? = nil,
        homeScore: Int = 0,
        awayScore: Int = 0
    ) throws -> Game {
        try validateGame(
            myTeamId: myTeamId,
            awayTeamName: awayTeamName,
            innings: innings,
            homeScore: homeScore,
            awayScore: awayScore
        )

        let game = Game(
            date: date,
            location: location?.normalizedOptional,
            myTeamId: myTeamId,
            awayTeamName: awayTeamName.trimmed,
            homeScore: homeScore,
            awayScore: awayScore,
            status: .draft,
            innings: innings
        )
        context.insert(game)
        try context.save()
        return game
    }

    @discardableResult
    func updateGame(
        gameId: String,
        date: Date,
        myTeamId: String,
        awayTeamName: String,
        location: String? = nil,
        innings: Int? = nil,
        homeScore: Int,
        awayScore: Int
    ) throws -> Game {
        try validateGame(
            myTeamId: myTeamId,
            awayTeamName: awayTeamName,
            innings: innings,
            homeScore: homeScore,
            awayScore: awayScore
        )

        guard let game = try game(id: gameId) else {
            throw AppError.notFound("試合が見つかりません")
        }

        game.date = date
        game.location = location?.normalizedOptional
        game.myTeamId = myTeamId
        game.awayTeamName = awayTeamName.trimmed
        game.innings = innings
        game.homeScore = homeScore
        game.awayScore = awayScore
        try context.save()
        return game
    }

    @discardableResult
    func addPlateAppearance(
        gameId: String,
        batterName: String,
        resultType: PlateAppearanceResultType,
        resultDetail: PlateAppearanceResultDetail,
        inning: Int? = nil,
        rbi: Int? = nil
    ) throws -> PlateAppearance {
        guard !gameId.trimmed.isEmpty else {
            throw AppError.validation("試合が指定されていません")
        }
        guard !batterName.trimmed.isEmpty else {
            throw AppError.validation("選手名を入力してください")
        }
        if let inning, inning <= 0 {
            throw AppError.validation("イニングは1以上で入力してください")
        }
        if let rbi, rbi < 0 {
            throw AppError.validation("打点は0以上で入力してください")
        }
        guard try game(id: gameId) != nil else {
            throw AppError.notFound("試合が見つかりません")
        }

        let appearance = PlateAppearance(
            gameId: gameId,
            batterName: batterName.trimmed,
            inning: inning,
            resultType: resultType,
            resultDetail: resultDetail,
            rbi: rbi
        )
        context.insert(appearance)
        try context.save()
        return appearance
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
    ) throws -> PitchingAppearance {
        guard !gameId.trimmed.isEmpty else {
            throw AppError.validation("試合が指定されていません")
        }
        guard !pitcherName.trimmed.isEmpty else {
            throw AppError.validation("選手名を入力してください")
        }
        guard outsPitched > 0 else {
            throw AppError.validation("投球回は1アウト以上で入力してください")
        }
        for value in [runs, earnedRuns, hitsAllowed, walks, strikeouts, homeRunsAllowed]
        where value < 0 {
            throw AppError.validation("0以上の値を入力してください")
        }
        guard try game(id: gameId) != nil else {
            throw AppError.notFound("試合が見つかりません")
        }

        let appearance = PitchingAppearance(
            gameId: gameId,
            pitcherName: pitcherName.trimmed,
            outsPitched: outsPitched,
            runs: runs,
            earnedRuns: earnedRuns,
            hitsAllowed: hitsAllowed,
            walks: walks,
            strikeouts: strikeouts,
            homeRunsAllowed: homeRunsAllowed
        )
        context.insert(appearance)
        try context.save()
        return appearance
    }

    func finalizeGame(id: String) throws {
        guard let game = try game(id: id) else { return }
        game.status = .final_
        try context.save()
    }

    private func validateGame(
        myTeamId: String,
        awayTeamName: String,
        innings: Int?,
        homeScore: Int,
        awayScore: Int
    ) throws {
        guard !myTeamId.trimmed.isEmpty else {
            throw AppError.validation("自チームを選択してください")
        }
        guard !awayTeamName.trimmed.isEmpty else {
            throw AppError.validation("相手チーム名を入力してください")
        }
        if let innings, innings <= 0 {
            throw AppError.validation("イニング数は1以上で入力してください")
        }
        guard homeScore >= 0, awayScore >= 0 else {
            throw AppError.validation("0以上の点数を入力してください")
        }
    }
}
