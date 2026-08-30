import Foundation
import SwiftData
import Testing

@testable import BaseMatch

@MainActor
private func makeContext() throws -> ModelContext {
    let container = try ModelContainer(
        for: MyTeam.self, Player.self, Game.self, InningScore.self,
        PlateAppearance.self, PitchingAppearance.self,
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

@Suite("PlayerRepository")
@MainActor
struct PlayerRepositoryTests {
    private func makeRepositories() throws -> (PlayerRepository, MyTeamRepository) {
        let context = try makeContext()
        return (PlayerRepository(context: context), MyTeamRepository(context: context))
    }

    @Test("選手を追加すると表示順が振られる")
    func createPlayerAssignsOrder() throws {
        let (players, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")

        let first = try players.createPlayer(name: "  田中  ", myTeamId: team.id)
        let second = try players.createPlayer(name: "佐藤", myTeamId: team.id)

        #expect(first.name == "田中")
        #expect(first.displayOrder == 0)
        #expect(second.displayOrder == 1)
        #expect(try players.players(myTeamId: team.id).count == 2)
    }

    @Test("空の名前は弾かれる")
    func blankNameThrows() throws {
        let (players, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")

        #expect(throws: AppError.self) {
            try players.createPlayer(name: "   ", myTeamId: team.id)
        }
    }

    @Test("同じチームに同名は追加できない")
    func duplicateNameInSameTeamThrows() throws {
        let (players, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        _ = try players.createPlayer(name: "田中", myTeamId: team.id)

        #expect(throws: AppError.self) {
            try players.createPlayer(name: "田中", myTeamId: team.id)
        }
    }

    @Test("別のチームなら同名でも追加できる")
    func sameNameInOtherTeamIsAllowed() throws {
        let (players, teams) = try makeRepositories()
        let teamA = try teams.createMyTeam(name: "A")
        let teamB = try teams.createMyTeam(name: "B")

        _ = try players.createPlayer(name: "田中", myTeamId: teamA.id)
        let other = try players.createPlayer(name: "田中", myTeamId: teamB.id)

        #expect(other.name == "田中")
        #expect(try players.players(myTeamId: teamB.id).count == 1)
    }

    @Test("選手を削除しても過去の記録は残る")
    func deletingPlayerKeepsRecords() throws {
        let context = try makeContext()
        let players = PlayerRepository(context: context)
        let teams = MyTeamRepository(context: context)
        let games = GameRepository(context: context)

        let team = try teams.createMyTeam(name: "A")
        let player = try players.createPlayer(name: "田中", myTeamId: team.id)
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        _ = try games.addPlateAppearance(
            gameId: game.id, batterName: "田中", resultType: .hit, resultDetail: .single
        )
        _ = try games.addPitchingAppearance(
            gameId: game.id, pitcherName: "田中", outsPitched: 3,
            runs: 0, earnedRuns: 0, hitsAllowed: 0, walks: 0, strikeouts: 1, homeRunsAllowed: 0
        )
        try players.deletePlayer(id: player.id)

        // 名簿からは消えるが、チームの通算成績が変わらないよう記録は残す。
        #expect(try players.players(myTeamId: team.id).isEmpty)
        #expect(try games.plateAppearances().count == 1)
        #expect(try games.pitchingAppearances().count == 1)
    }

    @Test("選手名を変更すると過去の記録も追従する")
    func renamingPlayerUpdatesRecords() throws {
        let context = try makeContext()
        let players = PlayerRepository(context: context)
        let teams = MyTeamRepository(context: context)
        let games = GameRepository(context: context)

        let team = try teams.createMyTeam(name: "A")
        let player = try players.createPlayer(name: "田中", myTeamId: team.id)
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        _ = try games.addPlateAppearance(
            gameId: game.id, batterName: "田中", resultType: .hit, resultDetail: .single
        )

        try players.renamePlayer(id: player.id, name: "田中太郎", myTeamId: team.id)

        // 記録は名前で紐づくため、改名したら記録側も直さないと成績が分断される。
        #expect(try players.players(myTeamId: team.id).first?.name == "田中太郎")
        #expect(try games.plateAppearances().first?.batterName == "田中太郎")
    }

    @Test("改名で同名が生まれる場合は弾かれる")
    func renamingToDuplicateThrows() throws {
        let (players, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        _ = try players.createPlayer(name: "田中", myTeamId: team.id)
        let second = try players.createPlayer(name: "佐藤", myTeamId: team.id)

        #expect(throws: AppError.self) {
            try players.renamePlayer(id: second.id, name: "田中", myTeamId: team.id)
        }
    }

    @Test("デフォルト選手は1人だけ")
    func defaultPlayerIsExclusive() throws {
        let (players, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let first = try players.createPlayer(name: "田中", myTeamId: team.id)
        let second = try players.createPlayer(name: "佐藤", myTeamId: team.id)

        // 最初の選手は自動的にデフォルト。
        #expect(first.isDefault)
        #expect(!second.isDefault)

        try players.setDefaultPlayer(id: second.id, myTeamId: team.id)

        #expect(!first.isDefault)
        #expect(second.isDefault)
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

    @Test("イニング別得点から合計が算出される")
    func inningScoresProduceTotals() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        try games.replaceInningScores(
            gameId: game.id,
            home: [0, 2, 0, 3, 0, 1, 0],
            away: [1, 0, 0, 0, 1, 0, 0]
        )

        let updated = try #require(try games.game(id: game.id))
        #expect(updated.homeScore == 6)
        #expect(updated.awayScore == 2)
        #expect(try games.inningScores(gameId: game.id).count == 14)
    }

    @Test("入れ直すと古いイニングは消える")
    func replacingInningScoresClearsOld() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        try games.replaceInningScores(gameId: game.id, home: [1, 1, 1], away: [0, 0, 0])
        try games.replaceInningScores(gameId: game.id, home: [5], away: [2])

        let updated = try #require(try games.game(id: game.id))
        #expect(updated.homeScore == 5)
        #expect(updated.awayScore == 2)
        #expect(try games.inningScores(gameId: game.id).count == 2)
    }

    @Test("イニング別が無い試合は合計スコアをそのまま保つ")
    func gamesWithoutInningsKeepTotals() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(
            date: Date(), myTeamId: team.id, awayTeamName: "相手",
            homeScore: 7, awayScore: 3
        )

        #expect(try games.inningScores(gameId: game.id).isEmpty)
        #expect(game.homeScore == 7)
        #expect(game.awayScore == 3)
    }

    @Test("試合を削除するとイニング別得点も消える")
    func deletingGameRemovesInningScores() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let target = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let other = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "別")

        try games.replaceInningScores(gameId: target.id, home: [1], away: [0])
        try games.replaceInningScores(gameId: other.id, home: [2], away: [1])

        try games.deleteGame(id: target.id)

        #expect(try games.inningScores(gameId: target.id).isEmpty)
        #expect(try games.inningScores(gameId: other.id).count == 2)
    }

    @Test("負の得点は弾かれる")
    func negativeInningScoreThrows() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        #expect(throws: AppError.self) {
            try games.replaceInningScores(gameId: game.id, home: [1, -1], away: [0, 0])
        }
    }

    @Test("打席記録を更新できる")
    func updatePlateAppearance() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let record = try games.addPlateAppearance(
            gameId: game.id, batterName: "田中", resultType: .out, resultDetail: .k, inning: 1, rbi: 0
        )

        try games.updatePlateAppearance(
            id: record.id, batterName: "  佐藤  ", resultType: .hit,
            resultDetail: .hr, inning: 5, rbi: 3
        )

        let updated = try #require(try games.plateAppearances().first)
        #expect(updated.id == record.id)
        #expect(updated.batterName == "佐藤")
        #expect(updated.resultType == .hit)
        #expect(updated.resultDetail == .hr)
        #expect(updated.inning == 5)
        #expect(updated.rbi == 3)
        #expect(try games.plateAppearances().count == 1)
    }

    @Test("投球記録を更新できる")
    func updatePitchingAppearance() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let record = try games.addPitchingAppearance(
            gameId: game.id, pitcherName: "山本", outsPitched: 3,
            runs: 0, earnedRuns: 0, hitsAllowed: 0, walks: 0, strikeouts: 1, homeRunsAllowed: 0
        )

        try games.updatePitchingAppearance(
            id: record.id, pitcherName: "中村", outsPitched: 21,
            runs: 3, earnedRuns: 2, hitsAllowed: 6, walks: 2, strikeouts: 8, homeRunsAllowed: 1
        )

        let updated = try #require(try games.pitchingAppearances().first)
        #expect(updated.pitcherName == "中村")
        #expect(updated.outsPitched == 21)
        #expect(updated.earnedRuns == 2)
        #expect(try games.pitchingAppearances().count == 1)
    }

    @Test("更新でも入力チェックは効く")
    func updateValidatesInput() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let record = try games.addPlateAppearance(
            gameId: game.id, batterName: "田中", resultType: .hit, resultDetail: .single
        )

        #expect(throws: AppError.self) {
            try games.updatePlateAppearance(
                id: record.id, batterName: "   ", resultType: .hit,
                resultDetail: .single, inning: 1, rbi: 0
            )
        }
        #expect(throws: AppError.self) {
            try games.updatePlateAppearance(
                id: record.id, batterName: "田中", resultType: .hit,
                resultDetail: .single, inning: 0, rbi: 0
            )
        }
    }

    @Test("存在しない記録の更新は失敗する")
    func updateUnknownRecordThrows() throws {
        let (games, _) = try makeRepositories()

        #expect(throws: AppError.self) {
            try games.updatePlateAppearance(
                id: "not-exist", batterName: "田中", resultType: .hit,
                resultDetail: .single, inning: 1, rbi: 0
            )
        }
    }

    @Test("試合を削除すると紐づく打席・投球記録も消える")
    func deleteGameRemovesChildRecords() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let target = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let other = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "別")

        _ = try games.addPlateAppearance(
            gameId: target.id, batterName: "田中", resultType: .hit, resultDetail: .single
        )
        _ = try games.addPitchingAppearance(
            gameId: target.id, pitcherName: "山本", outsPitched: 3,
            runs: 0, earnedRuns: 0, hitsAllowed: 0, walks: 0, strikeouts: 1, homeRunsAllowed: 0
        )
        // 別試合の記録は巻き添えで消えてはいけない。
        _ = try games.addPlateAppearance(
            gameId: other.id, batterName: "佐藤", resultType: .out, resultDetail: .k
        )

        try games.deleteGame(id: target.id)

        #expect(try games.games().map(\.id) == [other.id])
        #expect(try games.plateAppearances().allSatisfy { $0.gameId == other.id })
        #expect(try games.pitchingAppearances().isEmpty)
    }

    @Test("打席記録だけを削除しても試合は残る")
    func deletePlateAppearanceKeepsGame() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let first = try games.addPlateAppearance(
            gameId: game.id, batterName: "田中", resultType: .hit, resultDetail: .single
        )
        _ = try games.addPlateAppearance(
            gameId: game.id, batterName: "佐藤", resultType: .out, resultDetail: .k
        )

        try games.deletePlateAppearance(id: first.id)

        #expect(try games.plateAppearances().count == 1)
        #expect(try games.games().count == 1)
    }

    @Test("投球記録だけを削除しても試合は残る")
    func deletePitchingAppearanceKeepsGame() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")
        let pitching = try games.addPitchingAppearance(
            gameId: game.id, pitcherName: "山本", outsPitched: 9,
            runs: 1, earnedRuns: 1, hitsAllowed: 3, walks: 1, strikeouts: 5, homeRunsAllowed: 0
        )

        try games.deletePitchingAppearance(id: pitching.id)

        #expect(try games.pitchingAppearances().isEmpty)
        #expect(try games.games().count == 1)
    }

    @Test("存在しない ID の削除は何も壊さない")
    func deletingUnknownIdIsNoOp() throws {
        let (games, teams) = try makeRepositories()
        let team = try teams.createMyTeam(name: "A")
        _ = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        try games.deleteGame(id: "not-exist")
        try games.deletePlateAppearance(id: "not-exist")
        try games.deletePitchingAppearance(id: "not-exist")

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

@Suite("既存試合の互換性")
@MainActor
struct LegacyGameCompatibilityTests {
    /// イニング別を持たない試合を updateGame で保存しても、
    /// 合計スコアが 0 に潰れないこと。CreateGameView の hasInningScores
    /// ガードが外れると壊れる経路。
    @Test("合計スコアだけの試合は編集保存しても得点が残る")
    func updatingLegacyGameKeepsScore() throws {
        let context = try makeContext()
        let games = GameRepository(context: context)
        let teams = MyTeamRepository(context: context)
        let team = try teams.createMyTeam(name: "A")

        let game = try games.createGame(
            date: Date(), myTeamId: team.id, awayTeamName: "相手",
            homeScore: 7, awayScore: 3
        )

        // 画面が渡すのは「既存の合計」であって 0 ではない。
        _ = try games.updateGame(
            gameId: game.id,
            date: game.date,
            myTeamId: team.id,
            awayTeamName: "相手",
            innings: 7,
            homeScore: game.homeScore ?? 0,
            awayScore: game.awayScore ?? 0
        )

        let updated = try #require(try games.game(id: game.id))
        #expect(updated.homeScore == 7)
        #expect(updated.awayScore == 3)
        #expect(try games.inningScores(gameId: game.id).isEmpty)
    }

    @Test("0対0の試合でもイニング別は保存される")
    func scorelessGameStillStoresInnings() throws {
        let context = try makeContext()
        let games = GameRepository(context: context)
        let teams = MyTeamRepository(context: context)
        let team = try teams.createMyTeam(name: "A")
        let game = try games.createGame(date: Date(), myTeamId: team.id, awayTeamName: "相手")

        try games.replaceInningScores(gameId: game.id, home: [0, 0, 0], away: [0, 0, 0])

        // 合計が 0 でも「入力された」ことは残る。
        #expect(try games.inningScores(gameId: game.id).count == 6)
        let updated = try #require(try games.game(id: game.id))
        #expect(updated.homeScore == 0)
    }
}

@Suite("チームの編集・削除")
@MainActor
struct MyTeamEditingTests {
    @Test("チームを削除すると試合と記録も消える")
    func deletingTeamRemovesGamesAndRecords() throws {
        let context = try makeContext()
        let teams = MyTeamRepository(context: context)
        let players = PlayerRepository(context: context)
        let games = GameRepository(context: context)

        let target = try teams.createMyTeam(name: "A")
        let other = try teams.createMyTeam(name: "B")
        _ = try players.createPlayer(name: "田中", myTeamId: target.id)

        let game = try games.createGame(date: Date(), myTeamId: target.id, awayTeamName: "相手")
        _ = try games.addPlateAppearance(
            gameId: game.id, batterName: "田中", resultType: .hit, resultDetail: .single
        )
        try games.replaceInningScores(gameId: game.id, home: [1], away: [0])

        // 別チームの試合は巻き添えにしない。
        let keptGame = try games.createGame(date: Date(), myTeamId: other.id, awayTeamName: "別")

        try teams.deleteMyTeam(id: target.id, gameRepository: games, playerRepository: players)

        #expect(try teams.myTeams().map(\.id) == [other.id])
        #expect(try games.games().map(\.id) == [keptGame.id])
        #expect(try games.plateAppearances().isEmpty)
        #expect(try games.inningScores(gameId: game.id).isEmpty)
        #expect(try players.players(myTeamId: target.id).isEmpty)
    }

    @Test("削除後は残ったチームがデフォルトになる")
    func deletingDefaultTeamPromotesAnother() throws {
        let context = try makeContext()
        let teams = MyTeamRepository(context: context)
        let players = PlayerRepository(context: context)
        let games = GameRepository(context: context)

        let first = try teams.createMyTeam(name: "A")
        let second = try teams.createMyTeam(name: "B")
        #expect(first.isDefault)

        try teams.deleteMyTeam(id: first.id, gameRepository: games, playerRepository: players)

        // デフォルトが居なくなると試合作成で自チームを選べなくなる。
        #expect(try teams.defaultMyTeam()?.id == second.id)
    }

    @Test("チーム名を変更できる")
    func renamingTeam() throws {
        let teams = MyTeamRepository(context: try makeContext())
        let team = try teams.createMyTeam(name: "A")

        try teams.renameMyTeam(id: team.id, name: "  ホークス  ")

        #expect(try teams.myTeams().first?.name == "ホークス")
    }

    @Test("空の名前への変更は弾かれる")
    func renamingToBlankThrows() throws {
        let teams = MyTeamRepository(context: try makeContext())
        let team = try teams.createMyTeam(name: "A")

        #expect(throws: AppError.self) {
            try teams.renameMyTeam(id: team.id, name: "   ")
        }
    }
}
