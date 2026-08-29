# App Store 掲載画像の作り方

## 1. スクリーンショットを撮る

デモデータは `-seedDemoData` でアプリが自前で投入する。
表示言語に応じてチーム名・選手名も切り替わる（`DemoDataSeeder`）。

```bash
# 日本語
xcodebuild test -project BaseMatch.xcodeproj -scheme BaseMatch \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:BaseMatchUITests/ScreenshotTests \
  -testLanguage ja -testRegion JP -resultBundlePath /tmp/shots-ja.xcresult

# 英語
xcodebuild test ... -testLanguage en -testRegion US -resultBundlePath /tmp/shots-en.xcresult
```

xcresult から PNG を取り出す:

```bash
xcrun xcresulttool export attachments --path /tmp/shots-ja.xcresult --output-path /tmp/ex-ja
# manifest.json の suggestedHumanReadableName から目的のファイルを引く
```

## 2. キャッチコピーを合成する

```bash
swift tools/appstore/compose-screenshots.swift <srcDir> <outDir> <ja|en>
```

出力は 1320×2868（App Store 6.9インチ必須サイズ）。

## 3. App Store Connect へ登録する

### 認証情報

```bash
export APP_STORE_CONNECT_KEY_ID="..."
export APP_STORE_CONNECT_ISSUER_ID="..."
export APP_STORE_CONNECT_API_KEY="$(cat /path/to/AuthKey_XXXX.p8)"
```

### 掲載テキスト

```bash
bundle exec fastlane upload_text_only
```

### スクリーンショット

```bash
bundle exec ruby tools/appstore/sync_screenshots.rb
```

**fastlane の `deliver` は使わないこと。** `overwrite_screenshots` は削除直後に
アップロードを始めるため、ASC 側の反映が間に合わず「アップロードされていない」と
誤判定してリトライし、毎回二重に登録される。`sync_screenshots` オプションも beta
実装で、既存分があると `Retried uploading screenshots 0` のまま失敗する。

`tools/appstore/sync_screenshots.rb` は削除 → 0枚になるまで待機 →
アップロード → 検証を順に行うため、この問題が起きない。

## 素材の置き場所

| 対象 | 場所 | git |
|---|---|---|
| 掲載テキスト | `fastlane/metadata/` | 追跡する |
| スクリーンショット | `fastlane/screenshots/` | 除外（約10MB） |
| 審査担当者向け連絡先 | `fastlane/metadata/review_information/` | 除外（個人情報） |

スクショのマスターは `~/dev/personal/screen_shot/BaseMatch/` にも置いてある。

## ASC の画面でしか設定できないもの

fastlane では入らないため、初回は手で設定する。

- プライマリカテゴリ（スポーツ）
- コンテンツ配信権
- アプリのプライバシー（データを収集していません）
- 価格（無料）と配信国
- 年齢制限の質問票（すべて「なし」→ 4+）
- DSA トレーダーステータス（個人開発なら非トレーダー）
- ビルドの選択

※ 古いビルドが紐づいていると iPad のスクショを要求される。
  iPhone 専用化（`TARGETED_DEVICE_FAMILY = "1"`）以降のビルドを選ぶこと。
