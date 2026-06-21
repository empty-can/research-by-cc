#!/usr/bin/env bash
# check-payload.sh — 配布する共有ペイロード <Share> を公開前に機械チェックする（手順書 §6）
#
# 「6. 落とし穴チェックリスト」のうちスクリプトで検査可能な項目を自動判定する。
# 対話 TUI が必要な項目（trust 承認・/memory・/status の確認など）は対象外（手順書 §6 を手で確認）。
#
# 使い方:  ./check-payload.sh <Share-path>
# 終了コード: FAIL が1件以上で 1、なければ 0（CI 利用可）。
set -uo pipefail

SHARE="${1:-}"
if [[ -z "$SHARE" || ! -d "$SHARE" ]]; then echo "使い方: $0 <Share-path>" >&2; exit 2; fi
SHARE="$(cd "$SHARE" && pwd)"

fail=0
pass(){ echo "  [PASS] $1"; }
bad(){  echo "  [FAIL] $1"; fail=1; }
warn(){ echo "  [WARN] $1"; }

echo "[check-payload] 対象: $SHARE"

# 1. 個人ファイル CLAUDE.local.md を共有ペイロードに含めない（参照側へ漏れる）
if [[ -e "$SHARE/CLAUDE.local.md" || -e "$SHARE/.claude/CLAUDE.local.md" ]]; then
  bad "CLAUDE.local.md が <Share> にある（個人ファイル・--add-dir+env で参照側へ漏れる）。削除する"
else
  pass "CLAUDE.local.md なし"
fi

# 2. settings.local.json を共有ペイロードに含めない（個人・非共有）
if [[ -e "$SHARE/.claude/settings.local.json" ]]; then
  bad ".claude/settings.local.json が <Share> にある（個人・非共有）。共有設定は settings.json へ"
else
  pass "settings.local.json なし"
fi

# 3. settings.json の JSON 構文 ＋ project/local で無視される security キーの検出
SETTINGS="$SHARE/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SETTINGS" >/dev/null 2>&1; then
      pass "settings.json は valid JSON"
    else
      bad "settings.json が不正な JSON（/doctor でも検出される）"
    fi
  fi
  hits=""
  grep -Eq '"defaultMode"[[:space:]]*:[[:space:]]*"auto"'  "$SETTINGS" && hits="$hits defaultMode:auto"
  grep -Eq '"skipDangerousModePermissionPrompt"'           "$SETTINGS" && hits="$hits skipDangerousModePermissionPrompt"
  grep -Eq '"autoMode"'                                    "$SETTINGS" && hits="$hits autoMode"
  grep -Eq '"useAutoModeDuringPlan"'                       "$SETTINGS" && hits="$hits useAutoModeDuringPlan"
  if [[ -n "$hits" ]]; then
    warn "project/local では無視される可能性のあるキー:$hits（効かせるなら ~/.claude/settings.json へ）"
  else
    pass "project/local 無視キーなし（settings.json）"
  fi
else
  warn "settings.json が無い（settings を共有しない構成なら問題なし）"
fi

# 4. 共通ルール CLAUDE.md の存在（情報）
if [[ -f "$SHARE/CLAUDE.md" || -f "$SHARE/.claude/CLAUDE.md" ]]; then
  pass "共通ルール CLAUDE.md あり"
else
  warn "CLAUDE.md（共通ルール）が無い（rules/ や skills のみ配る構成なら問題なし）"
fi

if [[ $fail -eq 0 ]]; then
  echo "[check-payload] 結果: 重大な問題なし（FAIL=0）"
else
  echo "[check-payload] 結果: FAIL あり。上記を修正してください"
fi
exit $fail
