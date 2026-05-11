#!/bin/bash
# .claude/scripts/resolve-activity-dir.sh
#
# 現在の Git ブランチから活動フォルダのリポジトリルートからの相対パスを決定論的に解決する。
# ルート CLAUDE.md「ブランチ運用ルール」に従う:
#   - 現ブランチが feature/<X> または feature/<X> の派生サブブランチ → research-for-<X>/
#   - 現ブランチが main、または先祖に feature/<X> が存在しない        → ./
#
# 標準出力には末尾スラッシュ付きの相対パスを 1 行で出力する。

set -euo pipefail

# 1. 現ブランチが feature/<X> 自身か判定
current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ "$current" == feature/* ]]; then
    theme="${current#feature/}"
    echo "research-for-${theme}/"
    exit 0
fi

# 2. 先祖ブランチの中から feature/<X> を探す
#    現ブランチ HEAD を含む feature/* を列挙し、HEAD からのコミット差が最小のものを採用
best_theme=""
best_distance=-1
while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    # ref が HEAD の祖先かを判定（祖先 = HEAD がそのブランチに含まれる）
    if git merge-base --is-ancestor "$ref" HEAD 2>/dev/null; then
        distance=$(git rev-list --count "${ref}..HEAD" 2>/dev/null || echo "999999")
        if [[ "$best_distance" -lt 0 || "$distance" -lt "$best_distance" ]]; then
            best_distance="$distance"
            best_theme="${ref#feature/}"
        fi
    fi
done < <(git for-each-ref --format='%(refname:short)' refs/heads/feature/ 2>/dev/null)

if [[ -n "$best_theme" ]]; then
    echo "research-for-${best_theme}/"
else
    echo "./"
fi
