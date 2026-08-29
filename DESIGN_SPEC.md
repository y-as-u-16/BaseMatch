# BaseMatch UI リデザイン仕様（iOS 26 ネイティブ化）

目的: Flutter/Material の直訳UIを捨て、**iOS 26 らしい上質なUI**へ作り替える。
機能・文言・データ構造は一切変えない。**見た目と操作感だけ**を変える。

環境: iOS 26.5 / Swift 6.3 / Xcode 26.6 → **Liquid Glass など iOS 26 API を積極的に使ってよい**

---

## 1. デザイン原則（Material の名残を消す）

| 捨てるもの（Material 由来） | 置き換え（iOS ネイティブ） |
|---|---|
| 角丸 8pt の四角いカード | 角丸 **20〜28pt** の `.rect(cornerRadius:style: .continuous)` |
| 1pt の枠線で仕切る | 枠線を消し、**余白・階層・微細な影**で分ける |
| ベタ塗りの `surfaceContainer` 段階 | `.regularMaterial` / `.thinMaterial` / `.glassEffect()` |
| `.system(size: 15, weight: .black)` 固定 | `.font(.headline)` など**セマンティックフォント**（Dynamic Type 対応） |
| 塗り+枠線の Material ボタン | `.buttonStyle(.glass)` / `.glassProminent`、または Capsule の塗り |
| FloatingActionButton | ツールバーの `+` か、下部の Capsule グラスボタン |
| ChoiceChip の格子 | 選択肢は Capsule チップ + `.symbolEffect` / Haptics |
| 影を全要素に付ける | 影は**浮くもの限定**（カード1段、シート、FAB） |

### 必ず入れる iOS らしさ
- **Dynamic Type**: サイズは原則セマンティック（`.largeTitle` `.title2` `.headline` `.subheadline` `.footnote` `.caption`）。
  数値を大きく見せたい所だけ `.font(.system(size:weight:design:))` を使ってよいが、`.rounded` か `.serif` を指定して意図を持たせる。
- **数字は `.monospacedDigit()`**（スコア・打率・防御率など。桁揺れ防止）
- **Haptics**: 選択・保存・カウンタ操作に `.sensoryFeedback(.selection, trigger:)` / `.impact` / `.success`
- **アニメーション**: `.animation(.smooth, value:)` `.spring(response:dampingFraction:)`。数値変化は `.contentTransition(.numericText())`
- **SF Symbols**: `.symbolRenderingMode(.hierarchical)` か `.palette`、状態変化に `.symbolEffect(.bounce)` `.contentTransition(.symbolEffect(.replace))`
- **スクロール演出**: ヘッダーに `.scrollTransition`、リスト項目に軽いフェード/スケール
- **`.safeAreaInset(edge: .bottom)`** で下部固定ボタンを置く（今の自前オーバーレイをやめる）

---

## 2. カラー（**16進コードは変更禁止**）

`AppTheme` の 5 色はブランド資産なので**そのまま維持**する。
- fieldGreen `#1B4332` / leatherBrown `#5C4033` / stitchRed `#C62828` / baseWhite `#FFF8F0` / trophyGold `#D4A017`

変えるのは**使い方**:
- 背景は `Color(.systemGroupedBackground)` 系や `.thinMaterial` を基調にし、緑はアクセントとして使う
- ヒーローやサマリーは **fieldGreen → leatherBrown のメッシュ/グラデーション**で深みを出す
  （iOS 18+ の `MeshGradient` を使ってよい）
- 勝敗色: 勝=fieldGreen系 / 分=trophyGold / 負=グレー（stitchRed は「危険」ではなく差し色に）
- ダークモードでも破綻しないこと（`Color(.systemBackground)` などシステム色を併用）

---

## 3. 画面ごとの方針

### ホーム
- ヒーローを**フルブリード**に。上端はセーフエリアまで伸ばし、スクロールで視差（parallax）が付くと良い
- `MeshGradient` か `LinearGradient` + 野球ダイヤモンドの Canvas（既存の描画は流用可）
- 「今季サマリー」は枠線カードをやめ、**数値主役のレイアウト**へ。
  打率・防御率は `.monospacedDigit()` + `.contentTransition(.numericText())`
- 主要アクションは Capsule の `.glassProminent` / `.glass`
- 直近の試合は `NavigationLink` + カード。`.scrollTransition` で入場アニメーション

### 記録（カレンダー）
- カレンダーは**枠線を消し**、選択日を塗り円（Capsule）で示す iOS カレンダー風に
- 試合がある日は**ドット**（今の「N試合」ピルは情報過多）。複数試合なら小さく数字
- 月切り替えは左右スワイプ（`.gesture` か `TabView(.page)`）＋ヘッダーのボタン
- 「試合を追加」はツールバーの `+`（`.toolbar`）に移し、FAB を廃止
- 選択日の試合セクションはカード群として自然に流す

### 試合作成/編集
- **`Form` + `Section`** を使う（iOS 標準の設定画面の質感）。自前パネルをやめる
- 日付は `DatePicker(.compact)`、イニングは `Picker(.segmented)`、得点は `Stepper` か `TextField(.numberPad)`
- 自チームは `Picker(.menu)` かカスタムの Capsule 選択
- 保存はツールバー右上の「保存」（iOS 慣習）。破棄はキャンセル

### 試合詳細
- 上部にスコアボードを**主役**として大きく（チーム名 + 大きな数字 + 勝敗バッジ）
- グラス素材のスコアカード。数字は `.rounded` デザイン + `.monospacedDigit()`
- 打席/投球の追加は下部の `.safeAreaInset` にグラスボタン2つ
- 記録リストは枠線なしの行 + 区切り、右端に結果 Capsule

### 打席入力（最重要・使用頻度が高い）
- **結果選択を主役**に。上部にサマリー、中央に大きな選択グリッド
- チップは Capsule。選択時に `.symbolEffect(.bounce)` + Haptics + スケール
- カテゴリ（ヒット/アウト/出塁）は色で区別（緑系/グレー系/ゴールド系）
- イニング・打点は `Stepper` ではなく**タップしやすい大きめの ± Capsule**
- 保存ボタンは `.safeAreaInset(edge: .bottom)` にグラスで固定

### 投球入力
- 投球回は**大きな数値ディスプレイ**（`.rounded`, `.monospacedDigit()`, `.contentTransition(.numericText())`）
- クイックボタン（+1/3回, +1回, リセット）は Capsule グラス
- 6つのカウンタは 2 列グリッドのコンパクトなカード（各カードに ± ）

### 成績
- 期間セレクタは `Picker(.segmented)` か Capsule のセグメント
- 選手カードは**大きな主指標**（打率/防御率）を主役に。`.rounded` + `.monospacedDigit()`
- 副指標は小さく整列。可能なら簡易バー/ゲージ（`Gauge` でも可）で視覚化
- 空状態は `ContentUnavailableView` を使う（iOS 標準）

### 設定
- **`List` + `Section`（`.insetGrouped`）** に置き換える。自前カードをやめる
- チーム行は `Label` + デフォルトバッジ
- チーム追加シートは `.presentationDetents([.medium])` + `Form`

---

## 4. 実装ルール（厳守）

- **機能・文言・データは変更しない**。`L10n` の文言をそのまま使う（新規文言が要るなら `L10n` に追加）
- **`BaseMatch/Domain/` 配下は一切触らない**（`StatsCalculator.swift` はテスト35件が通っている）
- **`BaseMatch/Models/` も触らない**
- `AppTheme` の 5 色の 16 進値は変えない（`AppColors` の役割色は再設計してよい）
- 既存の画面ファイルは**中身を作り替えてよい**（ファイルの追加・分割も可）
- ビルドと既存テスト 35 件が通ること
- ダークモード・Dynamic Type（特大サイズ）で破綻しないこと
- コメントは原則不要。書くなら「なぜ」だけ1-2行

## 5. 完了確認コマンド

```bash
cd /Users/egiyasuyuki/dev/personal/BaseMatch
xcodebuild -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|BUILD"

xcodebuild test -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:BaseMatchTests 2>&1 | grep -E "error:|failed|passed on" | tail -5
```
