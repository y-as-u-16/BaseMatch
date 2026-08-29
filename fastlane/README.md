fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios next_build_number

```sh
[bundle exec] fastlane ios next_build_number
```

TestFlight の最新ビルド番号 + 1 を返す

ビルド番号は CI の実行回数から採らない。re-run で値が変わらず、

同じ番号で再アップロードして必ず弾かれるため。

### ios setup_certificates

```sh
[bundle exec] fastlane ios setup_certificates
```

証明書とプロファイルを新規作成して certificates リポジトリへ保存する

ローカルの Mac で最初に一度だけ実行する。CI は readonly のため作成できない。

### ios beta

```sh
[bundle exec] fastlane ios beta
```

TestFlight へ配信する

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

掲載情報とスクリーンショットを App Store Connect へアップロードする

審査には提出しない。内容を確認してから ASC の画面で提出すること。

### ios upload_screenshots_only

```sh
[bundle exec] fastlane ios upload_screenshots_only
```

スクリーンショットだけを更新する（掲載テキストは触らない）

ASC 側に古い枚数が残っていると重複するため、先に画面から全削除しておくこと。

### ios upload_text_only

```sh
[bundle exec] fastlane ios upload_text_only
```

掲載テキストだけを更新する（スクショは触らない）

文言の微調整を繰り返すときはこちらが速い。

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
