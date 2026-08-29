import Foundation
import SwiftData

/// App Store 掲載用スクリーンショットのためにデモデータを投入する。
/// 起動引数 `-seedDemoData` が渡されたときだけ動く開発用の仕組みで、
/// 通常起動では一切呼ばれない。
@MainActor
enum DemoDataSeeder {
    static var isRequested: Bool {
        CommandLine.arguments.contains("-seedDemoData")
    }

    static func seed(context: ModelContext) throws {
        try clearAll(context: context)

        let team = MyTeam(name: "イーストサイド", isDefault: true, displayOrder: 0)
        context.insert(team)

        let calendar = Calendar.current
        let today = Date()

        // 直近ほど画面に出るため、新しい試合から並べる
        let plans: [GamePlan] = [
            .init(dayOffset: -2, opponent: "グリーンズ", home: 6, away: 2, venue: "総合運動公園"),
            .init(dayOffset: -9, opponent: "ブルーシャークス", home: 3, away: 5, venue: "河川敷グラウンド"),
            .init(dayOffset: -16, opponent: "レッドウィングス", home: 7, away: 4, venue: "市民球場"),
            .init(dayOffset: -38, opponent: "ゴールデンベアーズ", home: 5, away: 5, venue: "市民球場"),
            .init(dayOffset: -45, opponent: "シルバーホークス", home: 8, away: 1, venue: "東部球場"),
        ]

        for plan in plans {
            let date = calendar.date(byAdding: .day, value: plan.dayOffset, to: today) ?? today
            let game = Game(
                date: calendar.startOfDay(for: date),
                location: plan.venue,
                myTeamId: team.id,
                awayTeamName: plan.opponent,
                homeScore: plan.home,
                awayScore: plan.away,
                status: .final_,
                createdAt: date,
                innings: 7
            )
            context.insert(game)

            for pa in plan.plateAppearances {
                context.insert(
                    PlateAppearance(
                        gameId: game.id,
                        batterName: pa.batter,
                        inning: pa.inning,
                        resultType: pa.type,
                        resultDetail: pa.detail,
                        rbi: pa.rbi,
                        createdAt: date
                    )
                )
            }

            for pitch in plan.pitchingAppearances {
                context.insert(
                    PitchingAppearance(
                        gameId: game.id,
                        pitcherName: pitch.pitcher,
                        outsPitched: pitch.outs,
                        runs: pitch.runs,
                        earnedRuns: pitch.earnedRuns,
                        hitsAllowed: pitch.hits,
                        walks: pitch.walks,
                        strikeouts: pitch.strikeouts,
                        homeRunsAllowed: pitch.homeRuns,
                        createdAt: date
                    )
                )
            }
        }

        try context.save()
    }

    private static func clearAll(context: ModelContext) throws {
        try context.delete(model: PlateAppearance.self)
        try context.delete(model: PitchingAppearance.self)
        try context.delete(model: Game.self)
        try context.delete(model: MyTeam.self)
        try context.save()
    }
}

private struct GamePlan {
    let dayOffset: Int
    let opponent: String
    let home: Int
    let away: Int
    let venue: String

    /// 打率が .300〜.400 台に収まるよう、安打と凡打を混ぜる。
    var plateAppearances: [PA] {
        switch dayOffset {
        case -2:
            [
                PA("田中", 1, .hit, .double, 2),
                PA("田中", 3, .out, .fly, 0),
                PA("田中", 6, .out, .ground, 0),
                PA("佐藤", 1, .hit, .hr, 3),
                PA("佐藤", 4, .out, .k, 0),
                PA("鈴木", 2, .walk, .bb, 0),
                PA("鈴木", 5, .hit, .single, 0),
                PA("高橋", 3, .out, .fly, 0),
            ]
        case -9:
            [
                PA("田中", 2, .out, .ground, 0),
                PA("田中", 5, .hit, .single, 1),
                PA("佐藤", 2, .out, .k, 0),
                PA("佐藤", 7, .out, .line, 0),
                PA("鈴木", 3, .out, .fly, 0),
                PA("鈴木", 6, .hit, .double, 1),
                PA("高橋", 4, .walk, .hbp, 0),
                PA("高橋", 7, .out, .k, 0),
            ]
        case -16:
            [
                PA("田中", 1, .hit, .triple, 2),
                PA("田中", 4, .out, .dp, 0),
                PA("佐藤", 3, .hit, .single, 1),
                PA("佐藤", 6, .out, .fly, 0),
                PA("鈴木", 1, .out, .k, 0),
                PA("鈴木", 5, .hit, .double, 2),
                PA("高橋", 2, .out, .sacFly, 1),
                PA("高橋", 6, .out, .ground, 0),
            ]
        case -38:
            [
                PA("田中", 3, .hit, .single, 1),
                PA("田中", 6, .out, .k, 0),
                PA("佐藤", 2, .out, .ground, 0),
                PA("佐藤", 5, .hit, .hr, 2),
                PA("鈴木", 4, .out, .line, 0),
                PA("高橋", 6, .out, .fly, 0),
            ]
        default:
            [
                PA("田中", 2, .hit, .double, 1),
                PA("田中", 6, .out, .fly, 0),
                PA("佐藤", 1, .hit, .single, 2),
                PA("佐藤", 5, .out, .ground, 0),
                PA("鈴木", 3, .out, .k, 0),
                PA("鈴木", 7, .out, .fly, 0),
                PA("高橋", 4, .out, .sacBunt, 0),
            ]
        }
    }

    /// 防御率が 2.00〜4.00 に収まる配分。
    var pitchingAppearances: [Pitch] {
        switch dayOffset {
        case -2:
            [Pitch("山本", outs: 21, runs: 2, earnedRuns: 2, hits: 5, walks: 1, strikeouts: 8, homeRuns: 0)]
        case -9:
            [
                Pitch("山本", outs: 15, runs: 4, earnedRuns: 3, hits: 7, walks: 2, strikeouts: 4, homeRuns: 1),
                Pitch("中村", outs: 6, runs: 1, earnedRuns: 1, hits: 2, walks: 0, strikeouts: 3, homeRuns: 0),
            ]
        case -16:
            [Pitch("中村", outs: 21, runs: 4, earnedRuns: 3, hits: 8, walks: 3, strikeouts: 6, homeRuns: 1)]
        case -38:
            [Pitch("山本", outs: 19, runs: 5, earnedRuns: 4, hits: 9, walks: 2, strikeouts: 5, homeRuns: 1)]
        default:
            [Pitch("中村", outs: 21, runs: 1, earnedRuns: 0, hits: 3, walks: 1, strikeouts: 9, homeRuns: 0)]
        }
    }
}

private struct PA {
    let batter: String
    let inning: Int
    let type: PlateAppearanceResultType
    let detail: PlateAppearanceResultDetail
    let rbi: Int

    init(
        _ batter: String,
        _ inning: Int,
        _ type: PlateAppearanceResultType,
        _ detail: PlateAppearanceResultDetail,
        _ rbi: Int
    ) {
        self.batter = batter
        self.inning = inning
        self.type = type
        self.detail = detail
        self.rbi = rbi
    }
}

private struct Pitch {
    let pitcher: String
    let outs: Int
    let runs: Int
    let earnedRuns: Int
    let hits: Int
    let walks: Int
    let strikeouts: Int
    let homeRuns: Int

    init(
        _ pitcher: String,
        outs: Int,
        runs: Int,
        earnedRuns: Int,
        hits: Int,
        walks: Int,
        strikeouts: Int,
        homeRuns: Int
    ) {
        self.pitcher = pitcher
        self.outs = outs
        self.runs = runs
        self.earnedRuns = earnedRuns
        self.hits = hits
        self.walks = walks
        self.strikeouts = strikeouts
        self.homeRuns = homeRuns
    }
}
