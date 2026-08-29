# Flutter → Swift 移行仕様書（BaseMatch / 草野球マッチ）

移行元: `/Users/egiyasuyuki/dev/personal/base_match`（Flutter, 59ファイル / 約14,600行）
移行先: `/Users/egiyasuyuki/dev/personal/BaseMatch`（SwiftUI + SwiftData, iOS 26.5, Swift 6.3）

Xcode プロジェクトは `PBXFileSystemSynchronizedRootGroup` を使用しているため、
`BaseMatch/` 配下に `.swift` を置くだけでビルド対象に入る（pbxproj の編集は不要）。

## 技術マッピング

| Flutter | Swift |
|---|---|
| drift (SQLite) | SwiftData `@Model` |
| Riverpod StateNotifier | `@Observable` / `@Query` |
| go_router | `NavigationStack` + `TabView` |
| 文字列定数 | 型安全な `enum`（String RawValue で DB 互換） |
| flutter_test / mocktail | Swift Testing |
| intl DateFormat | `Date.FormatStyle` |

## カラーパレット（AppTheme）

野球モチーフ。16進コードは移行元と完全一致させる。

- fieldGreen `#1B4332`（フィールドの芝／primary シード）
- leatherBrown `#5C4033`（グラブ・バットの革／secondary）
- stitchRed `#C62828`（ボールの縫い目／tertiary・タブ選択色）
- baseWhite `#FFF8F0`（ベース／surface）
- trophyGold `#D4A017`

角丸は基本 8pt（一部カード 12pt、ダイアログ 20pt）。
ライト／ダーク両対応。

## データモデル（SwiftData）

### MyTeam
| フィールド | 型 | 備考 |
|---|---|---|
| id | String | 主キー（UUID v4） |
| name | String | 必須・trim 済み |
| colorKey | String? | 空文字は nil に正規化 |
| isDefault | Bool | |
| displayOrder | Int | 新規は max+1、最初は 0 |
| archivedAt | Date? | nil のものだけ一覧に出す |
| createdAt / updatedAt | Date | |

一覧の並び: displayOrder 昇順 → createdAt 昇順。
作成時、`isDefault` 指定または既存チームが空なら default にし、他の default を解除（トランザクション）。

### Game
| フィールド | 型 | 備考 |
|---|---|---|
| id | String | 主キー |
| date | Date | |
| location | String? | 空文字は nil |
| myTeamId | String | MyTeam 参照 |
| awayTeamName | String | 必須 |
| homeScore / awayScore | Int? | 既定 0 |
| status | GameStatus | draft / final |
| createdAt | Date | |
| innings | Int? | 正数のみ |

### PlateAppearance（打席）
| フィールド | 型 | 備考 |
|---|---|---|
| id | String | 主キー |
| gameId | String | |
| batterName | String | 既定 "自分" |
| inning | Int? | 正数のみ |
| resultType | PlateAppearanceResultType | |
| resultDetail | PlateAppearanceResultDetail | |
| rbi | Int? | 0 以上 |
| createdAt | Date | |

### PitchingAppearance（登板）
id / gameId / pitcherName（既定 "自分"）/ outsPitched（正数）/ runs / earnedRuns /
hitsAllowed / walks / strikeouts / homeRunsAllowed（すべて 0 以上）/ createdAt

## Enum 定義（DB 互換の rawValue は移行元の文字列と一致させること）

### GameStatus
`draft` / `final`

### PlateAppearanceResultType（rawValue → 日本語ラベル）
- `hit` → ヒット
- `out` → アウト
- `walk` → 四死球
- `error` → エラー

### PlateAppearanceResultDetail（rawValue → 日本語ラベル）
- `single` → 単打
- `double` → 二塁打
- `triple` → 三塁打
- `hr` → 本塁打
- `k` → 三振
- `ground` → ゴロ
- `fly` → フライ
- `line` → ライナー
- `dp` → 併殺
- `sac_bunt` → 犠打
- `sac_fly` → 犠飛
- `other` → その他
- `bb` → 四球
- `hbp` → 死球
- `e` → エラー

## 成績計算ロジック（最重要・テストで固定されている）

### 打率などのフォーマット
`_formatRate(分子, 分母)`:
- 分母が 0 → `".000"`
- それ以外 → 小数第3位まで。**1 未満なら先頭の "0" を落とす**（`0.333` → `.333`、`1.000` はそのまま）

### BattingStats の集計（1打席ごと）
- `pa` +1（常に）
- `isSacrifice` = detail が `sac_bunt` または `sac_fly`
- `isAtBat` = 犠打/犠飛でない かつ type が `hit`/`out`/`error` のいずれか → `ab` +1
- `hits` +1 … type == `hit`
- `doubles` / `triples` / `hr` … detail 一致で +1
- `walks` +1 … detail == `bb`（**`hbp` は含めない**）
- `hbp` +1 … detail == `hbp`
- `sacFly` +1 … detail == `sac_fly`
- `so` +1 … detail == `k`

派生:
- `singles` = hits − doubles − triples − hr
- `totalBases` = singles + doubles×2 + triples×3 + hr×4

指標:
- `averageLabel` = rate(hits, ab)
- `obpLabel` = rate(hits+walks+hbp, ab+walks+hbp+sacFly)
- `slgLabel` = rate(totalBases, ab)
- `opsLabel` = OBP + SLG を小数第3位で。**分母(OBP)が 0 のときだけ ".000"**。
  AB=0 でも OBP が計算できるなら OPS は出す（SLG は AB=0 なら 0.0 扱い）。
  例: 四球2つだけ → OBP 1.000 / SLG .000 / **OPS 1.000**

### PitchingStats
- `inningsLabel`: outs÷3 が商、余り rest。rest==0 → `"3"`、それ以外 → `"1.1"` 形式
- `eraLabel`: outs==0 → `"-.--"`、それ以外 `earnedRuns × 27 / outs` を小数2桁
- `whipLabel`: outs==0 → `"-.--"`、それ以外 `(walks + hitsAllowed) × 3 / outs` を小数2桁

### 個人別集計（NamedBattingStats / NamedPitchingStats）
名前でグルーピング。並び順は
- 打撃: `pa` 降順 → 同数なら名前昇順
- 投球: `games` 降順 → 同数なら名前昇順

### 期間フィルタ
- `StatsPeriod` = `.all` / `.month(year, month)`
- `availableMonths(games)`: 記録のある年月を**新しい順**に
- 月指定時は対象月の試合 ID に属する appearance のみ返す。`.all` は絞り込まない

### SeasonSummary（ホーム用）
当年（`now.year`）の試合のみ対象。
- games = 当年の試合数
- 各試合で homeScore(既定0) と awayScore(既定0) を比較し wins / losses / draws を集計
- totalRuns = homeScore の合計
- battingAverage = 当年打席の `averageLabel`
- era = 当年登板の `eraLabel`

## 画面構成

スプラッシュ（1.5秒 / フェードイン / 背景 #1B4332 / SplashLogo 200pt）
→ 3タブ:
1. **ホーム**（`house`）
2. **記録**（`baseball`）
3. **成績**（`chart.bar`）
設定画面はホーム右上の歯車から push。

### ホーム
- ヒーロー: primary→secondary のグラデーション、野球ダイヤモンドを Canvas で描画、
  年ピル「2026年の記録」、見出し「試合を記録しよう」、説明「対戦カード、打席、ピッチング成績をまとめて残せます。」、
  スコアボード（試合数 / 勝敗 W-L-D）
- 主要アクション: 「試合を記録する」（塗り）/「成績を見る」（枠線）
- 今季サマリーカード: 試合 / 勝敗 / 得点 / 打率 / 防御率 の5タイル（1枚目のみ強調色）
- 直近の試合: 最大3件。空なら「まだ試合がありません。最初の試合を記録してください。」

### 記録（試合一覧）
- ヘッダーパネル（primary 背景）に「記録」と試合数
- 月カレンダー: 日曜始まり、前月/次月ボタン、今日は tertiary のドット、
  試合のある日はピル（"N試合"）、選択日は primaryContainer
- 選択日の試合セクション（空なら「この日の試合はありません」）
- FAB「試合を追加」→ 選択日を初期値に作成画面へ

### 試合作成／編集
入力: 試合日（ホイールピッカー, 2000年〜今日+365日）/ 自チーム（未登録なら追加導線）/
相手チーム名（必須）/ 球場（任意）/ 自チーム得点・相手得点（数字のみ・0以上・必須）/
イニング数（3,5,7,9 のセグメント。既定 7）
編集時は既存値をプリフィル。保存後 `final` 状態の試合は編集不可。

### 試合詳細
- サマリーパネル（primary 背景）: 「自チーム vs 相手」、日付・球場チップ、スコアボード
- アクション: 「打席」/「投手」
- 打席記録リスト / ピッチング記録リスト（件数バッジ、空文言あり）

### 打席入力
- サマリーカード「N回 / 結果 / 打点 M」
- 打者名（既定 "自分"）、イニング（1〜99, 既定1）、打点（0〜99, 既定0）のステッパー
- 結果選択（未選択では保存不可）:
  - ヒット: 単打 / 二塁打 / 三塁打 / 本塁打
  - アウト: 三振 / ゴロ / フライ / ライナー / 併殺 / 犠打 / 犠飛 / その他
  - 出塁・その他: 四球 / 死球 / エラー

### 投球入力
- サマリーカード「投球回 X / 失点 N / 自責 M」（primary 背景）
- 投手名（既定 "自分"）
- 投球回カウンタ: outs 単位（1〜99, 既定3）。"+1/3回" / "+1回" / "1回に戻す"。
  表示は「1回1/3」形式 と 「N アウト」
- カウンタ 6種（0〜99）: 失点 / 自責点 / 被安打 / 与四死球 / 奪三振 / 被本塁打

### 成績
- 記録が1件もなければ空状態（「まだ記録がありません」＋ CTA「試合を作成する」）
- 期間セレクタ: 「全期間」/ 月選択（ホイール）
- 打撃成績: 選手ごとカード（打率を大きく / 「N安打 / M本塁打 / OPS X」）
- ピッチング成績: 選手ごとカード（防御率を大きく / 「N奪三振 / WHIP X / M登板」）

### 設定
マイチーム一覧（デフォルトバッジ）＋「チームを追加」。
チーム追加はボトムシート（チーム名必須）。

## 日本語文言（抜粋・完全版は移行元 app_localizations_ja.dart 準拠）

アプリ名「草野球マッチ」/ タブ: ホーム・記録・成績 /
「試合を記録する」「成績を見る」「今季サマリー」「直近の試合」「試合を追加」
「試合を作成」「試合を編集」「保存する」「作成する」「登録する」「追加」「キャンセル」
「打席入力」「ピッチング入力」「試合詳細」「設定」「マイチーム」「デフォルト」
書式:
- 「{year}年の記録」「{year}年{month}月」「{count}試合」「{w}勝 {l}敗 {d}分」「{runs}点」「{n}回」
- 「{inning}回 / {result} / 打点 {rbi}」「投球回 {x} / 失点 {r} / 自責 {er}」「{outs} アウト」
- 「{h}安打 / {hr}本塁打 / OPS {ops}」「{k}奪三振 / WHIP {whip} / {g}登板」
- 投球回: 「{n}回」/「{n}回{rest}/3」

## バリデーション
- チーム名 / 相手チーム名 / 選手名: trim 後に空なら不可
- スコア: 0 以上の整数、必須
- innings / inning: 指定するなら正数
- outsPitched: 正数（1以上）
- 投球系カウンタ: 0 以上

## 移植するテスト（Swift Testing）
移行元 `test/` の 12 ファイル相当。特に `stats_calculator_test.dart` の
打率/OPS/防御率/WHIP/端数投球回/個人別集計/期間フィルタのケースは必ず再現する。

---

# 実装済みの土台（サブエージェントはこれを再利用すること・**再定義禁止**）

## 完成済みファイル
- `BaseMatch/Domain/BaseballEnums.swift`
  `GameStatus` / `PlateAppearanceResultType` / `PlateAppearanceResultDetail`（各 `.label`、detail は `.systemImage` も）
  `PlateAppearanceResultOption`（`.hitOptions` / `.outOptions` / `.onBaseOptions`）
- `BaseMatch/Domain/StatsCalculator.swift`
  `BattingStats` / `PitchingStats` / `NamedBattingStats` / `NamedPitchingStats` /
  `StatsPeriod`(.all / .month(year:month:)) / `availableMonths(_:)` / `eligibleGameIds(_:period:)` /
  `filterPlateAppearances` / `filterPitchingAppearances`（games+period 版と eligibleGameIds+isAll 版）
  ※**テスト18件合格済み。絶対に変更しないこと。**
- `BaseMatch/Domain/SeasonSummary.swift` … `SeasonSummary.from(games:plateAppearances:pitchingAppearances:now:)`
- `BaseMatch/Domain/AppError.swift` … `AppError`、`String.trimmed` / `String.normalizedOptional`
- `BaseMatch/Domain/GameRepository.swift` / `MyTeamRepository.swift`（@MainActor struct、バリデーション込み）
- `BaseMatch/Domain/AppStore.swift` … `@Observable @MainActor final class AppStore`
- `BaseMatch/Models/Models.swift` … SwiftData `@Model`: `MyTeam` / `Game` / `PlateAppearance` / `PitchingAppearance`
- `BaseMatch/Core/Theme/AppTheme.swift` … `AppTheme`(色定数, `cornerRadius`=8) / `AppColors` / `@Environment(\.appColors)`
- `BaseMatch/Core/Localization/L10n.swift` … 全日本語文言 + `Date.slashDateLabel` / `Date.dateKey`
- `BaseMatch/Core/Components/AppComponents.swift`
  `AppPanel` / `PrimaryPanel` / `SectionHeaderBar` / `CountBadge` / `EmptyTextPanel` /
  `EmptyStateView` / `PrimaryActionButtonStyle` / `SecondaryActionButtonStyle` / `CounterRow`
- `BaseMatch/Features/RootView.swift` … `RootView` / `SplashView` / `AppTab` / `MainTabView`
- `BaseMatch/Features/Home/HomeView.swift` … `HomeView` / `HomeHero` / `SeasonSummaryCard` /
  `HomePrimaryActions` / `HomeRecentGamesSection`

## AppStore の API（画面から使うもの）
```swift
@Environment(AppStore.self) private var store
```
- 読み取り: `store.games` / `sortedGames`(日付降順) / `plateAppearances` / `pitchingAppearances` /
  `myTeams` / `myTeamById` / `defaultMyTeam` / `isLoaded` / `seasonSummary` / `errorMessage`
- 参照: `store.game(id:)` / `plateAppearances(gameId:)` / `pitchingAppearances(gameId:)` / `teamName(for:)`
- 更新: `createGame(date:myTeamId:awayTeamName:location:innings:homeScore:awayScore:)` /
  `updateGame(gameId:...)` / `addPlateAppearance(gameId:batterName:resultType:resultDetail:inning:rbi:)` /
  `addPitchingAppearance(gameId:pitcherName:outsPitched:runs:earnedRuns:hitsAllowed:walks:strikeouts:homeRunsAllowed:)` /
  `finalizeGame(id:)` / `createMyTeam(name:colorKey:isDefault:)`
  （失敗時は nil を返し `store.errorMessage` に格納。throw しない）

## 共通の画面規約
- 背景は `colors.surfaceContainerLowest`、角丸は `AppTheme.cornerRadius`(=8)
- 色は必ず `@Environment(\.appColors) private var colors` から取る（`Color.blue` 等の直書き禁止）
- 文言は必ず `L10n` から取る（日本語のベタ書き禁止）
- ナビゲーションは `NavigationStack` + `navigationDestination(for: GameRoute.self)`

## 未実装（担当を割り振る）
1. `GameRoute`（画面遷移の enum）+ `GameRecordCard`（試合カード）
2. 記録タブ（カレンダー）`GamesView`
3. 試合作成/編集 `CreateGameView`
4. 試合詳細 `GameDetailView`
5. 打席入力 `PlateAppearanceInputView`
6. 投球入力 `PitchingInputView`
7. 成績 `StatsView`
8. 設定 `SettingsView` + マイチーム追加シート `CreateMyTeamSheet`
