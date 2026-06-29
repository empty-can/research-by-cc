#!/usr/bin/env bash
# check-assets.sh — 配布する共有ペイロード <Share> を公開前に機械チェックする（手順書 §6）
#
# 「6. 落とし穴チェックリスト」のうちスクリプトで検査可能な項目を自動判定する。
# 対話 TUI が必要な項目（trust 承認・/memory・/status の確認など）は対象外（手順書 §6 を手で確認）。
#
# 判定基準（README 隔離方式 / 案1 対応）:
#   <Share> が git リポジトリなら「Git 追跡されているか」で配布可否を判定する。
#     - 個人ファイルが tracked        → FAIL（clone に含まれ参照側へ漏れる）
#     - 個人ファイルが untracked で実在 → WARN（gitignore 済みで配布はされないが掃除推奨）
#     - 不在                          → PASS
#   git リポジトリでない（コピー展開した素のディレクトリ）なら、実在＝FAIL にフォールバックする
#   （ディレクトリごとコピーされるため実在がそのまま配布になる）。
#
# 使い方:  ./check-assets.sh <Share-path>
# 終了コード: FAIL が1件以上で 1、なければ 0（CI 利用可）。
set -uo pipefail

SHARE="${1:-}"
if [[ -z "$SHARE" || ! -d "$SHARE" ]]; then echo "使い方: $0 <Share-path>" >&2; exit 2; fi
SHARE="$(cd "$SHARE" && pwd)"

fail=0
pass(){ echo "  [PASS] $1"; }
bad(){  echo "  [FAIL] $1"; fail=1; }
warn(){ echo "  [WARN] $1"; }

# git リポジトリか判定
IS_GIT=0
if git -C "$SHARE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then IS_GIT=1; fi

is_tracked(){ git -C "$SHARE" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

# 個人ファイル（tracked=FAIL / untracked実在=WARN / 不在=PASS、非gitは実在=FAIL）を判定
check_personal(){
  local rel="$1" label="$2"
  if [[ $IS_GIT -eq 1 ]]; then
    if is_tracked "$rel"; then
      bad "$label が Git 追跡されている（clone に含まれ参照側へ漏れる）。git rm --cached して .gitignore へ"
    elif [[ -e "$SHARE/$rel" ]]; then
      warn "$label が実在するが未追跡（配布はされない。掃除推奨）"
    else
      pass "$label なし"
    fi
  else
    if [[ -e "$SHARE/$rel" ]]; then
      bad "$label がある（非 git のためコピー展開でそのまま配布される）。削除する"
    else
      pass "$label なし"
    fi
  fi
}

echo "[check-assets] 対象: $SHARE（$([[ $IS_GIT -eq 1 ]] && echo 'git リポジトリ: 追跡基準' || echo '非 git: 実在基準')）"

# 1. 個人ファイル CLAUDE.local.md（--add-dir+env で参照側へ漏れる）
check_personal "CLAUDE.local.md"        "CLAUDE.local.md"
check_personal ".claude/CLAUDE.local.md" ".claude/CLAUDE.local.md"

# 2. settings.local.json（個人・非共有。共有設定は settings.json へ）
check_personal ".claude/settings.local.json" ".claude/settings.local.json"

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

# 4. 共有共通ルールの所在（案1 では .claude/CLAUDE.md。ルート CLAUDE.md は README 隔離の対象）
if [[ -f "$SHARE/.claude/CLAUDE.md" ]]; then
  pass "共有共通ルール .claude/CLAUDE.md あり（案1 構成）"
elif [[ -f "$SHARE/CLAUDE.md" ]]; then
  warn "共有ルールがルート CLAUDE.md にある。案1（README 隔離）では .claude/CLAUDE.md へ移し、リポ固有情報は README.md へ"
else
  warn "共有共通ルール（.claude/CLAUDE.md）が無い（rules/ や skills のみ配る構成なら問題なし）"
fi

# 5. （案1 情報）ルート CLAUDE.md が tracked なら --add-dir+env で参照側へ漏れる旨を通知
if [[ $IS_GIT -eq 1 ]] && is_tracked "CLAUDE.md"; then
  warn "ルート CLAUDE.md が Git 追跡されている。--add-dir + CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 で参照側にロードされる点に注意（リポ固有情報を含めない）"
fi

if [[ $fail -eq 0 ]]; then
  echo "[check-assets] 結果: 重大な問題なし（FAIL=0）"
else
  echo "[check-assets] 結果: FAIL あり。上記を修正してください"
fi
exit $fail
