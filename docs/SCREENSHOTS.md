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
