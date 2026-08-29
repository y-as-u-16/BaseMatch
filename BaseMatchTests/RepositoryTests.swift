import Foundation
import SwiftData
import Testing

@testable import BaseMatch

@MainActor
private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: MyTeam.self, Game.self, PlateAppearance.self, PitchingAppearance.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ModelContext(container)
}

@Suite("MyTeamRepository")
@MainActor
struct MyTeamRepositoryTests {
    @Test("最初のチームは自動的にデフォルトになる")
    func firstTeamBecomesDefault() throws {
        let repository = MyTeamRepository(context: try makeContext())

        let team = try repository.createMyTeam(name: "ホークス")

        #expect(team.isDefault)
        #expect(team.displayOrder == 0)
    }

    @Test("チーム名は trim され、空なら弾かれる")
    func nameIsTrimmedAndRequired() throws {
        let repository = MyTeamRepository(context: try makeContext())

        let team = try repository.createMyTeam(name: "  タイガース  ")
        #expect(team.name == "タイガース")

        #expect(throws: AppError.self) {
            try repository.createMyTeam(name: "   ")
        }
    }

    @Test("2つ目以降はデフォルトにならず、表示順が増える")
    func secondTeamKeepsOrder() throws {
        let repository = MyTeamRepository(context: try makeContext())

        _ = try repository.createMyTeam(name: "A")
        let second = try repository.createMyTeam(name: "B")

        #expect(!second.isDefault)
        #expect(second.displayOrder == 1)
        #expect(try repository.myTeams().count == 2)
    }

    @Test("デフォルト指定すると既存のデフォルトが解除される")
    func defaultIsExclusive() throws {
        let repository = MyTeamRepository(context: try makeContext())

        let first = try repository.createMyTeam(name: "A")
        let second = try repository.createMyTeam(name: "B", isDefault: true)

        #expect(!first.isDefault)
        #expect(second.isDefault)
        #expect(try repository.defaultMyTeam()?.id == second.id)
    }

    @Test("colorKey の空文字は nil に正規化される")
    func blankColorKeyBecomesNil() throws {
        let repository = MyTeamRepository(context: try makeContext())

        let team = try repository.createMyTeam(name: "A", colorKey: "   ")

        #expect(team.colorKey == nil)
    }

    @Test("デフォルトを切り替えると他のチームは外れる")
    func setDefaultMovesTheFlag() throws {
        let repository = MyTeamRepository(context: try makeContext())
        let first = try repository.createMyTeam(name: "A")
        let second = try repository.createMyTeam(name: "B")

        try repository.setDefaultMyTeam(id: second.id)

        #expect(!first.isDefault)
        #expect(second.isDefault)
        #expect(try repository.defaultMyTeam()?.id == second.id)
    }

    @Test("既にデフォルトのチームを指定しても状態は変わらない")
    func setDefaultOnCurrentDefaultKeepsIt() throws {
        let repository = MyTeamRepository(context: try makeContext())
        let only = try repository.createMyTeam(name: "A")

        try repository.setDefaultMyTeam(id: only.id)

        #expect(only.isDefault)
        #expect(try repository.myTeams().filter(\.isDefault).count == 1)
    }

    @Test("存在しない ID を指定すると失敗する")
    func setDefaultWithUnknownIdThrows() throws {
        let repository = MyTeamRepository(context: try makeContext())
        _ = try repository.createMyTeam(name: "A")

        #expect(throws: AppError.self) {
            try repository.setDefaultMyTeam(id: "not-exist")
        }
    }
}

@Suite("GameRepository")
@MainActor
struct GameRepositoryTests {
    private func makeRepositories() throws -> (GameRepository, MyTeamRepository) {
        let context = try makeContext()
        return (GameRepository(context: context), MyTeamRepository(context: context))
    }

    @Test("試合を作成すると draft 状態で保存される")
    func createGameStartsAsDraft() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")

        let game = try games.createGame(
            date: Date(),
            myTeamId: team.id,
            awayTeamName: "  相手  ",
            location: "  東京ドーム  ",
            innings: 7,
            homeScore: 3,
            awayScore: 2
        )

        #expect(game.status == .draft)
        #expect(game.awayTeamName == "相手")
        #expect(game.location == "東京ドーム")
        #expect(try games.games().count == 1)
    }

    @Test("空の球場名は nil として保存される")
    func blankLocationBecomesNil() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")

        let game = try games.createGame(
            date: Date(), myTeamId: team.id, awayTeamName: "相手", location: "   "
        )

        #expect(game.location == nil)
    }

    @Test("相手チーム名が空、得点が負、イニングが0以下なら弾かれる")
    func validatesGameInput() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")

        #expect(throws: AppError.self) {
            try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "  ")
        }
        #expect(throws: AppError.self) {
            try games.createGame(
                date: Date(), myTeamId: team.id, awayTeamName: "相手", homeScore: -1
            )
        }
        #expect(throws: AppError.self) {
            try games.createGame(
                date: Date(), myTeamId: team.id, awayTeamName: "相手", innings: 0
            )
        }
        #expect(throws: AppError.self) {
            try games.createGame(date: Date(), myTeamId: "  ", awayTeamName: "相手")
        }
    }

    @Test("試合を更新しても status と createdAt は保持される")
    func updateKeepsStatus() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "旧")
        let createdAt = game.createdAt

        let updated = try games.updateGame(
            gameId: game.id,
            date: game.date,
            myTeamId: team.id,
            awayTeamName: "新",
            location: nil,
            innings: 9,
            homeScore: 5,
            awayScore: 1
        )

        #expect(updated.awayTeamName == "新")
        #expect(updated.innings == 9)
        #expect(updated.status == .draft)
        #expect(updated.createdAt == createdAt)
    }

    @Test("存在しない試合の更新は notFound になる")
    func updateMissingGameThrows() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")

        #expect(throws: AppError.self) {
            try games.updateGame(
                gameId: "missing",
                date: Date(),
                myTeamId: team.id,
                awayTeamName: "相手",
                location: nil,
                innings: nil,
                homeScore: 0,
                awayScore: 0
            )
        }
    }

    @Test("打席を追加できる。イニングと打点の不正値は弾く")
    func addPlateAppearance() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        let appearance = try games.addPlateAppearance(
            gameId: game.id,
            batterName: "  佐藤  ",
            resultType: .hit,
            resultDetail: .single,
            inning: 3,
            rbi: 1
        )

        #expect(appearance.batterName == "佐藤")
        #expect(appearance.resultType == .hit)
        #expect(try games.plateAppearances().count == 1)

        #expect(throws: AppError.self) {
            try games.addPlateAppearance(
                gameId: game.id, batterName: " ", resultType: .hit, resultDetail: .single
            )
        }
        #expect(throws: AppError.self) {
            try games.addPlateAppearance(
                gameId: game.id, batterName: "佐藤",
                resultType: .hit, resultDetail: .single, inning: 0
            )
        }
        #expect(throws: AppError.self) {
            try games.addPlateAppearance(
                gameId: game.id, batterName: "佐藤",
                resultType: .hit, resultDetail: .single, rbi: -1
            )
        }
    }

    @Test("存在しない試合への打席追加は notFound になる")
    func addPlateAppearanceToMissingGame() throws {
        let (games, _) = try makeRepositories()

        #expect(throws: AppError.self) {
            try games.addPlateAppearance(
                gameId: "missing", batterName: "佐藤", resultType: .hit, resultDetail: .single
            )
        }
    }

    @Test("登板を追加できる。アウト0以下と負の値は弾く")
    func addPitchingAppearance() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        let appearance = try games.addPitchingAppearance(
            gameId: game.id,
            pitcherName: "田中",
            outsPitched: 9,
            runs: 2,
            earnedRuns: 1,
            hitsAllowed: 4,
            walks: 2,
            strikeouts: 7,
            homeRunsAllowed: 0
        )

        #expect(appearance.outsPitched == 9)
        #expect(try games.pitchingAppearances().count == 1)

        #expect(throws: AppError.self) {
            try games.addPitchingAppearance(
                gameId: game.id, pitcherName: "田中", outsPitched: 0,
                runs: 0, earnedRuns: 0, hitsAllowed: 0,
                walks: 0, strikeouts: 0, homeRunsAllowed: 0
            )
        }
        #expect(throws: AppError.self) {
            try games.addPitchingAppearance(
                gameId: game.id, pitcherName: "田中", outsPitched: 3,
                runs: -1, earnedRuns: 0, hitsAllowed: 0,
                walks: 0, strikeouts: 0, homeRunsAllowed: 0
            )
        }
    }

    @Test("finalizeGame で status が final になる")
    func finalizeGame() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        try games.finalizeGame(id: game.id)

        #expect(try games.game(id: game.id)?.status == .final_)
    }
}

@Suite("SeasonSummary")
@MainActor
struct SeasonSummaryTests {
    private func game(id: String, year: Int, home: Int, away: Int) -> Game {
        var components = DateComponents()
        components.year = year
        components.month = 5
        components.day = 1
        let date = Calendar.current.date(from: components)!
        return Game(
            id: id,
            date: date,
            myTeamId: "team-1",
            awayTeamName: "Away",
            homeScore: home,
            awayScore: away,
            createdAt: date
        )
    }

    private var now: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 1))!
    }

    @Test("当年の試合だけを集計し、勝敗と得点を数える")
    func aggregatesCurrentSeason() {
        let summary = SeasonSummary.from(
            games: [
                game(id: "g1", year: 2026, home: 5, away: 3),
                game(id: "g2", year: 2026, home: 1, away: 4),
                game(id: "g3", year: 2026, home: 2, away: 2),
                game(id: "g4", year: 2025, home: 9, away: 0),
            ],
            plateAppearances: [],
            pitchingAppearances: [],
            now: now
        )

        #expect(summary.year == 2026)
        #expect(summary.games == 3)
        #expect(summary.wins == 1)
        #expect(summary.losses == 1)
        #expect(summary.draws == 1)
        #expect(summary.totalRuns == 8)
    }

    @Test("記録がなければ打率 .000 / 防御率 -.--")
    func emptyRecords() {
        let summary = SeasonSummary.from(
            games: [], plateAppearances: [], pitchingAppearances: [], now: now
        )

        #expect(summary.games == 0)
        #expect(summary.battingAverage == ".000")
        #expect(summary.era == "-.--")
    }

    @Test("当年の打席・登板だけが打率と防御率に反映される")
    func statsAreScopedToSeason() {
        let currentGame = game(id: "g-now", year: 2026, home: 1, away: 0)
        let pastGame = game(id: "g-past", year: 2025, home: 1, away: 0)

        let summary = SeasonSummary.from(
            games: [currentGame, pastGame],
            plateAppearances: [
                PlateAppearance(
                    gameId: "g-now", resultType: .hit, resultDetail: .single
                ),
                PlateAppearance(
                    gameId: "g-past", resultType: .out, resultDetail: .k
                ),
            ],
            pitchingAppearances: [
                PitchingAppearance(gameId: "g-now", outsPitched: 9, earnedRuns: 1)
            ],
            now: now
        )

        #expect(summary.battingAverage == "1.000")
        #expect(summary.era == "3.00")
    }
}
