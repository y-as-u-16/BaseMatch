#!/usr/bin/env bash
# レイヤーの依存方向を検査する。
# Models / Domain が UI に依存し始めると、ロジックを画面なしでテストできなくなる。
set -euo pipefail

cd "$(dirname "$0")/.."

status=0

fail() {
  echo "::error::$1"
  status=1
}

# Models と Domain は表示の都合から独立させる。
ui_in_domain=$(
  grep -ln 'import SwiftUI\|import UIKit' \
    BaseMatch/Models/*.swift BaseMatch/Domain/*.swift 2>/dev/null || true
)
if [ -n "$ui_in_domain" ]; then
  fail "Models / Domain が UI フレームワークに依存しています。"
  echo "$ui_in_domain"
fi

# Features 同士の相互参照は、画面をまたぐ密結合の入口になる。
# 共有したいものは Core か Domain へ引き上げる。
for dir in BaseMatch/Features/*/; do
  feature=$(basename "$dir")
  others=$(find BaseMatch/Features -maxdepth 1 -mindepth 1 -type d ! -name "$feature" -exec basename {} \;)
  for other in $others; do
    # 型名の衝突を避けるため、import ではなくファイル名由来の参照だけを見る。
    hits=$(grep -rn "${other}View\b" "$dir" 2>/dev/null | grep -v "^${dir}" || true)
    if [ -n "$hits" ]; then
      fail "Features/${feature} が Features/${other} を直接参照しています。"
      echo "$hits"
    fi
  done
done

if [ "$status" -eq 0 ]; then
  echo "依存方向に問題はありません。"
fi

exit "$status"
