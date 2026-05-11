#!/bin/bash
# .claude/skills/read-prompt-file/read-prompt-file.sh
#
# 活動フォルダ配下の .claude/work/clip.txt を準備してエディタで開く。
# - 活動フォルダはルート CLAUDE.md「ブランチ運用ルール」に従い決定論的に解決する
# - clip.txt が存在しない場合は空ファイルとして作成する
# - その後エディタで開く（Windows の既定アプリで Start-Process）
#
# 標準出力には clip.txt のリポジトリルートからの相対パスを 1 行で出力する。
# Skill 側はこれを cat -n で読み込んでコンテキストに取り込む想定。

set -euo pipefail

ACTIVITY_DIR=$(bash "$(dirname "$0")/../../scripts/resolve-activity-dir.sh")
WORK_DIR="${ACTIVITY_DIR}.claude/work"
CLIP_PATH="${WORK_DIR}/clip.txt"

mkdir -p "$WORK_DIR"
[[ -f "$CLIP_PATH" ]] || : > "$CLIP_PATH"

CLIP_PATH_WIN=$(cygpath -w "$(pwd)/$CLIP_PATH")
powershell.exe -command "Start-Process '$CLIP_PATH_WIN'" >/dev/null 2>&1 || true

echo "$CLIP_PATH"
