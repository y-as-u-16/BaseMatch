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
        awayScore: Int = 0,
        isMyTeamHome: Bool = true
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
            innings: innings,
            isMyTeamHome: isMyTeamHome
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
        awayScore: Int,
        isMyTeamHome: Bool
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
        game.isMyTeamHome = isMyTeamHome
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
        try validatePlateAppearance(batterName: batterName, inning: inning, rbi: rbi)
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
        try validatePitchingAppearance(
            pitcherName: pitcherName, outsPitched: outsPitched, runs: runs,
            earnedRuns: earnedRuns, hitsAllowed: hitsAllowed, walks: walks,
            strikeouts: strikeouts, homeRunsAllowed: homeRunsAllowed
        )
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

    func allInningScores() throws -> [InningScore] {
        try context.fetch(FetchDescriptor<InningScore>())
    }

    func inningScores(gameId: String) throws -> [InningScore] {
        let descriptor = FetchDescriptor<InningScore>(
            predicate: #Predicate { $0.gameId == gameId },
            sortBy: [SortDescriptor(\.inning)]
        )
        return try context.fetch(descriptor)
    }

    /// イニング別得点を丸ごと入れ替え、合計スコアも同時に更新する。
    /// 差分更新にすると入力欄の増減と噛み合わず状態が崩れるため、都度消して入れ直す。
    func replaceInningScores(gameId: String, home: [Int], away: [Int]) throws {
        guard home.allSatisfy({ $0 >= 0 }), away.allSatisfy({ $0 >= 0 }) else {
            throw AppError.validation("0以上の点数を入力してください")
        }
        guard let game = try game(id: gameId) else {
            throw AppError.notFound("試合が見つかりません")
        }

        try context.delete(model: InningScore.self, where: #Predicate { $0.gameId == gameId })

        for (index, runs) in home.enumerated() {
            context.insert(
                InningScore(gameId: gameId, inning: index + 1, isHome: true, runs: runs)
            )
        }
        for (index, runs) in away.enumerated() {
            context.insert(
                InningScore(gameId: gameId, inning: index + 1, isHome: false, runs: runs)
            )
        }

        // 合計は必ずイニング別から導く。二重管理を避けるため手入力は受け付けない。
        game.homeScore = home.reduce(0, +)
        game.awayScore = away.reduce(0, +)
        try context.save()
    }

    func updatePlateAppearance(
        id: String,
        batterName: String,
        resultType: PlateAppearanceResultType,
        resultDetail: PlateAppearanceResultDetail,
        inning: Int?,
        rbi: Int?
    ) throws {
        try validatePlateAppearance(batterName: batterName, inning: inning, rbi: rbi)

        var descriptor = FetchDescriptor<PlateAppearance>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            throw AppError.notFound("打席記録が見つかりません")
        }

        record.batterName = batterName.trimmed
        record.resultType = resultType
        record.resultDetail = resultDetail
        record.inning = inning
        record.rbi = rbi
        try context.save()
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
    ) throws {
        try validatePitchingAppearance(
            pitcherName: pitcherName,
            outsPitched: outsPitched,
            runs: runs,
            earnedRuns: earnedRuns,
            hitsAllowed: hitsAllowed,
            walks: walks,
            strikeouts: strikeouts,
            homeRunsAllowed: homeRunsAllowed
        )

        var descriptor = FetchDescriptor<PitchingAppearance>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            throw AppError.notFound("投球記録が見つかりません")
        }

        record.pitcherName = pitcherName.trimmed
        record.outsPitched = outsPitched
        record.runs = runs
        record.earnedRuns = earnedRuns
        record.hitsAllowed = hitsAllowed
        record.walks = walks
        record.strikeouts = strikeouts
        record.homeRunsAllowed = homeRunsAllowed
        try context.save()
    }

    /// 子レコードは `gameId` の手動外部キーで繋がっており `@Relationship` が無い。
    /// deleteRule を書く場所が無いため、ここで明示的に消す。
    func deleteGame(id: String) throws {
        guard let game = try game(id: id) else { return }

        try context.delete(model: PlateAppearance.self, where: #Predicate { $0.gameId == id })
        try context.delete(model: PitchingAppearance.self, where: #Predicate { $0.gameId == id })
        try context.delete(model: InningScore.self, where: #Predicate { $0.gameId == id })
        context.delete(game)
        try context.save()
    }

    func deletePlateAppearance(id: String) throws {
        try context.delete(model: PlateAppearance.self, where: #Predicate { $0.id == id })
        try context.save()
    }

    func deletePitchingAppearance(id: String) throws {
        try context.delete(model: PitchingAppearance.self, where: #Predicate { $0.id == id })
        try context.save()
    }

    private func validatePlateAppearance(
        batterName: String,
        inning: Int?,
        rbi: Int?
    ) throws {
        guard !batterName.trimmed.isEmpty else {
            throw AppError.validation("選手名を入力してください")
        }
        if let inning, inning <= 0 {
            throw AppError.validation("イニングは1以上で入力してください")
        }
        if let rbi, rbi < 0 {
            throw AppError.validation("打点は0以上で入力してください")
        }
    }

    private func validatePitchingAppearance(
        pitcherName: String,
        outsPitched: Int,
        runs: Int,
        earnedRuns: Int,
        hitsAllowed: Int,
        walks: Int,
        strikeouts: Int,
        homeRunsAllowed: Int
    ) throws {
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
