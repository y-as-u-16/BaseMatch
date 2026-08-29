import Foundation
import Testing

@testable import BaseMatch

private func plate(
    id: String,
    batterName: String = "自分",
    gameId: String = "game-1",
    type: PlateAppearanceResultType,
    detail: PlateAppearanceResultDetail
) -> PlateAppearance {
    PlateAppearance(
        id: id,
        gameId: gameId,
        batterName: batterName,
        resultType: type,
        resultDetail: detail,
        createdAt: Date(timeIntervalSince1970: 0)
    )
}

private func pitching(
    id: String,
    pitcherName: String = "自分",
    gameId: String = "game-1",
    outsPitched: Int,
    earnedRuns: Int = 0,
    hitsAllowed: Int = 0,
    walks: Int = 0,
    strikeouts: Int = 0
) -> PitchingAppearance {
    PitchingAppearance(
        id: id,
        gameId: gameId,
        pitcherName: pitcherName,
        outsPitched: outsPitched,
        runs: earnedRuns,
        earnedRuns: earnedRuns,
        hitsAllowed: hitsAllowed,
        walks: walks,
        strikeouts: strikeouts,
        homeRunsAllowed: 0,
        createdAt: Date(timeIntervalSince1970: 0)
    )
}

private func makeGame(id: String, year: Int, month: Int, day: Int) -> Game {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    let date = Calendar.current.date(from: components)!
    return Game(
        id: id,
        date: date,
        myTeamId: "team-1",
        awayTeamName: "Away",
        status: .final_,
        createdAt: date
    )
}

@Suite("BattingStats")
@MainActor
struct BattingStatsTests {
    @Test("打席リストが空の場合は打撃成績をゼロで返す")
    func emptyAppearances() {
        let stats = BattingStats.from([PlateAppearance]())

        #expect(stats.pa == 0)
        #expect(stats.ab == 0)
        #expect(stats.hits == 0)
        #expect(stats.hr == 0)
        #expect(stats.walks == 0)
        #expect(stats.so == 0)
        #expect(stats.averageLabel == ".000")
    }

    @Test("安打、凡打、失策は打数に含め、四球は除外する")
    func atBatCounting() {
        let stats = BattingStats.from([
            plate(id: "pa-1", type: .hit, detail: .single),
            plate(id: "pa-2", type: .out, detail: .k),
            plate(id: "pa-3", type: .walk, detail: .bb),
            plate(id: "pa-4", type: .error, detail: .e),
        ])

        #expect(stats.pa == 4)
        #expect(stats.ab == 3)
        #expect(stats.hits == 1)
        #expect(stats.walks == 1)
        #expect(stats.so == 1)
        #expect(stats.averageLabel == ".333")
    }

    @Test("本塁打を集計し、打率 1.000 を表示する")
    func homeRunAverage() {
        let stats = BattingStats.from([
            plate(id: "pa-1", type: .hit, detail: .hr),
            plate(id: "pa-2", type: .hit, detail: .double),
        ])

        #expect(stats.pa == 2)
        #expect(stats.ab == 2)
        #expect(stats.hits == 2)
        #expect(stats.hr == 1)
        #expect(stats.averageLabel == "1.000")
    }

    @Test("犠打・犠飛は打数に含めない")
    func sacrificesExcludedFromAtBats() {
        let stats = BattingStats.from([
            plate(id: "pa-1", type: .hit, detail: .single),
            plate(id: "pa-2", type: .out, detail: .sacFly),
            plate(id: "pa-3", type: .out, detail: .sacBunt),
        ])

        #expect(stats.pa == 3)
        #expect(stats.ab == 1)
        #expect(stats.sacFly == 1)
        #expect(stats.averageLabel == "1.000")
    }

    @Test("死球は四球と区別し、出塁率に反映される")
    func hitByPitchSeparateFromWalk() {
        let stats = BattingStats.from([
            plate(id: "pa-1", type: .out, detail: .k),
            plate(id: "pa-2", type: .walk, detail: .hbp),
        ])

        #expect(stats.walks == 0)
        #expect(stats.hbp == 1)
        #expect(stats.obpLabel == ".500")
    }

    @Test("四球のみの打者でも OPS は OBP+SLG として計算される（AB=0 でも .000 にしない）")
    func opsWithZeroAtBats() {
        let stats = BattingStats.from([
            plate(id: "pa-1", type: .walk, detail: .bb),
            plate(id: "pa-2", type: .walk, detail: .bb),
        ])

        #expect(stats.ab == 0)
        #expect(stats.walks == 2)
        #expect(stats.obpLabel == "1.000")
        #expect(stats.slgLabel == ".000")
        #expect(stats.opsLabel == "1.000")
    }

    @Test("OPS は出塁率と長打率の合計")
    func opsIsObpPlusSlg() {
        let stats = BattingStats.from([
            plate(id: "pa-1", type: .hit, detail: .single),
            plate(id: "pa-2", type: .hit, detail: .double),
            plate(id: "pa-3", type: .out, detail: .k),
            plate(id: "pa-4", type: .walk, detail: .bb),
        ])

        #expect(stats.ab == 3)
        #expect(stats.doubles == 1)
        #expect(stats.obpLabel == ".750")
        #expect(stats.slgLabel == "1.000")
        #expect(stats.opsLabel == "1.750")
    }

    @Test("打者名ごとに個人別打撃成績を分ける")
    func groupedByBatterName() {
        let rows = NamedBattingStats.from([
            plate(id: "pa-1", batterName: "佐藤", type: .hit, detail: .single),
            plate(id: "pa-2", batterName: "田中", type: .out, detail: .k),
            plate(id: "pa-3", batterName: "佐藤", type: .walk, detail: .bb),
        ])

        #expect(rows.map(\.playerName) == ["佐藤", "田中"])
        #expect(rows.first?.stats.pa == 2)
        #expect(rows.first?.stats.hits == 1)
        #expect(rows.last?.stats.pa == 1)
        #expect(rows.last?.stats.so == 1)
    }
}

@Suite("StatsPeriod / フィルタ")
@MainActor
struct StatsPeriodTests {
    @Test("availableMonths は記録のある月を新しい順に返す")
    func availableMonthsSorted() {
        let mayGame = makeGame(id: "g-may", year: 2026, month: 5, day: 10)
        let juneGame = makeGame(id: "g-june", year: 2026, month: 6, day: 1)

        let months = availableMonths([mayGame, juneGame])

        #expect(months.count == 2)
        #expect(months[0].year == 2026 && months[0].month == 6)
        #expect(months[1].year == 2026 && months[1].month == 5)
    }

    @Test("全期間は appearance を絞り込まない")
    func allPeriodKeepsEverything() {
        let mayGame = makeGame(id: "g-may", year: 2026, month: 5, day: 10)
        let juneGame = makeGame(id: "g-june", year: 2026, month: 6, day: 1)
        let mayPlate = plate(id: "pa-may", gameId: "g-may", type: .hit, detail: .single)
        let junePlate = plate(id: "pa-june", gameId: "g-june", type: .hit, detail: .hr)

        let result = filterPlateAppearances(
            [mayPlate, junePlate],
            games: [mayGame, juneGame],
            period: .all
        )

        #expect(result.count == 2)
    }

    @Test("月指定で対象月の試合の appearance のみ返す")
    func monthPeriodFiltersPlateAppearances() {
        let mayGame = makeGame(id: "g-may", year: 2026, month: 5, day: 10)
        let juneGame = makeGame(id: "g-june", year: 2026, month: 6, day: 1)
        let mayPlate = plate(id: "pa-may", gameId: "g-may", type: .hit, detail: .single)
        let junePlate = plate(id: "pa-june", gameId: "g-june", type: .hit, detail: .hr)

        let result = filterPlateAppearances(
            [mayPlate, junePlate],
            games: [mayGame, juneGame],
            period: .month(year: 2026, month: 6)
        )

        #expect(result.count == 1)
        #expect(result.first?.id == "pa-june")
    }

    @Test("投球も同じく月で絞り込める")
    func monthPeriodFiltersPitchingAppearances() {
        let mayGame = makeGame(id: "g-may", year: 2026, month: 5, day: 10)
        let juneGame = makeGame(id: "g-june", year: 2026, month: 6, day: 1)
        let mayPitch = pitching(id: "pit-may", gameId: "g-may", outsPitched: 3)
        let junePitch = pitching(id: "pit-june", gameId: "g-june", outsPitched: 6)

        let result = filterPitchingAppearances(
            [mayPitch, junePitch],
            games: [mayGame, juneGame],
            period: .month(year: 2026, month: 5)
        )

        #expect(result.count == 1)
        #expect(result.first?.id == "pit-may")
    }
}

@Suite("PitchingStats")
@MainActor
struct PitchingStatsTests {
    @Test("登板リストが空の場合は投球成績をゼロで返す")
    func emptyAppearances() {
        let stats = PitchingStats.from([PitchingAppearance]())

        #expect(stats.games == 0)
        #expect(stats.outsPitched == 0)
        #expect(stats.earnedRuns == 0)
        #expect(stats.strikeouts == 0)
        #expect(stats.inningsLabel == "0")
        #expect(stats.eraLabel == "-.--")
    }

    @Test("投球回、自責点、奪三振、防御率を集計する")
    func aggregatesEra() {
        let stats = PitchingStats.from([
            pitching(id: "pit-1", outsPitched: 4, earnedRuns: 1, strikeouts: 2),
            pitching(id: "pit-2", outsPitched: 5, earnedRuns: 2, strikeouts: 4),
        ])

        #expect(stats.games == 2)
        #expect(stats.outsPitched == 9)
        #expect(stats.earnedRuns == 3)
        #expect(stats.strikeouts == 6)
        #expect(stats.inningsLabel == "3")
        #expect(stats.eraLabel == "9.00")
    }

    @Test("端数の投球回を野球表記で表示する")
    func fractionalInnings() {
        let stats = PitchingStats.from([pitching(id: "pit-1", outsPitched: 4)])

        #expect(stats.inningsLabel == "1.1")
    }

    @Test("被安打・与四球から WHIP を計算する")
    func whipCalculation() {
        let stats = PitchingStats.from([
            pitching(id: "pit-1", outsPitched: 9, hitsAllowed: 4, walks: 2)
        ])

        #expect(stats.outsPitched == 9)
        #expect(stats.hitsAllowed == 4)
        #expect(stats.walks == 2)
        #expect(stats.whipLabel == "2.00")
    }

    @Test("投球記録なしのとき WHIP は -.--")
    func whipWithoutRecords() {
        #expect(PitchingStats.empty.whipLabel == "-.--")
    }

    @Test("投手名ごとに個人別投球成績を分ける")
    func groupedByPitcherName() {
        let rows = NamedPitchingStats.from([
            pitching(id: "pit-1", pitcherName: "佐藤", outsPitched: 3, earnedRuns: 1, strikeouts: 2),
            pitching(id: "pit-2", pitcherName: "田中", outsPitched: 6, earnedRuns: 0, strikeouts: 3),
            pitching(id: "pit-3", pitcherName: "佐藤", outsPitched: 3, earnedRuns: 1, strikeouts: 1),
        ])

        #expect(rows.map(\.playerName) == ["佐藤", "田中"])
        #expect(rows.first?.stats.games == 2)
        #expect(rows.first?.stats.earnedRuns == 2)
        #expect(rows.last?.stats.games == 1)
        #expect(rows.last?.stats.strikeouts == 3)
    }
}

@Suite("periodStats")
@MainActor
struct PeriodStatsTests {
    private let mayGame = makeGame(id: "g-may", year: 2026, month: 5, day: 10)
    private let juneGame = makeGame(id: "g-june", year: 2026, month: 6, day: 1)

    private var plates: [PlateAppearance] {
        [
            plate(id: "pa-may", batterName: "佐藤", gameId: "g-may", type: .hit, detail: .single),
            plate(id: "pa-june", batterName: "田中", gameId: "g-june", type: .out, detail: .k),
        ]
    }

    private var pitches: [PitchingAppearance] {
        [
            pitching(id: "pit-may", pitcherName: "佐藤", gameId: "g-may", outsPitched: 3),
            pitching(id: "pit-june", pitcherName: "田中", gameId: "g-june", outsPitched: 6),
        ]
    }

    @Test("全期間はすべての選手を集計する")
    func allPeriodIncludesEveryone() {
        let stats = periodStats(
            games: [mayGame, juneGame],
            plateAppearances: plates,
            pitchingAppearances: pitches,
            period: .all
        )

        #expect(stats.batting.map(\.playerName).sorted() == ["佐藤", "田中"])
        #expect(stats.pitching.map(\.playerName).sorted() == ["佐藤", "田中"])
    }

    @Test("月指定は打席と投球の両方を同じ期間で絞り込む")
    func monthPeriodFiltersBothSides() {
        let stats = periodStats(
            games: [mayGame, juneGame],
            plateAppearances: plates,
            pitchingAppearances: pitches,
            period: .month(year: 2026, month: 5)
        )

        #expect(stats.batting.map(\.playerName) == ["佐藤"])
        #expect(stats.batting.first?.stats.hits == 1)
        #expect(stats.pitching.map(\.playerName) == ["佐藤"])
        #expect(stats.pitching.first?.stats.outsPitched == 3)
    }

    @Test("記録のない月は空を返す")
    func emptyForMonthWithoutRecords() {
        let stats = periodStats(
            games: [mayGame, juneGame],
            plateAppearances: plates,
            pitchingAppearances: pitches,
            period: .month(year: 2026, month: 7)
        )

        #expect(stats == .empty)
    }
}
