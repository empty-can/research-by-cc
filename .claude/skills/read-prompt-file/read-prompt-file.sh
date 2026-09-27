#!/bin/bash
# .claude/skills/read-prompt-file/read-prompt-file.sh
#
# 活動フォルダ配下の .claude/work/prompt.txt のパスを解決し、存在を確認する。
# - 活動フォルダはルート CLAUDE.md「ブランチ運用ルール」に従い決定論的に解決する
# - prompt.txt が存在しない場合は、作成を促すメッセージを標準エラーに出力して
#   非ゼロ終了する（スクリプトは空ファイル作成も行わない）
# - prompt.txt が存在する場合は、リポジトリルートからの相対パスを標準出力に
#   1 行で返す（Skill 側はこれを cat -n で読み込んで利用する想定）

set -euo pipefail

ACTIVITY_DIR=$(bash "$(dirname "$0")/../../scripts/resolve-activity-dir.sh")
PROMPT_PATH="${ACTIVITY_DIR}.claude/work/prompt.txt"

if [[ ! -f "$PROMPT_PATH" ]]; then
    echo "ファイルが存在しません: ${PROMPT_PATH}" >&2
    echo "上記パスにファイルを作成してから、再度コマンドを実行してください。" >&2
    exit 1
fi

echo "$PROMPT_PATH"
