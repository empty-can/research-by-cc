#!/usr/bin/env bash
# generate-refactor-proposal.sh
#
# mechanism-builder Skill のリファクタリングモード用ヘルパースクリプト。
# 既存 Skill / Rule のバリデーションと、提案ファイル生成を担う。
#
# 使い方:
#   validate モード（対象の存在チェック）:
#     ./generate-refactor-proposal.sh validate <target-name>
#
#   generate モード（提案ファイル生成）:
#     ./generate-refactor-proposal.sh generate <target-name> <analysis-md-path>
#
# <target-name> の形式:
#   - <name>             — 自動解決（Skill / Rule のいずれか 1 件にマッチ。両方存在なら ambiguous エラー）
#   - skill:<name>       — Skill に限定
#   - rule:<name>        — Rule に限定
#
# stdout 出力: JSON（status / type / path / output / message を含む）
# exit code: 0 = 成功、1 = バリデーションエラー、2 = 引数エラー

set -euo pipefail

# --- パス解決 -----------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/ → mechanism-builder/ → skills/ → .claude/ → project root
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SKILLS_DIR="$PROJECT_ROOT/.claude/skills"
RULES_DIR="$PROJECT_ROOT/.claude/rules"
WORKSPACE_DIR="$PROJECT_ROOT/.claude/workspace/mechanism-builder"
TEMPLATE="$SCRIPT_DIR/../templates/refactor-proposal.md.template.md"

# --- ユーティリティ ----------------------------------------------------------

# JSON エスケープ（最小限: " と \ のみ。本スクリプトの値は ASCII path 主体）
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

emit_json() {
  # 引数: key1 val1 key2 val2 ...
  local out="{"
  local first=1
  while [[ $# -ge 2 ]]; do
    local k="$1"
    local v="$2"
    shift 2
    if [[ $first -eq 0 ]]; then out+=","; fi
    first=0
    out+="\"$(json_escape "$k")\":\"$(json_escape "$v")\""
  done
  out+="}"
  printf '%s\n' "$out"
}

# --- 対象解決 ----------------------------------------------------------------

resolve_target() {
  local raw="$1"
  local type_hint=""
  local name="$raw"

  case "$raw" in
    skill:*) type_hint="skill"; name="${raw#skill:}" ;;
    rule:*)  type_hint="rule";  name="${raw#rule:}"  ;;
  esac

  local skill_path="$SKILLS_DIR/$name"
  local rule_path="$RULES_DIR/$name.md"
  local skill_exists=0
  local rule_exists=0
  [[ -d "$skill_path" && -f "$skill_path/SKILL.md" ]] && skill_exists=1
  [[ -f "$rule_path" ]] && rule_exists=1

  case "$type_hint" in
    skill)
      if [[ $skill_exists -eq 1 ]]; then
        emit_json status "ok" type "skill" name "$name" path "$skill_path"
        return 0
      fi
      emit_json status "error" reason "skill_not_found" \
        message "Skill '$name' が見つかりません。.claude/skills/$name/SKILL.md が存在するか確認してください"
      return 1
      ;;
    rule)
      if [[ $rule_exists -eq 1 ]]; then
        emit_json status "ok" type "rule" name "$name" path "$rule_path"
        return 0
      fi
      emit_json status "error" reason "rule_not_found" \
        message "Rule '$name' が見つかりません。.claude/rules/$name.md が存在するか確認してください"
      return 1
      ;;
    "")
      if [[ $skill_exists -eq 1 && $rule_exists -eq 1 ]]; then
        emit_json status "error" reason "ambiguous" \
          message "同名の Skill と Rule が両方存在します。skill:$name または rule:$name と指定してください"
        return 1
      elif [[ $skill_exists -eq 1 ]]; then
        emit_json status "ok" type "skill" name "$name" path "$skill_path"
        return 0
      elif [[ $rule_exists -eq 1 ]]; then
        emit_json status "ok" type "rule" name "$name" path "$rule_path"
        return 0
      else
        emit_json status "error" reason "not_found" \
          message "'$name' が Skill / Rule のいずれにも見つかりません。タイポを確認するか、skill:<name> / rule:<name> 形式で明示してください"
        return 1
      fi
      ;;
  esac
}

# --- 分析 Markdown からセクション抽出 -----------------------------------------

# 使い方: extract_section <md-path> <section-key>
# md 内の "## <section-key>" 行から次の "## " 直前までを stdout に出力
extract_section() {
  local md="$1"
  local key="$2"
  awk -v key="$key" '
    BEGIN { in_section = 0 }
    /^## / {
      header = $0
      sub(/^## +/, "", header)
      if (header == key) {
        in_section = 1
        next
      } else if (in_section == 1) {
        in_section = 0
      }
    }
    in_section { print }
  ' "$md"
}

# --- テンプレ展開 ------------------------------------------------------------

# 環境変数経由で値を渡し、awk gsub で {{KEY}} を置換
render_template() {
  local out_file="$1"
  TPL_TARGET_NAME="$TARGET_NAME" \
  TPL_TARGET_TYPE="$TARGET_TYPE" \
  TPL_TARGET_PATH="$TARGET_PATH" \
  TPL_GENERATED_AT="$GENERATED_AT" \
  TPL_CURRENT_ANALYSIS="$CURRENT_ANALYSIS" \
  TPL_JUDGMENT_RESULT="$JUDGMENT_RESULT" \
  TPL_IMPROVEMENT_PROPOSAL="$IMPROVEMENT_PROPOSAL" \
  TPL_ALTERNATIVES="$ALTERNATIVES" \
  awk '
    function replace(line,    out) {
      out = line
      gsub(/\{\{TARGET_NAME\}\}/,         ENVIRON["TPL_TARGET_NAME"],         out)
      gsub(/\{\{TARGET_TYPE\}\}/,         ENVIRON["TPL_TARGET_TYPE"],         out)
      gsub(/\{\{TARGET_PATH\}\}/,         ENVIRON["TPL_TARGET_PATH"],         out)
      gsub(/\{\{GENERATED_AT\}\}/,        ENVIRON["TPL_GENERATED_AT"],        out)
      gsub(/\{\{CURRENT_ANALYSIS\}\}/,    ENVIRON["TPL_CURRENT_ANALYSIS"],    out)
      gsub(/\{\{JUDGMENT_RESULT\}\}/,     ENVIRON["TPL_JUDGMENT_RESULT"],     out)
      gsub(/\{\{IMPROVEMENT_PROPOSAL\}\}/,ENVIRON["TPL_IMPROVEMENT_PROPOSAL"],out)
      gsub(/\{\{ALTERNATIVES\}\}/,        ENVIRON["TPL_ALTERNATIVES"],        out)
      return out
    }
    BEGIN { in_comment = 0 }
    # HTML コメントブロックは出力スキップ（テンプレ内のプレースホルダー解説等を除外）
    /<!--/ {
      in_comment = 1
      if (/-->/) { in_comment = 0 }
      next
    }
    in_comment {
      if (/-->/) { in_comment = 0 }
      next
    }
    { print replace($0) }
  ' "$TEMPLATE" > "$out_file"
}

# --- メイン ----------------------------------------------------------------

main() {
  local cmd="${1:-}"
  local target="${2:-}"

  if [[ -z "$cmd" || -z "$target" ]]; then
    cat >&2 <<USAGE
Usage:
  $0 validate <target-name>
  $0 generate <target-name> <analysis-md-path>

<target-name> 形式: <name> | skill:<name> | rule:<name>
USAGE
    exit 2
  fi

  case "$cmd" in
    validate)
      resolve_target "$target"
      ;;
    generate)
      local analysis_md="${3:-}"
      if [[ -z "$analysis_md" ]]; then
        echo "generate モードには analysis-md-path が必要です" >&2
        exit 2
      fi
      if [[ ! -f "$analysis_md" ]]; then
        emit_json status "error" reason "analysis_not_found" \
          message "分析 Markdown が見つかりません: $analysis_md"
        exit 1
      fi
      if [[ ! -f "$TEMPLATE" ]]; then
        emit_json status "error" reason "template_not_found" \
          message "テンプレートが見つかりません: $TEMPLATE"
        exit 1
      fi

      # 対象解決
      local resolved
      if ! resolved=$(resolve_target "$target"); then
        printf '%s\n' "$resolved"
        exit 1
      fi

      # JSON から値を抽出（簡易: " で囲まれた値を取り出す。値に \" が含まれないことを前提）
      TARGET_TYPE=$(printf '%s' "$resolved" | sed -n 's/.*"type":"\([^"]*\)".*/\1/p')
      TARGET_PATH=$(printf '%s' "$resolved" | sed -n 's/.*"path":"\([^"]*\)".*/\1/p')
      TARGET_NAME=$(printf '%s' "$resolved" | sed -n 's/.*"name":"\([^"]*\)".*/\1/p')
      GENERATED_AT=$(date +%Y-%m-%dT%H:%M:%S)

      # 分析 Markdown からセクション抽出
      CURRENT_ANALYSIS=$(extract_section "$analysis_md" current_analysis)
      JUDGMENT_RESULT=$(extract_section "$analysis_md" judgment_result)
      IMPROVEMENT_PROPOSAL=$(extract_section "$analysis_md" improvement_proposal)
      ALTERNATIVES=$(extract_section "$analysis_md" alternatives)

      # 必須セクションの欠落チェック
      if [[ -z "${CURRENT_ANALYSIS//[[:space:]]/}" \
         || -z "${JUDGMENT_RESULT//[[:space:]]/}" \
         || -z "${IMPROVEMENT_PROPOSAL//[[:space:]]/}" \
         || -z "${ALTERNATIVES//[[:space:]]/}" ]]; then
        emit_json status "error" reason "section_missing" \
          message "分析 Markdown のセクションが不足しています。current_analysis / judgment_result / improvement_proposal / alternatives の全 ## ヘッダが必要です"
        exit 1
      fi

      # 出力先準備
      local out_dir="$WORKSPACE_DIR/$TARGET_NAME"
      mkdir -p "$out_dir"
      local out_file="$out_dir/proposal-$(date +%Y-%m-%d).md"

      # テンプレ展開
      render_template "$out_file"

      emit_json status "ok" output "$out_file" \
        target_name "$TARGET_NAME" target_type "$TARGET_TYPE" target_path "$TARGET_PATH"
      ;;
    *)
      echo "Unknown command: $cmd (expected 'validate' or 'generate')" >&2
      exit 2
      ;;
  esac
}

main "$@"
