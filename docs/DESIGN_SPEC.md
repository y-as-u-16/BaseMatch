# BaseMatch デザイン仕様

目的: 機能・ビジネスロジック・アーキテクチャを変えずに、UI の一貫性と情報の優先順位を保つ。
装飾を足して「おしゃれ」にするのではなく、Typography・Spacing・Visual Hierarchy・Alignment の
一貫性で品質を出す。

環境: デプロイターゲット iOS 17 / Swift 6

---

## 1. 基本方針

Minimal / Clean / Native / Content-first / Consistent。

**使わないもの**（AI 生成 UI に頻出し、階層を伝えないわりに視覚ノイズになる）:

- Card の乱用（全要素をカード背景にする、カードの入れ子）
- 大きすぎる Corner Radius（20pt 超）
- 影で要素を浮かせる表現
- Gradient / Glassmorphism / MeshGradient
- 何でも Pill（Capsule）型にする
- Floating Action Button
- Decorative Icon の大量配置
- 過剰な Animation（選択時のスケール変化など）

階層は **Typography・Whitespace・Alignment・Contrast** で作る。
Border・Card・Background Color だけに依存しない。

---

## 2. Design Token

トークンは `Core/Theme/AppTheme.swift` に定義する。**レイアウトに数値を直書きしない。**

### Spacing（4pt グリッド）

| Token | 値 | 用途 |
|---|---|---|
| `Spacing.xxs` | 4 | アイコンとラベルなど密着した要素 |
| `Spacing.xs` | 8 | 行内の要素間 |
| `Spacing.sm` | 12 | まとまりの内側 |
| `Spacing.md` | 16 | 画面の左右余白、カード内側 |
| `Spacing.lg` | 24 | セクション間 |
| `Spacing.xl` | 32 | 画面上の大きな区切り |

### Radius

| Token | 値 | 用途 |
|---|---|---|
| `Radius.small` | 8 | バッジ・チップ |
| `Radius.medium` | 12 | カード・パネル・ボタン |
| `Radius.large` | 16 | 画面幅いっぱいの面 |

### Color

ブランド 5 色の 16 進値は資産なので変更しない（fieldGreen `#1B4332` / leatherBrown `#5C4033` /
stitchRed `#C62828` / baseWhite `#FFF8F0` / trophyGold `#D4A017`）。

色は `AppColors` の役割名でのみ参照する。`Color.red` や `.white.opacity(0.8)` を直書きしない。

- 背景・文字・区切りはシステム色に委ね、ダークモード対応を OS に任せる
- ブランド色はアクセントとして使う
- 濃色面に載る文字は `onDark` / `onDarkVariant` / `onDarkTertiary` を使う
- 勝敗: 勝 = `winColor` / 分 = `drawColor` / 負 = `lossColor`。
  **色だけで状態を伝えず、必ず文字（バッジ）を併記する**

### Typography

SwiftUI のセマンティックフォント（`.largeTitle` `.title` `.headline` `.subheadline`
`.footnote` `.caption`）を使い、**`.system(size:)` で固定 pt を指定しない**（Dynamic Type が効かなくなる）。

主役の数値は `StatValueText` の `Scale`（`.hero` / `.prominent` / `.standard` / `.compact`）で
段階を選ぶ。数値には `.monospacedDigit()` を付けて桁揺れを防ぐ。

---

## 3. 共通コンポーネント

複数画面で実際に再利用されるものだけを `Core/Components/AppComponents.swift` に置く。
過剰な抽象化はしない。

| コンポーネント | 用途 |
|---|---|
| `.cardStyle()` | カード。**影は使わず**背景色の差で分ける（ダークのみ境界線を足す） |
| `PrimaryPanel` | ブランド色ベタ塗りの濃色パネル |
| `SectionHeaderBar` | セクション見出し |
| `StatusBadge` | 勝敗・打席結果などの状態バッジ |
| `CountBadge` | 件数バッジ |
| `StatValueText` | 主役になる数値 |
| `SelectionChip` | 選択肢のチップ |
| `ActionButton` | 下部固定アクション・クイック操作 |
| `PrimaryActionButtonStyle` / `SecondaryActionButtonStyle` | 主要／副次アクション |
| `CounterRow` | ± ステッパー行 |
| `ScoreBoardView` | HOME / AWAY のスコア表示 |
| `EmptyStateView` | 空状態（`ContentUnavailableView` ラッパー） |

**カードを入れ子にしない。** カードは階層を表すために使い、全要素の背景にしない。

---

## 4. iOS 標準コンポーネントを優先する

独自 UI を作ること自体を目的にしない。以下がある場合はそれを使う。

`NavigationStack` / `TabView` / `Form` / `List(.insetGrouped)` / `Sheet` / `Toolbar` / `Menu` /
`Context Menu` / `Swipe Actions` / `Picker` / `DatePicker` / `Stepper` / `Toggle` /
`ContentUnavailableView` / SF Symbols

独自コンポーネントは、UX 上の明確なメリットがある場合のみ使う
（例: カレンダーの試合数ドットは `DatePicker` で表現できないため自前実装を維持）。

---

## 5. 状態設計

通常状態だけでなく Empty / Loading / Error / Disabled / First Use も設計対象とする。

- **Empty**: `ContentUnavailableView` に統一する。単に「データがありません」ではなく、
  次に取るべき行動を示す（`EmptyStateView` の CTA）
- **Loading**: `ProgressView`
- **Error**: `alert` か Form の footer にインライン表示する。**無言で握り潰さない**

---

## 6. Accessibility / Localization

- **Dynamic Type**: セマンティックフォントを使う。固定幅・固定高さは `minWidth` / `minHeight` にする
- **Touch Target**: 44pt 以上
- **VoiceOver**: 意味のまとまりに `.accessibilityElement(children: .combine)`、
  アイコンのみのボタンに `.accessibilityLabel`
- **色だけに依存しない**: 状態は文字やアイコンでも示す
- **Localization**: 日本語・英語の両方でレイアウトが成立すること。
  英語化による Text Expansion に耐えるよう固定幅を避ける

---

## 7. 実装ルール

- 機能・文言・データ構造は変更しない。文言は `L10n` を使う（新規は `L10n` に追加）
- `Domain/` `Models/` は触らない
- `AppTheme` のブランド 5 色の 16 進値は変えない
- ビルドと既存ユニットテストが通ること
- コメントは「なぜ」だけを 1-2 行。コードを読めば分かることは書かない

## 8. 確認コマンド

```bash
cd /Users/egiyasuyuki/dev/personal/BaseMatch

xcodebuild -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "error:|BUILD"

xcodebuild test -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:BaseMatchTests 2>&1 | grep -E "error:|TEST SUCCEEDED|TEST FAILED"
```
