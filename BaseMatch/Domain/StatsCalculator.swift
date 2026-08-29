import Foundation

/// 野球表記の率。1 未満は先頭の 0 を落とす（.333 / 1.000）。
func formatRate(_ numerator: Int, _ denominator: Int) -> String {
    guard denominator != 0 else { return ".000" }
    return formatRateValue(Double(numerator) / Double(denominator))
}

private func formatRateValue(_ rate: Double) -> String {
    let fixed = String(format: "%.3f", rate)
    return rate < 1 && fixed.hasPrefix("0") ? String(fixed.dropFirst()) : fixed
}

struct BattingStats: Equatable, Sendable {
    var pa = 0
    var ab = 0
    var hits = 0
    var doubles = 0
    var triples = 0
    var hr = 0
    var walks = 0
    var hbp = 0
    var sacFly = 0
    var so = 0

    static let empty = BattingStats()

    var singles: Int { hits - doubles - triples - hr }
    var totalBases: Int { singles + doubles * 2 + triples * 3 + hr * 4 }

    var averageLabel: String { formatRate(hits, ab) }

    var obpLabel: String { formatRate(hits + walks + hbp, obpDenominator) }

    var slgLabel: String { formatRate(totalBases, ab) }

    /// AB=0 でも OBP が計算できるなら OPS を出す（四球のみの打者を .000 にしない）。
    var opsLabel: String {
        guard obpDenominator != 0 else { return ".000" }
        let obp = Double(hits + walks + hbp) / Double(obpDenominator)
        let slg = ab == 0 ? 0 : Double(totalBases) / Double(ab)
        return formatRateValue(obp + slg)
    }

    private var obpDenominator: Int { ab + walks + hbp + sacFly }

    static func from(_ appearances: some Sequence<PlateAppearance>) -> Self {
        appearances.reduce(into: Self.empty) { $0.add($1) }
    }

    mutating func add(_ appearance: PlateAppearance) {
        let type = appearance.resultType
        let detail = appearance.resultDetail
        let isSacrifice = detail == .sacBunt || detail == .sacFly
        let isAtBat = !isSacrifice && [.hit, .out, .error].contains(type)

        pa += 1
        if isAtBat { ab += 1 }
        if type == .hit { hits += 1 }
        if detail == .double { doubles += 1 }
        if detail == .triple { triples += 1 }
        if detail == .hr { hr += 1 }
        if detail == .bb { walks += 1 }
        if detail == .hbp { hbp += 1 }
        if detail == .sacFly { sacFly += 1 }
        if detail == .k { so += 1 }
    }
}

struct PitchingStats: Equatable, Sendable {
    var games = 0
    var outsPitched = 0
    var earnedRuns = 0
    var hitsAllowed = 0
    var walks = 0
    var strikeouts = 0

    static let empty = PitchingStats()

    var inningsLabel: String { Self.inningsLabel(fromOuts: outsPitched) }

    /// 「3」「1.1」のような野球表記。
    static func inningsLabel(fromOuts outs: Int) -> String {
        let innings = outs / 3
        let rest = outs % 3
        return rest == 0 ? "\(innings)" : "\(innings).\(rest)"
    }

    var eraLabel: String {
        guard outsPitched != 0 else { return "-.--" }
        return String(format: "%.2f", Double(earnedRuns) * 27 / Double(outsPitched))
    }

    var whipLabel: String {
        guard outsPitched != 0 else { return "-.--" }
        return String(format: "%.2f", Double(walks + hitsAllowed) * 3 / Double(outsPitched))
    }

    static func from(_ appearances: some Sequence<PitchingAppearance>) -> Self {
        appearances.reduce(into: Self.empty) { $0.add($1) }
    }

    mutating func add(_ appearance: PitchingAppearance) {
        games += 1
        outsPitched += appearance.outsPitched
        earnedRuns += appearance.earnedRuns
        hitsAllowed += appearance.hitsAllowed
        walks += appearance.walks
        strikeouts += appearance.strikeouts
    }
}

struct NamedBattingStats: Identifiable, Equatable, Sendable {
    let playerName: String
    let stats: BattingStats

    var id: String { playerName }

    static func from(_ appearances: some Sequence<PlateAppearance>) -> [Self] {
        let grouped = Dictionary(grouping: appearances, by: \.batterName)
        return grouped
            .map { Self(playerName: $0.key, stats: BattingStats.from($0.value)) }
            .sorted {
                $0.stats.pa != $1.stats.pa
                    ? $0.stats.pa > $1.stats.pa
                    : $0.playerName < $1.playerName
            }
    }
}

struct NamedPitchingStats: Identifiable, Equatable, Sendable {
    let playerName: String
    let stats: PitchingStats

    var id: String { playerName }

    static func from(_ appearances: some Sequence<PitchingAppearance>) -> [Self] {
        let grouped = Dictionary(grouping: appearances, by: \.pitcherName)
        return grouped
            .map { Self(playerName: $0.key, stats: PitchingStats.from($0.value)) }
            .sorted {
                $0.stats.games != $1.stats.games
                    ? $0.stats.games > $1.stats.games
                    : $0.playerName < $1.playerName
            }
    }
}

enum StatsPeriod: Hashable, Sendable {
    case all
    case month(year: Int, month: Int)

    func contains(_ date: Date) -> Bool {
        switch self {
        case .all:
            return true
        case let .month(year, month):
            let components = Calendar.current.dateComponents([.year, .month], from: date)
            return components.year == year && components.month == month
        }
    }

    var isAll: Bool { self == .all }
}

/// 記録のある年月を新しい順に返す。
func availableMonths(_ games: some Sequence<Game>) -> [DateComponents] {
    let calendar = Calendar.current
    var seen = Set<DateComponents>()
    for game in games {
        let components = calendar.dateComponents([.year, .month], from: game.date)
        seen.insert(DateComponents(year: components.year, month: components.month))
    }
    return seen.sorted {
        ($0.year ?? 0, $0.month ?? 0) > ($1.year ?? 0, $1.month ?? 0)
    }
}

func eligibleGameIds(_ games: some Sequence<Game>, period: StatsPeriod) -> Set<String> {
    Set(games.filter { period.contains($0.date) }.map(\.id))
}

func filterPlateAppearances(
    _ appearances: some Sequence<PlateAppearance>,
    games: some Sequence<Game>,
    period: StatsPeriod
) -> [PlateAppearance] {
    guard !period.isAll else { return Array(appearances) }
    let ids = eligibleGameIds(games, period: period)
    return appearances.filter { ids.contains($0.gameId) }
}

func filterPitchingAppearances(
    _ appearances: some Sequence<PitchingAppearance>,
    games: some Sequence<Game>,
    period: StatsPeriod
) -> [PitchingAppearance] {
    guard !period.isAll else { return Array(appearances) }
    let ids = eligibleGameIds(games, period: period)
    return appearances.filter { ids.contains($0.gameId) }
}

/// 同じ描画内で打席・投球の両方を絞り込むとき、計算済みの ID 集合を使い回す。
func filterPlateAppearances(
    _ appearances: some Sequence<PlateAppearance>,
    eligibleGameIds ids: Set<String>,
    isAll: Bool
) -> [PlateAppearance] {
    isAll ? Array(appearances) : appearances.filter { ids.contains($0.gameId) }
}

func filterPitchingAppearances(
    _ appearances: some Sequence<PitchingAppearance>,
    eligibleGameIds ids: Set<String>,
    isAll: Bool
) -> [PitchingAppearance] {
    isAll ? Array(appearances) : appearances.filter { ids.contains($0.gameId) }
}

/// 成績画面が表示する、期間で絞り込んだ選手別成績。
struct PeriodStats: Equatable, Sendable {
    let batting: [NamedBattingStats]
    let pitching: [NamedPitchingStats]

    static let empty = PeriodStats(batting: [], pitching: [])
}

/// 期間で絞り込んでから選手別に集計する。打席と投球で試合 ID 集合を共有する。
func periodStats(
    games: [Game],
    plateAppearances: [PlateAppearance],
    pitchingAppearances: [PitchingAppearance],
    period: StatsPeriod
) -> PeriodStats {
    let isAll = period.isAll
    let ids = isAll ? [] : eligibleGameIds(games, period: period)

    return PeriodStats(
        batting: NamedBattingStats.from(
            filterPlateAppearances(plateAppearances, eligibleGameIds: ids, isAll: isAll)
        ),
        pitching: NamedPitchingStats.from(
            filterPitchingAppearances(pitchingAppearances, eligibleGameIds: ids, isAll: isAll)
        )
    )
}
