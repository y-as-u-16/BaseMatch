import Foundation

/// 年は桁区切りを付けたくないため、ロケール依存の数値整形を避けて文字列で渡す。
private func plainNumber(_ value: Int) -> String { String(value) }

/// 設定で選ばれた言語。nil なら端末設定に従う。
///
/// `LocalizedStringResource` は解決を表示時まで遅らせるため、SwiftUI は
/// `.environment(\.locale)` に追従して自動で再描画する。String を先に組み立てると
/// 言語を変えても古い文言が残るので、UI へ渡す文言はすべてこの型で扱う。
nonisolated(unsafe) var l10nOverrideLocale: Locale?

private func t(_ key: String.LocalizationValue) -> LocalizedStringResource {
    if let locale = l10nOverrideLocale {
        return LocalizedStringResource(key, locale: locale)
    }
    return LocalizedStringResource(key)
}
/// UI 文言。原文は日本語で、訳は Localizable.xcstrings が持つ。
enum L10n {
    static var appTitle: LocalizedStringResource { t("app.title") }

    static var navHome: LocalizedStringResource { t("nav.home") }
    static var navRecord: LocalizedStringResource { t("nav.record") }
    static var navStats: LocalizedStringResource { t("nav.stats") }

    // Home
    static var homeHeadline: LocalizedStringResource { t("home.headline") }
    static var homeDescription: LocalizedStringResource { t("home.description") }
    static var seasonSummaryTitle: LocalizedStringResource { t("home.seasonSummary.title") }
    static var seasonGamesMetricLabel: LocalizedStringResource { t("home.metric.games") }
    static var seasonRecordMetricLabel: LocalizedStringResource { t("home.metric.record") }
    static var seasonRunsMetricLabel: LocalizedStringResource { t("home.metric.runs") }
    static var seasonAverageMetricLabel: LocalizedStringResource { t("home.metric.average") }
    static var seasonEraMetricLabel: LocalizedStringResource { t("home.metric.era") }
    static var recordGameButton: LocalizedStringResource { t("home.button.recordGame") }
    static var viewStatsButton: LocalizedStringResource { t("home.button.viewStats") }
    static var recentGamesTitle: LocalizedStringResource { t("home.recentGames.title") }
    static var homeEmptyGames: LocalizedStringResource { t("home.empty.games") }

    static func seasonSummarySubtitle(_ year: Int) -> LocalizedStringResource {
        t("home.seasonSummary.subtitle \(plainNumber(year))")
    }
    static func seasonGamesCount(_ count: Int) -> LocalizedStringResource {
        t("home.metric.gamesCount \(count)")
    }
    static func seasonRecordLabel(_ wins: Int, _ losses: Int, _ draws: Int) -> LocalizedStringResource {
        t("home.metric.recordValue \(wins) \(losses) \(draws)")
    }
    static func seasonRunsLabel(_ runs: Int) -> LocalizedStringResource {
        t("home.metric.runsValue \(runs)")
    }

    // Record / calendar
    static var recordTitle: LocalizedStringResource { t("record.title") }
    static var addGameButton: LocalizedStringResource { t("record.addGame") }
    static var selectedDateGamesTitle: LocalizedStringResource { t("record.selectedDateGames") }
    static var noGamesOnSelectedDate: LocalizedStringResource { t("record.noGamesOnDate") }
    static var playerSectionTitle: LocalizedStringResource { t("player.sectionTitle") }
    static var addPlayerButton: LocalizedStringResource { t("player.addButton") }
    static var addPlayerTitle: LocalizedStringResource { t("player.addTitle") }
    static var playerNameLabel: LocalizedStringResource { t("player.nameLabel") }
    static var playerEmptyHint: LocalizedStringResource { t("player.empty") }
    static var deletePlayerTitle: LocalizedStringResource { t("player.deleteTitle") }
    static var deletePlayerMessage: LocalizedStringResource { t("player.deleteMessage") }
    static var directInputLabel: LocalizedStringResource { t("player.directInput") }
    static var statsFilterAllPlayers: LocalizedStringResource { t("stats.filterAllPlayers") }

    static var selectMonthTitle: LocalizedStringResource { t("record.selectMonth") }
    static var jumpToTodayButton: LocalizedStringResource { t("record.jumpToToday") }
    static var previousMonthTooltip: LocalizedStringResource { t("record.previousMonth") }
    static var nextMonthTooltip: LocalizedStringResource { t("record.nextMonth") }

    // Create / edit game
    static var createGameTitle: LocalizedStringResource { t("game.create.title") }
    static var editGameTitle: LocalizedStringResource { t("game.edit.title") }
    static var gameDateLabel: LocalizedStringResource { t("game.field.date") }
    static var awayTeamNameLabel: LocalizedStringResource { t("game.field.awayTeamName") }
    static var awayTeamNameRequired: LocalizedStringResource { t("game.validation.awayTeamNameRequired") }
    static var homeScoreLabel: LocalizedStringResource { t("game.field.homeScore") }
    static var awayScoreLabel: LocalizedStringResource { t("game.field.awayScore") }
    static var scoreRequired: LocalizedStringResource { t("game.validation.scoreRequired") }
    static var scoreMustBeNonNegative: LocalizedStringResource { t("game.validation.scoreNonNegative") }
    static var locationOptionalLabel: LocalizedStringResource { t("game.field.locationOptional") }
    static var inningsCountLabel: LocalizedStringResource { t("game.field.inningsCount") }
    static var inningScoresLabel: LocalizedStringResource { t("game.field.inningScores") }
    static var inningScoresHint: LocalizedStringResource { t("game.field.inningScoresHint") }
    static var topHalfLabel: LocalizedStringResource { t("game.field.topHalf") }
    static var bottomHalfLabel: LocalizedStringResource { t("game.field.bottomHalf") }
    static var totalScoreLabel: LocalizedStringResource { t("game.field.totalScore") }
    static func inningNumberLabel(_ inning: Int) -> LocalizedStringResource {
        t("game.field.inningNumber \(inning)")
    }
    static func inningRunsAccessibilityLabel(_ inning: Int, _ half: String) -> LocalizedStringResource {
        t("game.field.inningRunsAccessibility \(inning) \(half)")
    }
    static var createButton: LocalizedStringResource { t("common.create") }
    static var saveChangesButton: LocalizedStringResource { t("common.saveChanges") }
    static var gameUpdatedMessage: LocalizedStringResource { t("game.updatedMessage") }

    // Game detail
    static var gameDetailTitle: LocalizedStringResource { t("game.detail.title") }
    static var gameNotFound: LocalizedStringResource { t("game.notFound") }
    static var addPlateAppearanceButton: LocalizedStringResource { t("game.detail.addPlateAppearance") }
    static var addPitchingButton: LocalizedStringResource { t("game.detail.addPitching") }
    static var plateAppearanceRecordsTitle: LocalizedStringResource { t("game.detail.plateAppearances") }
    static var emptyPlateAppearances: LocalizedStringResource { t("game.detail.emptyPlateAppearances") }
    static var lineScoreTitle: LocalizedStringResource { t("game.detail.lineScore") }
    static var lineScoreTotalHeader: LocalizedStringResource { t("game.detail.lineScoreTotal") }
    static var pitchingRecordsTitle: LocalizedStringResource { t("game.detail.pitchingRecords") }
    static var emptyPitchingAppearances: LocalizedStringResource { t("game.detail.emptyPitching") }

    static func plateAppearanceListSubtitle(_ inning: String, _ rbi: Int) -> LocalizedStringResource {
        t("game.detail.paSubtitle \(inning) \(rbi)")
    }
    static func pitchingOutsTitle(_ innings: String) -> LocalizedStringResource {
        t("game.detail.pitchingOuts \(innings)")
    }
    static func pitchingListSubtitle(_ runs: Int, _ earnedRuns: Int, _ strikeouts: Int) -> LocalizedStringResource {
        t("game.detail.pitchingSubtitle \(runs) \(earnedRuns) \(strikeouts)")
    }

    // Plate appearance input
    static var plateAppearanceInputTitle: LocalizedStringResource { t("pa.input.title") }
    static var selectPlateAppearanceResultMessage: LocalizedStringResource { t("pa.selectResultMessage") }
    static var notSelectedLabel: LocalizedStringResource { t("common.notSelected") }
    static var playerNameRequired: LocalizedStringResource { t("validation.playerNameRequired") }
    static var batterNameLabel: LocalizedStringResource { t("pa.field.batterName") }
    static var inningLabel: LocalizedStringResource { t("pa.field.inning") }
    static var rbiLabel: LocalizedStringResource { t("pa.field.rbi") }
    static var hitSectionTitle: LocalizedStringResource { t("pa.section.hit") }
    static var outSectionTitle: LocalizedStringResource { t("pa.section.out") }
    static var onBaseSectionTitle: LocalizedStringResource { t("pa.section.onBase") }
    static var saveButton: LocalizedStringResource { t("common.save") }

    static func plateAppearanceSummary(_ inning: Int, _ result: String, _ rbi: Int) -> LocalizedStringResource {
        t("pa.summary \(inning) \(result) \(rbi)")
    }

    // Pitching input
    static var pitchingInputTitle: LocalizedStringResource { t("pitching.input.title") }
    static var pitcherNameLabel: LocalizedStringResource { t("pitching.field.pitcherName") }
    static var runsLabel: LocalizedStringResource { t("pitching.field.runs") }
    static var earnedRunsLabel: LocalizedStringResource { t("pitching.field.earnedRuns") }
    static var hitsAllowedLabel: LocalizedStringResource { t("pitching.field.hitsAllowed") }
    static var walksAllowedLabel: LocalizedStringResource { t("pitching.field.walksAllowed") }
    static var strikeoutsLabel: LocalizedStringResource { t("pitching.field.strikeouts") }
    static var homeRunsAllowedLabel: LocalizedStringResource { t("pitching.field.homeRunsAllowed") }
    static var pitchingInningsLabel: LocalizedStringResource { t("pitching.field.innings") }
    static var addOneThirdInningButton: LocalizedStringResource { t("pitching.button.addOneThird") }
    static var addOneInningButton: LocalizedStringResource { t("pitching.button.addOneInning") }
    static var resetOneInningButton: LocalizedStringResource { t("pitching.button.resetOneInning") }

    static func pitchingInputSummary(_ innings: String, _ runs: Int, _ earnedRuns: Int) -> LocalizedStringResource {
        t("pitching.input.summary \(innings) \(runs) \(earnedRuns)")
    }
    static func outsLabel(_ outs: Int) -> LocalizedStringResource { t("pitching.outsLabel \(outs)") }

    // Stats
    static var statsTitle: LocalizedStringResource { t("stats.title") }
    static var statsPeriodAll: LocalizedStringResource { t("stats.period.all") }
    static var statsPeriodMonthPlaceholder: LocalizedStringResource { t("stats.period.monthPlaceholder") }
    static var statsEmptyTitle: LocalizedStringResource { t("stats.empty.title") }
    static var statsEmptyMessage: LocalizedStringResource { t("stats.empty.message") }
    static var statsEmptyCta: LocalizedStringResource { t("stats.empty.cta") }
    static var battingStatsTitle: LocalizedStringResource { t("stats.batting.title") }
    static var pitchingStatsTitle: LocalizedStringResource { t("stats.pitching.title") }
    static var noBattingStatsLabel: LocalizedStringResource { t("stats.batting.none") }
    static var noPitchingStatsLabel: LocalizedStringResource { t("stats.pitching.none") }
    static var reloadButton: LocalizedStringResource { t("common.reload") }

    static func statsPeriodMonth(_ year: Int, _ month: Int) -> LocalizedStringResource {
        t("stats.period.month \(plainNumber(year)) \(month)")
    }
    static func battingStatsSummary(_ hits: Int, _ hr: Int, _ ops: String) -> LocalizedStringResource {
        t("stats.batting.summary \(hits) \(hr) \(ops)")
    }
    static func pitchingStatsSummary(_ strikeouts: Int, _ whip: String, _ games: Int) -> LocalizedStringResource {
        t("stats.pitching.summary \(strikeouts) \(whip) \(games)")
    }

    // My team
    static var addMyTeamButton: LocalizedStringResource { t("myTeam.addButton") }
    static var addMyTeamTitle: LocalizedStringResource { t("myTeam.addTitle") }
    static var myTeamNameLabel: LocalizedStringResource { t("myTeam.field.name") }
    static var myTeamNameRequired: LocalizedStringResource { t("myTeam.validation.nameRequired") }
    static var myTeamSelectLabel: LocalizedStringResource { t("myTeam.selectLabel") }
    static var selectMyTeamRequired: LocalizedStringResource { t("myTeam.validation.selectRequired") }
    static var noMyTeamsForGameTitle: LocalizedStringResource { t("myTeam.empty.title") }
    static var noMyTeamsForGameSubtitle: LocalizedStringResource { t("myTeam.empty.subtitle") }
    static var settingsAppearanceSection: LocalizedStringResource { t("settings.appearanceSection") }
    static var settingsLanguage: LocalizedStringResource { t("settings.language") }
    static var settingsTheme: LocalizedStringResource { t("settings.theme") }
    static var followSystemLabel: LocalizedStringResource { t("settings.followSystem") }
    static var lightThemeLabel: LocalizedStringResource { t("settings.themeLight") }
    static var darkThemeLabel: LocalizedStringResource { t("settings.themeDark") }

    static var editButton: LocalizedStringResource { t("common.edit") }
    static var editPlateAppearanceTitle: LocalizedStringResource { t("plateAppearance.editTitle") }
    static var editPitchingTitle: LocalizedStringResource { t("pitching.editTitle") }
    static var recordNotFound: LocalizedStringResource { t("record.notFound") }

    static var deleteButton: LocalizedStringResource { t("common.delete") }
    static var deleteCannotUndo: LocalizedStringResource { t("common.deleteCannotUndo") }
    static var deleteGameTitle: LocalizedStringResource { t("game.delete.title") }
    static var deleteGameMessage: LocalizedStringResource { t("game.delete.message") }
    static var deletePlateAppearanceTitle: LocalizedStringResource { t("plateAppearance.delete.title") }
    static var deletePitchingTitle: LocalizedStringResource { t("pitching.delete.title") }

    static var defaultMyTeamBadge: LocalizedStringResource { t("myTeam.defaultBadge") }
    static var setDefaultMyTeamHint: LocalizedStringResource { t("myTeam.setDefaultHint") }
    static var setDefaultMyTeamAccessibility: LocalizedStringResource { t("myTeam.setDefaultAccessibility") }
    static var myTeamCreatedMessage: LocalizedStringResource { t("myTeam.createdMessage") }
    static var unknownMyTeamLabel: LocalizedStringResource { t("myTeam.unknown") }
    static var defaultPlayerName: LocalizedStringResource { t("common.defaultPlayerName") }

    static func incrementAccessibilityLabel(_ label: String) -> LocalizedStringResource {
        t("a11y.increment \(label)")
    }
    static func decrementAccessibilityLabel(_ label: String) -> LocalizedStringResource {
        t("a11y.decrement \(label)")
    }

    static var cancelButton: LocalizedStringResource { t("common.cancel") }
    static var addButton: LocalizedStringResource { t("common.add") }
    static var doneButton: LocalizedStringResource { t("common.done") }

    // Settings
    static var settingsTitle: LocalizedStringResource { t("settings.title") }
    static var settingsMyTeamSection: LocalizedStringResource { t("settings.myTeamSection") }
    static var settingsMyTeamEmpty: LocalizedStringResource { t("settings.myTeamEmpty") }
    static var settingsTooltipOpen: LocalizedStringResource { t("settings.tooltipOpen") }
    static var settingsAboutSection: LocalizedStringResource { t("settings.aboutSection") }
    static var settingsPrivacyPolicy: LocalizedStringResource { t("settings.privacyPolicy") }
    static var settingsVersion: LocalizedStringResource { t("settings.version") }

    // Stats mini metric labels
    static var statsHitsLabel: LocalizedStringResource { t("stats.metric.hits") }
    static var statsHomeRunsLabel: LocalizedStringResource { t("stats.metric.homeRuns") }
    static var statsOpsLabel: LocalizedStringResource { t("stats.metric.ops") }
    static var statsStrikeoutsLabel: LocalizedStringResource { t("stats.metric.strikeouts") }
    static var statsWhipLabel: LocalizedStringResource { t("stats.metric.whip") }
    static var statsAppearancesLabel: LocalizedStringResource { t("stats.metric.appearances") }
    static var statsPeriodSectionLabel: LocalizedStringResource { t("stats.periodSection") }

    static func inningsShort(_ innings: Int) -> LocalizedStringResource { t("innings.short \(innings)") }

    /// 日本語は「3回」「1回1/3」、英語は "3.0"/"1.1" と書式そのものが変わるため
    /// 完成形の文字列ではなくキーを言語側で切り替える。
    static func inningsFromOuts(_ outs: Int) -> LocalizedStringResource {
        let innings = outs / 3
        let rest = outs % 3
        return rest == 0 ? t("innings.whole \(innings)") : t("innings.fraction \(innings) \(rest)")
    }
}

extension PlateAppearanceResultType {
    var localizedLabel: LocalizedStringResource {
        switch self {
        case .hit: t("result.type.hit")
        case .out: t("result.type.out")
        case .walk: t("result.type.walk")
        case .error: t("result.type.error")
        }
    }
}

extension PlateAppearanceResultDetail {
    var localizedLabel: LocalizedStringResource {
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
