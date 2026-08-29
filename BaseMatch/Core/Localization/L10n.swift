import Foundation

/// 年は桁区切りを付けたくないため、ロケール依存の数値整形を避けて文字列で渡す。
private func plainNumber(_ value: Int) -> String { String(value) }

private func t(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .main)
}

/// UI 文言。原文は日本語で、訳は Localizable.xcstrings が持つ。
enum L10n {
    static var appTitle: String { t("app.title") }

    static var navHome: String { t("nav.home") }
    static var navRecord: String { t("nav.record") }
    static var navStats: String { t("nav.stats") }

    // Home
    static var homeHeadline: String { t("home.headline") }
    static var homeDescription: String { t("home.description") }
    static var seasonSummaryTitle: String { t("home.seasonSummary.title") }
    static var seasonGamesMetricLabel: String { t("home.metric.games") }
    static var seasonRecordMetricLabel: String { t("home.metric.record") }
    static var seasonRunsMetricLabel: String { t("home.metric.runs") }
    static var seasonAverageMetricLabel: String { t("home.metric.average") }
    static var seasonEraMetricLabel: String { t("home.metric.era") }
    static var recordGameButton: String { t("home.button.recordGame") }
    static var viewStatsButton: String { t("home.button.viewStats") }
    static var recentGamesTitle: String { t("home.recentGames.title") }
    static var homeEmptyGames: String { t("home.empty.games") }

    static func seasonSummarySubtitle(_ year: Int) -> String {
        t("home.seasonSummary.subtitle \(plainNumber(year))")
    }
    static func seasonGamesCount(_ count: Int) -> String {
        t("home.metric.gamesCount \(count)")
    }
    static func seasonRecordLabel(_ wins: Int, _ losses: Int, _ draws: Int) -> String {
        t("home.metric.recordValue \(wins) \(losses) \(draws)")
    }
    static func seasonRunsLabel(_ runs: Int) -> String {
        t("home.metric.runsValue \(runs)")
    }

    // Record / calendar
    static var recordTitle: String { t("record.title") }
    static var addGameButton: String { t("record.addGame") }
    static var selectedDateGamesTitle: String { t("record.selectedDateGames") }
    static var noGamesOnSelectedDate: String { t("record.noGamesOnDate") }
    static var previousMonthTooltip: String { t("record.previousMonth") }
    static var nextMonthTooltip: String { t("record.nextMonth") }

    // Create / edit game
    static var createGameTitle: String { t("game.create.title") }
    static var editGameTitle: String { t("game.edit.title") }
    static var gameDateLabel: String { t("game.field.date") }
    static var awayTeamNameLabel: String { t("game.field.awayTeamName") }
    static var awayTeamNameRequired: String { t("game.validation.awayTeamNameRequired") }
    static var homeScoreLabel: String { t("game.field.homeScore") }
    static var awayScoreLabel: String { t("game.field.awayScore") }
    static var scoreRequired: String { t("game.validation.scoreRequired") }
    static var scoreMustBeNonNegative: String { t("game.validation.scoreNonNegative") }
    static var locationOptionalLabel: String { t("game.field.locationOptional") }
    static var inningsCountLabel: String { t("game.field.inningsCount") }
    static var createButton: String { t("common.create") }
    static var saveChangesButton: String { t("common.saveChanges") }
    static var gameUpdatedMessage: String { t("game.updatedMessage") }

    // Game detail
    static var gameDetailTitle: String { t("game.detail.title") }
    static var gameNotFound: String { t("game.notFound") }
    static var addPlateAppearanceButton: String { t("game.detail.addPlateAppearance") }
    static var addPitchingButton: String { t("game.detail.addPitching") }
    static var plateAppearanceRecordsTitle: String { t("game.detail.plateAppearances") }
    static var emptyPlateAppearances: String { t("game.detail.emptyPlateAppearances") }
    static var pitchingRecordsTitle: String { t("game.detail.pitchingRecords") }
    static var emptyPitchingAppearances: String { t("game.detail.emptyPitching") }

    static func plateAppearanceListSubtitle(_ inning: String, _ rbi: Int) -> String {
        t("game.detail.paSubtitle \(inning) \(rbi)")
    }
    static func pitchingOutsTitle(_ innings: String) -> String {
        t("game.detail.pitchingOuts \(innings)")
    }
    static func pitchingListSubtitle(_ runs: Int, _ earnedRuns: Int, _ strikeouts: Int) -> String {
        t("game.detail.pitchingSubtitle \(runs) \(earnedRuns) \(strikeouts)")
    }

    // Plate appearance input
    static var plateAppearanceInputTitle: String { t("pa.input.title") }
    static var selectPlateAppearanceResultMessage: String { t("pa.selectResultMessage") }
    static var notSelectedLabel: String { t("common.notSelected") }
    static var playerNameRequired: String { t("validation.playerNameRequired") }
    static var batterNameLabel: String { t("pa.field.batterName") }
    static var inningLabel: String { t("pa.field.inning") }
    static var rbiLabel: String { t("pa.field.rbi") }
    static var hitSectionTitle: String { t("pa.section.hit") }
    static var outSectionTitle: String { t("pa.section.out") }
    static var onBaseSectionTitle: String { t("pa.section.onBase") }
    static var saveButton: String { t("common.save") }

    static func plateAppearanceSummary(_ inning: Int, _ result: String, _ rbi: Int) -> String {
        t("pa.summary \(inning) \(result) \(rbi)")
    }

    // Pitching input
    static var pitchingInputTitle: String { t("pitching.input.title") }
    static var pitcherNameLabel: String { t("pitching.field.pitcherName") }
    static var runsLabel: String { t("pitching.field.runs") }
    static var earnedRunsLabel: String { t("pitching.field.earnedRuns") }
    static var hitsAllowedLabel: String { t("pitching.field.hitsAllowed") }
    static var walksAllowedLabel: String { t("pitching.field.walksAllowed") }
    static var strikeoutsLabel: String { t("pitching.field.strikeouts") }
    static var homeRunsAllowedLabel: String { t("pitching.field.homeRunsAllowed") }
    static var pitchingInningsLabel: String { t("pitching.field.innings") }
    static var addOneThirdInningButton: String { t("pitching.button.addOneThird") }
    static var addOneInningButton: String { t("pitching.button.addOneInning") }
    static var resetOneInningButton: String { t("pitching.button.resetOneInning") }

    static func pitchingInputSummary(_ innings: String, _ runs: Int, _ earnedRuns: Int) -> String {
        t("pitching.input.summary \(innings) \(runs) \(earnedRuns)")
    }
    static func outsLabel(_ outs: Int) -> String { t("pitching.outsLabel \(outs)") }

    // Stats
    static var statsTitle: String { t("stats.title") }
    static var statsPeriodAll: String { t("stats.period.all") }
    static var statsPeriodMonthPlaceholder: String { t("stats.period.monthPlaceholder") }
    static var statsEmptyTitle: String { t("stats.empty.title") }
    static var statsEmptyMessage: String { t("stats.empty.message") }
    static var statsEmptyCta: String { t("stats.empty.cta") }
    static var battingStatsTitle: String { t("stats.batting.title") }
    static var pitchingStatsTitle: String { t("stats.pitching.title") }
    static var noBattingStatsLabel: String { t("stats.batting.none") }
    static var noPitchingStatsLabel: String { t("stats.pitching.none") }
    static var reloadButton: String { t("common.reload") }

    static func statsPeriodMonth(_ year: Int, _ month: Int) -> String {
        t("stats.period.month \(plainNumber(year)) \(month)")
    }
    static func battingStatsSummary(_ hits: Int, _ hr: Int, _ ops: String) -> String {
        t("stats.batting.summary \(hits) \(hr) \(ops)")
    }
    static func pitchingStatsSummary(_ strikeouts: Int, _ whip: String, _ games: Int) -> String {
        t("stats.pitching.summary \(strikeouts) \(whip) \(games)")
    }

    // My team
    static var addMyTeamButton: String { t("myTeam.addButton") }
    static var addMyTeamTitle: String { t("myTeam.addTitle") }
    static var myTeamNameLabel: String { t("myTeam.field.name") }
    static var myTeamNameRequired: String { t("myTeam.validation.nameRequired") }
    static var myTeamSelectLabel: String { t("myTeam.selectLabel") }
    static var selectMyTeamRequired: String { t("myTeam.validation.selectRequired") }
    static var noMyTeamsForGameTitle: String { t("myTeam.empty.title") }
    static var noMyTeamsForGameSubtitle: String { t("myTeam.empty.subtitle") }
    static var defaultMyTeamBadge: String { t("myTeam.defaultBadge") }
    static var myTeamCreatedMessage: String { t("myTeam.createdMessage") }
    static var unknownMyTeamLabel: String { t("myTeam.unknown") }
    static var defaultPlayerName: String { t("common.defaultPlayerName") }

    static func incrementAccessibilityLabel(_ label: String) -> String {
        t("a11y.increment \(label)")
    }
    static func decrementAccessibilityLabel(_ label: String) -> String {
        t("a11y.decrement \(label)")
    }

    static var cancelButton: String { t("common.cancel") }
    static var addButton: String { t("common.add") }
    static var doneButton: String { t("common.done") }

    // Settings
    static var settingsTitle: String { t("settings.title") }
    static var settingsMyTeamSection: String { t("settings.myTeamSection") }
    static var settingsMyTeamEmpty: String { t("settings.myTeamEmpty") }
    static var settingsTooltipOpen: String { t("settings.tooltipOpen") }

    // Stats mini metric labels
    static var statsHitsLabel: String { t("stats.metric.hits") }
    static var statsHomeRunsLabel: String { t("stats.metric.homeRuns") }
    static var statsOpsLabel: String { t("stats.metric.ops") }
    static var statsStrikeoutsLabel: String { t("stats.metric.strikeouts") }
    static var statsWhipLabel: String { t("stats.metric.whip") }
    static var statsAppearancesLabel: String { t("stats.metric.appearances") }
    static var statsPeriodSectionLabel: String { t("stats.periodSection") }

    static func inningsShort(_ innings: Int) -> String { t("innings.short \(innings)") }

    /// 日本語は「3回」「1回1/3」、英語は "3.0"/"1.1" と書式そのものが変わるため
    /// 完成形の文字列ではなくキーを言語側で切り替える。
    static func inningsFromOuts(_ outs: Int) -> String {
        let innings = outs / 3
        let rest = outs % 3
        return rest == 0 ? t("innings.whole \(innings)") : t("innings.fraction \(innings) \(rest)")
    }
}

extension PlateAppearanceResultType {
    var localizedLabel: String {
        switch self {
        case .hit: t("result.type.hit")
        case .out: t("result.type.out")
        case .walk: t("result.type.walk")
        case .error: t("result.type.error")
        }
    }
}

extension PlateAppearanceResultDetail {
    var localizedLabel: String {
        switch self {
        case .single: t("result.detail.single")
        case .double: t("result.detail.double")
        case .triple: t("result.detail.triple")
        case .hr: t("result.detail.hr")
        case .k: t("result.detail.k")
        case .ground: t("result.detail.ground")
        case .fly: t("result.detail.fly")
        case .line: t("result.detail.line")
        case .dp: t("result.detail.dp")
        case .sacBunt: t("result.detail.sacBunt")
        case .sacFly: t("result.detail.sacFly")
        case .other: t("result.detail.other")
        case .bb: t("result.detail.bb")
        case .hbp: t("result.detail.hbp")
        case .e: t("result.detail.e")
        }
    }
}

extension Date {
    /// 移行元の DateFormat('yyyy/MM/dd') に対応。
    var slashDateLabel: String {
        let calendar = Calendar.current
        let c = calendar.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d/%02d/%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    var dateKey: Date {
        Calendar.current.startOfDay(for: self)
    }
}
