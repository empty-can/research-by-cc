#!/usr/bin/env bash
# clean-test-env.sh — クリーン隔離テスト環境を作って Claude Code を起動する（手順書 §5）
#
# 自分の ~/.claude / project 設定を切り離し、配布する <Share> の共有資産だけを検証する。
# 空の CLAUDE_CONFIG_DIR と、.claude / CLAUDE.md / .mcp.json を持たない空の作業ディレクトリを作り、
# <Share> を --add-dir / 環境変数 / --settings で結合して起動する。
#
# 使い方:
#   ./clean-test-env.sh [<Share-path>]
#     <Share-path> 省略時は結合なしの素のクリーンセッション（バイセクトの起点に使う）。
#   KEEP=1 ./clean-test-env.sh <Share>   # 終了後に一時ディレクトリを残す（既定は削除）
#
# 注意:
#   - managed settings は system パスにあるためクリーンセッションでも適用され続ける。
#   - Linux / Windows(WSL) では認証情報が config dir 配下のため再ログインを求められることがある
#     （macOS は Keychain 保管で引き継がれる）。
set -uo pipefail

SHARE="${1:-}"

CFG="$(mktemp -d -t cc-clean-cfg-XXXXXX)"
WORK="$(mktemp -d -t cc-clean-work-XXXXXX)"

cleanup() {
  if [[ "${KEEP:-0}" == "1" ]]; then
    echo "[clean-test-env] 一時ディレクトリを残しました: $CFG  $WORK"
  else
    rm -rf "$CFG" "$WORK"
    echo "[clean-test-env] 一時ディレクトリを削除しました（残すには KEEP=1）"
  fi
}
trap cleanup EXIT

echo "[clean-test-env] CLAUDE_CONFIG_DIR = $CFG"
echo "[clean-test-env] 作業ディレクトリ   = $WORK"

export CLAUDE_CONFIG_DIR="$CFG"
cli=()

if [[ -n "$SHARE" ]]; then
  if [[ ! -d "$SHARE" ]]; then echo "ERROR: <Share> が見つかりません: $SHARE" >&2; exit 1; fi
  SHARE_ABS="$(cd "$SHARE" && pwd)"
  cli+=(--add-dir "$SHARE_ABS")
  export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1   # CLAUDE.md / rules も結合
  echo "[clean-test-env] 結合: --add-dir $SHARE_ABS（+ CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1）"
  if [[ -f "$SHARE_ABS/.claude/settings.json" ]]; then
    cli+=(--settings "$SHARE_ABS/.claude/settings.json")  # settings.json は --add-dir で来ないので明示
    echo "[clean-test-env] 結合: --settings $SHARE_ABS/.claude/settings.json"
  fi
fi

echo "[clean-test-env] 起動中... (起動後は /memory /context /status /doctor /skills /agents で検証)"
cd "$WORK"
if [[ ${#cli[@]} -gt 0 ]]; then
  claude "${cli[@]}"
else
  claude
fi
