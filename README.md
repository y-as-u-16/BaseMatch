# BaseMatch（草野球マッチ）

草野球・ソフトボールの試合記録アプリ。打席と登板を記録すると、打率・出塁率・OPS・防御率・WHIP を自動で計算する。

アカウント登録は不要で、データは端末内にのみ保存される。

## 動作環境

- iOS 17.0 以降（iPhone 専用）
- Xcode 26 / Swift 6

## 構成

```
BaseMatch/
├── Core/        テーマ、多言語、共通部品
├── Domain/      成績計算とアプリ状態（AppStore）
├── Models/      SwiftData モデル
└── Features/    画面（Home / Games / Stats / Settings）
```

MV（Model-View）パターンを採る。`@Observable` な `AppStore` を `@Environment` で配り、ViewModel は置かない。Apple の SwiftData サンプルと同じ構成。

## ビルドとテスト

```bash
xcodebuild -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build

xcodebuild test -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:BaseMatchTests
```

成績計算は仕様が細かいため、テストで固定してある（39件）。`Domain/StatsCalculator.swift` を触るときは必ずテストを通すこと。

## CI/CD

- **CI**: PR ごとにビルドとテスト（`.github/workflows/ci-main.yml`）
- **Guards**: 機密情報の混入と依存方向を検査（`.github/workflows/guards.yml`）
- **CD**: main への push で TestFlight へ配信（`.github/workflows/cd-testflight.yml`）

証明書は fastlane match で管理する。

fastlane をローカルで動かすには Team ID が要る。CI では GitHub Secrets から供給される。

```bash
echo 'FASTLANE_TEAM_ID=<Apple Developer の Team ID>' > .env
```

## ドキュメント

| ファイル | 内容 |
|---|---|
| [docs/MIGRATION_SPEC.md](docs/MIGRATION_SPEC.md) | Flutter 版からの移行仕様。成績計算ロジックの詳細 |
| [docs/DESIGN_SPEC.md](docs/DESIGN_SPEC.md) | UI デザイン方針とカラー定義 |
| [docs/SCREENSHOTS.md](docs/SCREENSHOTS.md) | App Store 掲載画像の作り方 |
| [PRIVACY.md](PRIVACY.md) | プライバシーポリシー（アプリ内からリンクしている） |

## ライセンス

MIT
