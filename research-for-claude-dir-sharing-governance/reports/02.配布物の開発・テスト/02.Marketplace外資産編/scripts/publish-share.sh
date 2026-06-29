#!/usr/bin/env bash
# publish-share.sh — <Dev> の指定 ref の .claude を共有本体 <Share.claude> へ publish（パターンB・Sync A・手動ゲート）
#
# session 開始時の自動同期（refresh / pull --ff-only）とは別物。release-ready な .claude を
# 共有本体へ反映する意図的な公開操作で、publish はここでしか push しない。
# publish 対象は ref で指定（既定 main＝公開基準）。checkout 不要で任意 ref を publish できる。
#
# 使い方:
#   ./scripts/publish-share.sh --share <Share.claude のローカルパス> [--ref <ref>]
#     --share  共有本体（<Share.claude>）クローンのパス（必須）
#     --ref    publish する .claude の取り出し元 ref（既定: main）
# 例:
#   ./scripts/publish-share.sh --share /path/to/share-claude               # main を publish
#   ./scripts/publish-share.sh --share /path/to/share-claude --ref develop # 指定ブランチを publish
# 終了コード: ゲート失敗・エラーで非0。
set -uo pipefail

REF="main"
SHARE_BODY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --ref)   REF="${2:?--ref に値が必要}"; shift 2;;
    --share) SHARE_BODY="${2:?--share に値が必要}"; shift 2;;
    *) echo "‼ 不明な引数: $1（使い方: $0 --share <path> [--ref <ref>]）" >&2; exit 2;;
  esac
done
[ -n "$SHARE_BODY" ] || { echo "‼ --share <Share.claude のパス> が必要" >&2; exit 2; }

DEV_ROOT="$(git rev-parse --show-toplevel)"
HERE="$(cd "$(dirname "$0")" && pwd)"

[ -d "$SHARE_BODY/.git" ] || { echo "‼ 共有本体（<Share.claude> のクローン）が見つからない: $SHARE_BODY" >&2; exit 2; }
git -C "$DEV_ROOT" rev-parse --verify "$REF^{commit}" >/dev/null 2>&1 || { echo "‼ ref が存在しない: $REF" >&2; exit 2; }

# 1. 追跡ファイルのみを ref から取り出し（checkout 不要・個人/未追跡は構造的に除外）
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git -C "$DEV_ROOT" archive "$REF" .claude | tar -x -C "$tmp"   # → $tmp/.claude/

# 2. 安全弁: 取り出した .claude が空なら中止（共有本体の空上書きを防止）
[ -d "$tmp/.claude" ] && [ -n "$(ls -A "$tmp/.claude" 2>/dev/null)" ] || {
  echo "‼ $REF の .claude が空。publish 中止（共有本体を空で上書きしない）" >&2; exit 1; }

# 3. 衛生ゲート: check-assets を「取り出した実体」に対して実行（実際に publish する中身を検査）
bash "$HERE/check-assets.sh" "$tmp" || { echo "‼ check-assets FAIL。publish 中止" >&2; exit 1; }

# 4. /security-review は対話コマンドのため手動確認
read -r -p "→ $REF の内容について /security-review を実行済みなら y で続行: " ok
[ "$ok" = "y" ] || { echo "中止"; exit 1; }

# 5. 共有本体へミラー（メタ .git/README/LICENSE/.gitignore は残し、資産だけを総入れ替え）
find "$SHARE_BODY" -mindepth 1 -maxdepth 1 \
  ! -name '.git' ! -name '.gitignore' ! -name 'README.md' ! -name 'LICENSE' \
  -exec rm -rf {} +
cp -R "$tmp/.claude/." "$SHARE_BODY/"

# 6. 共有本体を commit & push
git -C "$SHARE_BODY" add -A
if git -C "$SHARE_BODY" diff --cached --quiet; then echo "変更なし。publish 不要"; exit 0; fi
git -C "$SHARE_BODY" commit -m "publish: sync .claude from <Dev>@$(git -C "$DEV_ROOT" rev-parse --short "$REF") (ref: $REF)"
git -C "$SHARE_BODY" push

echo "✓ publish 完了（ref: $REF）。雛型リポジトリ <Share> で submodule を bump してください:"
echo "    git -C <Share> submodule update --remote .claude"
echo "    git -C <Share> add .claude && git -C <Share> commit -m 'chore: bump .claude' && git -C <Share> push"
