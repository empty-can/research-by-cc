#!/bin/bash
# .claude/hooks/pre-task-reminder.sh
#
# UserPromptSubmit hook 用スクリプト。
# メインセッションでユーザーが新規プロンプトを送信した直後に発火し、
# Claude に対し「モデル妥当性」「/compact 要否」の 2 点確認を促す
# system-reminder を注入する。
#
# 設計方針:
# - UserPromptSubmit は仕様上メインセッションでのみ発火（sub-agent 内では発火しない、一次防御）
# - 注入文に「sub-agent ならスキップ」の防御文を含める（二次防御）
# - 参照 SKILL.md が存在しない場合は当該ブロックをサイレントに除外（graceful degradation）
#   ← plugin として配布する際など、skill が同梱されていない環境を想定
#   両方不在ならば何も注入せず正常終了。エラー・警告ログは一切出力しない。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK_MODEL_SKILL="${SCRIPT_DIR}/../skills/check-model/SKILL.md"
PRE_COMPACT_SKILL="${SCRIPT_DIR}/../skills/pre-compact/SKILL.md"

HAS_CHECK_MODEL=false
HAS_PRE_COMPACT=false
[[ -f "${CHECK_MODEL_SKILL}" ]] && HAS_CHECK_MODEL=true
[[ -f "${PRE_COMPACT_SKILL}" ]] && HAS_PRE_COMPACT=true

# 両方不在の場合は何も出力せず終了
if ! ${HAS_CHECK_MODEL} && ! ${HAS_PRE_COMPACT}; then
    exit 0
fi

# ヘッダ（共通）
cat <<'HEADER'
<system-reminder>
新規の作業指示を受けた場合、あるいはそれまでのコンテキストと比較し異なる観点や一段深いor浅い観点での質問を受けた場合、応答着手前に以下を確認すること。継続応答・clarification・軽微な確認ではこの限りでない（毎ターン繰り返しになるノイズを避けるため Claude が判断）。なお、あなたが sub-agent として呼び出されている場合は本確認をスキップする（sub-agent のモデル選定は親側で決定済みのため）。本確認プロセスの実行・スキップ・適合判定の事実はユーザーへの応答に一切言及しない。「要切替」判定が出た場合のみ、切替提案を応答に自然に含める。
HEADER

# モデル妥当性チェック（check-model SKILL.md が存在するときのみ）
if ${HAS_CHECK_MODEL}; then
    cat <<'CHECK_MODEL'

- **モデル妥当性チェック**: 現セッションのモデルが当該作業に対し過剰/不足でないかを確認する
  - 実施手段: Skill(skill="check-model") を呼び出して評価
  - 判定が「不適合」だった場合: skill の出力に従い、推奨モデルへの切替を作業指示者に提案
CHECK_MODEL
fi

# /compact 要否チェック（pre-compact SKILL.md が存在するときのみ）
if ${HAS_PRE_COMPACT}; then
    cat <<'PRE_COMPACT'

- **/compact 要否チェック**: 当該作業実施後に Context 使用率が 75% に到達する見込みがあるかを評価する
  - YES と判定した場合: 作業指示者に /compact 実行の提案を行う
  - 提案に合意が得られた時点で、事前準備として Skill(skill="pre-compact") を呼び出し、
    その出力（事前準備の実施 + /compact 引数コメント案）を作業指示者に提示する
PRE_COMPACT
fi

# フッタ（共通）
cat <<'FOOTER'
</system-reminder>
FOOTER
