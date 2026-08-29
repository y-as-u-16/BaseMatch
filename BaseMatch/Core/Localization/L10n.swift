import Foundation

/// 移行元の app_localizations_ja.dart に対応する日本語文言。
enum L10n {
    static let appTitle = "草野球マッチ"

    static let navHome = "ホーム"
    static let navRecord = "記録"
    static let navStats = "成績"

    // Home
    static let homeHeadline = "試合を記録しよう"
    static let homeDescription = "対戦カード、打席、ピッチング成績をまとめて残せます。"
    static let seasonSummaryTitle = "今季サマリー"
    static let seasonGamesMetricLabel = "試合"
    static let seasonRecordMetricLabel = "勝敗"
    static let seasonRunsMetricLabel = "得点"
    static let seasonAverageMetricLabel = "打率"
    static let seasonEraMetricLabel = "防御率"
    static let recordGameButton = "試合を記録する"
    static let viewStatsButton = "成績を見る"
    static let recentGamesTitle = "直近の試合"
    static let homeEmptyGames = "まだ試合がありません。最初の試合を記録してください。"

    static func seasonSummarySubtitle(_ year: Int) -> String { "\(year)年の記録" }
    static func seasonGamesCount(_ count: Int) -> String { "\(count)試合" }
    static func seasonRecordLabel(_ wins: Int, _ losses: Int, _ draws: Int) -> String {
        "\(wins)勝 \(losses)敗 \(draws)分"
    }
    static func seasonRunsLabel(_ runs: Int) -> String { "\(runs)点" }

    // Record / calendar
    static let recordTitle = "記録"
    static let addGameButton = "試合を追加"
    static let selectedDateGamesTitle = "選択日の試合"
    static let noGamesOnSelectedDate = "この日の試合はありません"
    static let previousMonthTooltip = "前の月"
    static let nextMonthTooltip = "次の月"

    // Create / edit game
    static let createGameTitle = "試合を作成"
    static let editGameTitle = "試合を編集"
    static let gameDateLabel = "試合日"
    static let awayTeamNameLabel = "相手チーム名"
    static let awayTeamNameRequired = "相手チーム名を入力してください"
    static let homeScoreLabel = "自チーム得点"
    static let awayScoreLabel = "相手チーム得点"
    static let scoreRequired = "点数を入力してください"
    static let scoreMustBeNonNegative = "0以上の点数を入力してください"
    static let locationOptionalLabel = "球場（任意）"
    static let inningsCountLabel = "イニング数"
    static let createButton = "作成する"
    static let saveChangesButton = "保存する"
    static let gameUpdatedMessage = "試合を更新しました"

    // Game detail
    static let gameDetailTitle = "試合詳細"
    static let gameNotFound = "試合が見つかりません"
    static let addPlateAppearanceButton = "打席"
    static let addPitchingButton = "投手"
    static let plateAppearanceRecordsTitle = "打席記録"
    static let emptyPlateAppearances = "まだ打席記録がありません"
    static let pitchingRecordsTitle = "ピッチング記録"
    static let emptyPitchingAppearances = "まだピッチング記録がありません"

    static func plateAppearanceListSubtitle(_ inning: String, _ rbi: Int) -> String {
        "\(inning)回 / 打点 \(rbi)"
    }
    static func pitchingOutsTitle(_ innings: String) -> String { "投球回 \(innings)" }
    static func pitchingListSubtitle(_ runs: Int, _ earnedRuns: Int, _ strikeouts: Int) -> String {
        "失点 \(runs) / 自責 \(earnedRuns) / 奪三振 \(strikeouts)"
    }

    // Plate appearance input
    static let plateAppearanceInputTitle = "打席入力"
    static let selectPlateAppearanceResultMessage = "打席結果を選択してください"
    static let notSelectedLabel = "未選択"
    static let playerNameRequired = "選手名を入力してください"
    static let batterNameLabel = "打者名"
    static let inningLabel = "イニング"
    static let rbiLabel = "打点"
    static let hitSectionTitle = "ヒット"
    static let outSectionTitle = "アウト"
    static let onBaseSectionTitle = "出塁・その他"
    static let saveButton = "登録する"

    static func plateAppearanceSummary(_ inning: Int, _ result: String, _ rbi: Int) -> String {
        "\(inning)回 / \(result) / 打点 \(rbi)"
    }

    // Pitching input
    static let pitchingInputTitle = "ピッチング入力"
    static let pitcherNameLabel = "投手名"
    static let runsLabel = "失点"
    static let earnedRunsLabel = "自責点"
    static let hitsAllowedLabel = "被安打"
    static let walksAllowedLabel = "与四死球"
    static let strikeoutsLabel = "奪三振"
    static let homeRunsAllowedLabel = "被本塁打"
    static let pitchingInningsLabel = "投球回"
    static let addOneThirdInningButton = "+1/3回"
    static let addOneInningButton = "+1回"
    static let resetOneInningButton = "1回に戻す"

    static func pitchingInputSummary(_ innings: String, _ runs: Int, _ earnedRuns: Int) -> String {
        "投球回 \(innings) / 失点 \(runs) / 自責 \(earnedRuns)"
    }
    static func outsLabel(_ outs: Int) -> String { "\(outs) アウト" }

    // Stats
    static let statsTitle = "成績"
    static let statsPeriodAll = "全期間"
    static let statsPeriodMonthPlaceholder = "月を選ぶ"
    static let statsEmptyTitle = "まだ記録がありません"
    static let statsEmptyMessage = "最初の試合を記録して、成績を積み上げよう。"
    static let statsEmptyCta = "試合を作成する"
    static let battingStatsTitle = "打撃成績"
    static let pitchingStatsTitle = "ピッチング成績"
    static let noBattingStatsLabel = "打撃記録なし"
    static let noPitchingStatsLabel = "投球記録なし"
    static let reloadButton = "再読み込み"

    static func statsPeriodMonth(_ year: Int, _ month: Int) -> String { "\(year)年\(month)月" }
    static func battingStatsSummary(_ hits: Int, _ hr: Int, _ ops: String) -> String {
        "\(hits)安打 / \(hr)本塁打 / OPS \(ops)"
    }
    static func pitchingStatsSummary(_ strikeouts: Int, _ whip: String, _ games: Int) -> String {
        "\(strikeouts)奪三振 / WHIP \(whip) / \(games)登板"
    }

    // My team
    static let addMyTeamButton = "チームを追加"
    static let addMyTeamTitle = "自チームを追加"
    static let myTeamNameLabel = "チーム名"
    static let myTeamNameRequired = "チーム名を入力してください"
    static let myTeamSelectLabel = "自チーム"
    static let selectMyTeamRequired = "自チームを選択してください"
    static let noMyTeamsForGameTitle = "自チームを追加してください"
    static let noMyTeamsForGameSubtitle = "試合を作成するには、先に自分のチームが必要です。"
    static let defaultMyTeamBadge = "デフォルト"
    static let myTeamCreatedMessage = "チームを追加しました"
    static let unknownMyTeamLabel = "不明なチーム"
    static let cancelButton = "キャンセル"
    static let addButton = "追加"
    static let doneButton = "完了"

    // Settings
    static let settingsTitle = "設定"
    static let settingsMyTeamSection = "マイチーム"
    static let settingsMyTeamEmpty = "まだチームが登録されていません。"
    static let settingsTooltipOpen = "設定を開く"

    // Stats mini metric labels
    static let statsHitsLabel = "安打"
    static let statsHomeRunsLabel = "本塁打"
    static let statsOpsLabel = "OPS"
    static let statsStrikeoutsLabel = "奪三振"
    static let statsWhipLabel = "WHIP"
    static let statsAppearancesLabel = "登板"
    static let statsPeriodSectionLabel = "期間"

    static func inningsShort(_ innings: Int) -> String { "\(innings)回" }

    /// アウト数から「3回」「1回1/3」形式へ。
    static func inningsFromOuts(_ outs: Int) -> String {
        let innings = outs / 3
        let rest = outs % 3
        return rest == 0 ? "\(innings)回" : "\(innings)回\(rest)/3"
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
