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

    /// 掲載画像は言語ごとに差し替えるため、名前も表示言語に合わせる。
    /// UI 文言ではないので String Catalog には載せない。
    private static var isEnglish: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? false
    }

    static func seed(context: ModelContext) throws {
        try clearAll(context: context)

        let names = isEnglish ? DemoNames.english : DemoNames.japanese
        let team = MyTeam(name: names.myTeam, isDefault: true, displayOrder: 0)
        context.insert(team)

        let calendar = Calendar.current
        let today = Date()

        // カレンダーの初期選択日は当日。掲載画像でカードを見せるため当日に1試合置く。
        let plans: [GamePlan] = [
            .init(dayOffset: 0, opponent: names.opponents[0], home: 6, away: 2, venue: names.venues[0]),
            .init(dayOffset: -9, opponent: names.opponents[1], home: 3, away: 5, venue: names.venues[1]),
            .init(dayOffset: -16, opponent: names.opponents[2], home: 7, away: 4, venue: names.venues[2]),
            .init(dayOffset: -38, opponent: names.opponents[3], home: 5, away: 5, venue: names.venues[2]),
            .init(dayOffset: -45, opponent: names.opponents[4], home: 8, away: 1, venue: names.venues[3]),
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

            for (index, runs) in plan.homeInnings.enumerated() {
                context.insert(
                    InningScore(gameId: game.id, inning: index + 1, isHome: true, runs: runs)
                )
            }
            for (index, runs) in plan.awayInnings.enumerated() {
                context.insert(
                    InningScore(gameId: game.id, inning: index + 1, isHome: false, runs: runs)
                )
            }

            for pa in plan.plateAppearances(batters: names.batters) {
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

            for pitch in plan.pitchingAppearances(pitchers: names.pitchers) {
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

/// 架空の名前だけを使う（App Review Guideline 2.3.9）。
private struct DemoNames {
    let myTeam: String
    let opponents: [String]
    let venues: [String]
    let batters: [String]
    let pitchers: [String]

    static let japanese = DemoNames(
        myTeam: "イーストサイド",
        opponents: ["グリーンズ", "ブルーシャークス", "レッドウィングス", "ゴールデンベアーズ", "シルバーホークス"],
        venues: ["総合運動公園", "河川敷グラウンド", "市民球場", "東部球場"],
        batters: ["田中", "佐藤", "鈴木", "高橋"],
        pitchers: ["山本", "中村"]
    )

    static let english = DemoNames(
        myTeam: "East Side",
        opponents: ["Greens", "Blue Sharks", "Red Wings", "Golden Bears", "Silver Hawks"],
        venues: ["Riverside Park", "Northgate Field", "City Stadium", "East Park"],
        batters: ["Miller", "Carter", "Brooks", "Hayes"],
        pitchers: ["Reed", "Palmer"]
    )
}

private struct GamePlan {
    let dayOffset: Int
    let opponent: String
    let home: Int
    let away: Int
    let venue: String

    /// 合計が home / away に一致する 7 回分の配分。
    /// 序盤・中盤・終盤に散らしてラインスコアが単調にならないようにする。
    var homeInnings: [Int] { Self.distribute(home) }
    var awayInnings: [Int] { Self.distribute(away) }

    private static func distribute(_ total: Int) -> [Int] {
        var runs = [Int](repeating: 0, count: 7)
        // 得点する回を散らすため、1回ずつ間隔を空けて置いていく。
        var inning = 0
        var remaining = total
        while remaining > 0 {
            let scored = min(remaining, inning == 3 ? 2 : 1)
            runs[inning % 7] += scored
            remaining -= scored
            inning += 2
            if inning >= 7 { inning = (inning % 7) + 1 }
        }
        return runs
    }

    /// 打率が .300〜.400 台に収まるよう、安打と凡打を混ぜる。
    /// batters は [1番, 2番, 3番, 4番] の並び。
    func plateAppearances(batters: [String]) -> [PA] {
        switch dayOffset {
        case 0:
            [
                PA(batters[0], 1, .hit, .double, 2),
                PA(batters[0], 3, .out, .fly, 0),
                PA(batters[0], 6, .out, .ground, 0),
                PA(batters[1], 1, .hit, .hr, 3),
                PA(batters[1], 4, .out, .k, 0),
                PA(batters[2], 2, .walk, .bb, 0),
                PA(batters[2], 5, .hit, .single, 0),
                PA(batters[3], 3, .out, .fly, 0),
            ]
        case -9:
            [
                PA(batters[0], 2, .out, .ground, 0),
                PA(batters[0], 5, .hit, .single, 1),
                PA(batters[1], 2, .out, .k, 0),
                PA(batters[1], 7, .out, .line, 0),
                PA(batters[2], 3, .out, .fly, 0),
                PA(batters[2], 6, .hit, .double, 1),
                PA(batters[3], 4, .walk, .hbp, 0),
                PA(batters[3], 7, .out, .k, 0),
            ]
        case -16:
            [
                PA(batters[0], 1, .hit, .triple, 2),
                PA(batters[0], 4, .out, .dp, 0),
                PA(batters[1], 3, .hit, .single, 1),
                PA(batters[1], 6, .out, .fly, 0),
                PA(batters[2], 1, .out, .k, 0),
                PA(batters[2], 5, .hit, .double, 2),
                PA(batters[3], 2, .out, .sacFly, 1),
                PA(batters[3], 6, .out, .ground, 0),
            ]
        case -38:
            [
                PA(batters[0], 3, .hit, .single, 1),
                PA(batters[0], 6, .out, .k, 0),
                PA(batters[1], 2, .out, .ground, 0),
                PA(batters[1], 5, .hit, .hr, 2),
                PA(batters[2], 4, .out, .line, 0),
                PA(batters[3], 6, .out, .fly, 0),
            ]
        default:
            [
                PA(batters[0], 2, .hit, .double, 1),
                PA(batters[0], 6, .out, .fly, 0),
                PA(batters[1], 1, .hit, .single, 2),
                PA(batters[1], 5, .out, .ground, 0),
                PA(batters[2], 3, .out, .k, 0),
                PA(batters[2], 7, .out, .fly, 0),
                PA(batters[3], 4, .out, .sacBunt, 0),
            ]
        }
    }

    /// 防御率が 2.00〜4.00 に収まる配分。
    func pitchingAppearances(pitchers: [String]) -> [Pitch] {
        switch dayOffset {
        case 0:
            [Pitch(pitchers[0], outs: 21, runs: 2, earnedRuns: 2, hits: 5, walks: 1, strikeouts: 8, homeRuns: 0)]
        case -9:
            [
                Pitch(pitchers[0], outs: 15, runs: 4, earnedRuns: 3, hits: 7, walks: 2, strikeouts: 4, homeRuns: 1),
                Pitch(pitchers[1], outs: 6, runs: 1, earnedRuns: 1, hits: 2, walks: 0, strikeouts: 3, homeRuns: 0),
            ]
        case -16:
            [Pitch(pitchers[1], outs: 21, runs: 4, earnedRuns: 3, hits: 8, walks: 3, strikeouts: 6, homeRuns: 1)]
        case -38:
            [Pitch(pitchers[0], outs: 19, runs: 5, earnedRuns: 4, hits: 9, walks: 2, strikeouts: 5, homeRuns: 1)]
        default:
            [Pitch(pitchers[1], outs: 21, runs: 1, earnedRuns: 0, hits: 3, walks: 1, strikeouts: 9, homeRuns: 0)]
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
