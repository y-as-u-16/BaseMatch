import Foundation
import SwiftData

@Model
final class MyTeam {
    @Attribute(.unique) var id: String = ""
    var name: String = ""
    var colorKey: String?
    var isDefault: Bool = false
    var displayOrder: Int = 0
    var archivedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        name: String,
        colorKey: String? = nil,
        isDefault: Bool = false,
        displayOrder: Int = 0,
        archivedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorKey = colorKey
        self.isDefault = isDefault
        self.displayOrder = displayOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// チームに所属する選手。
/// 打席・投球記録とは `name` の一致で結び付く。既存の記録は名前だけを
/// 持っているため、ID 参照にすると移行が必要になる。
@Model
final class Player {
    @Attribute(.unique) var id: String = ""
    var name: String = ""
    var myTeamId: String = ""
    var isDefault: Bool = false
    var displayOrder: Int = 0
    var archivedAt: Date?
    var createdAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        name: String,
        myTeamId: String,
        isDefault: Bool = false,
        displayOrder: Int = 0,
        archivedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.myTeamId = myTeamId
        self.isDefault = isDefault
        self.displayOrder = displayOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
    }
}

/// 1イニング分の得点。既存モデルに揃えて `gameId` の手動外部キーで繋ぐ。
/// `isHome` は「後攻（裏）の枠」を指し、自チームかどうかは `Game.isMyTeamHome` と
/// 掛け合わせて決まる。
@Model
final class InningScore {
    @Attribute(.unique) var id: String = ""
    var gameId: String = ""
    var inning: Int = 1
    var isHome: Bool = true
    var runs: Int = 0

    init(
        id: String = UUID().uuidString,
        gameId: String,
        inning: Int,
        isHome: Bool,
        runs: Int
    ) {
        self.id = id
        self.gameId = gameId
        self.inning = inning
        self.isHome = isHome
        self.runs = runs
    }
}

@Model
final class Game {
    @Attribute(.unique) var id: String = ""
    var date: Date = Date()
    var location: String?
    var myTeamId: String = ""
    var awayTeamName: String = ""
    var homeScore: Int?
    var awayScore: Int?
    /// 記録中／確定という区別は廃止したが、既存ストアとの互換のため列は残す。
    var statusRaw: String = ""
    var createdAt: Date = Date()
    var innings: Int?
    /// 既定を true にしているのは、この項目が無かった頃の記録がすべて
    /// 自チーム＝後攻として保存されているため。
    var isMyTeamHome: Bool = true

    /// 自チームの得点。`homeScore` / `awayScore` は先攻・後攻の枠であって
    /// 自チームの枠ではないため、直接読むと先攻の試合で相手の点になる。
    var myTeamScore: Int? {
        isMyTeamHome ? homeScore : awayScore
    }

    var opponentScore: Int? {
        isMyTeamHome ? awayScore : homeScore
    }

    init(
        id: String = UUID().uuidString,
        date: Date,
        location: String? = nil,
        myTeamId: String,
        awayTeamName: String,
        homeScore: Int? = nil,
        awayScore: Int? = nil,
        createdAt: Date = Date(),
        innings: Int? = nil,
        isMyTeamHome: Bool = true
    ) {
        self.id = id
        self.date = date
        self.location = location
        self.myTeamId = myTeamId
        self.awayTeamName = awayTeamName
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.createdAt = createdAt
        self.innings = innings
        self.isMyTeamHome = isMyTeamHome
    }
}

@Model
final class PlateAppearance {
    @Attribute(.unique) var id: String = ""
    var gameId: String = ""
    var batterName: String = "自分"
    var inning: Int?
    var resultTypeRaw: String = PlateAppearanceResultType.out.rawValue
    var resultDetailRaw: String = PlateAppearanceResultDetail.other.rawValue
    var rbi: Int?
    var createdAt: Date = Date()

    var resultType: PlateAppearanceResultType {
        get { PlateAppearanceResultType(rawValue: resultTypeRaw) ?? .out }
        set { resultTypeRaw = newValue.rawValue }
    }

    var resultDetail: PlateAppearanceResultDetail {
        get { PlateAppearanceResultDetail(rawValue: resultDetailRaw) ?? .other }
        set { resultDetailRaw = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        gameId: String,
        batterName: String = "自分",
        inning: Int? = nil,
        resultType: PlateAppearanceResultType,
        resultDetail: PlateAppearanceResultDetail,
        rbi: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.gameId = gameId
        self.batterName = batterName
        self.inning = inning
        self.resultTypeRaw = resultType.rawValue
        self.resultDetailRaw = resultDetail.rawValue
        self.rbi = rbi
        self.createdAt = createdAt
    }
}

@Model
final class PitchingAppearance {
    @Attribute(.unique) var id: String = ""
    var gameId: String = ""
    var pitcherName: String = "自分"
    var outsPitched: Int = 0
    var runs: Int = 0
    var earnedRuns: Int = 0
    var hitsAllowed: Int = 0
    var walks: Int = 0
    var strikeouts: Int = 0
    var homeRunsAllowed: Int = 0
    var createdAt: Date = Date()

    init(
        id: String = UUID().uuidString,
        gameId: String,
        pitcherName: String = "自分",
        outsPitched: Int,
        runs: Int = 0,
        earnedRuns: Int = 0,
        hitsAllowed: Int = 0,
        walks: Int = 0,
        strikeouts: Int = 0,
        homeRunsAllowed: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.gameId = gameId
        self.pitcherName = pitcherName
        self.outsPitched = outsPitched
        self.runs = runs
        self.earnedRuns = earnedRuns
        self.hitsAllowed = hitsAllowed
        self.walks = walks
        self.strikeouts = strikeouts
        self.homeRunsAllowed = homeRunsAllowed
        self.createdAt = createdAt
    }
}
