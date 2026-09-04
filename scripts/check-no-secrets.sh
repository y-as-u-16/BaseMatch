#!/usr/bin/env bash
# 公開してはいけない値がコミットに混ざっていないか検査する。
# Xcode は自動署名のたびに project.pbxproj へ Team ID を書き戻すため、
# 人の注意では防げない。CI で毎回見る。
set -euo pipefail

cd "$(dirname "$0")/.."

status=0

fail() {
  echo "::error::$1"
  status=1
}

# Apple Developer の Team ID は 10 桁の英数字。
# 実値を書くとこのスクリプト自身が検出対象になるため、形で拾う。
team_id_hits=$(
  grep -rnE 'DEVELOPMENT_TEAM = [A-Z0-9]{10};|team_id\("[A-Z0-9]{10}"\)|TEAM_ID = "[A-Z0-9]{10}"' \
    --include='*.pbxproj' --include='Appfile' --include='Matchfile' --include='Fastfile' \
    . 2>/dev/null || true
)
if [ -n "$team_id_hits" ]; then
  fail "Team ID がハードコードされています。pbxproj は \"\" に、fastlane は ENV.fetch(\"FASTLANE_TEAM_ID\") にしてください。"
  echo "$team_id_hits"
fi

# 実メールアドレスが公開コミットに残らないようにする。
# noreply.github.com は公開前提のため除く。
email_hits=$(
  grep -rnE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' \
    --include='*.swift' --include='*.pbxproj' --include='*.yml' --include='*.md' \
    --exclude-dir=.git . 2>/dev/null \
    | grep -v 'noreply' \
    | grep -v 'example\.com' \
    | grep -v 'users\.noreply\.github\.com' || true
)
if [ -n "$email_hits" ]; then
  fail "メールアドレスらしき文字列が含まれています。公開してよい値か確認してください。"
  echo "$email_hits"
fi

# Xcode がテンプレートから生成するヘッダーには作者の実名が入る。
author_hits=$(
  grep -rn '^//  Created by' --include='*.swift' . 2>/dev/null || true
)
if [ -n "$author_hits" ]; then
  fail "Xcode 生成のヘッダーコメントが残っています。冒頭の // ブロックごと削除してください。"
  echo "$author_hits"
fi

if [ "$status" -eq 0 ]; then
  echo "機密情報の混入は見つかりませんでした。"
fi

exit "$status"
