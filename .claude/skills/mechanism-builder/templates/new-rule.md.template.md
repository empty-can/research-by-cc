---
# 以下は path-scoped 自動ロードしたい場合のみ設定:
# paths:
#   - "{{glob-pattern-1}}"           # 例: "src/**/*.ts"、"**/*.py"
#   - "{{glob-pattern-2}}"
---

# {{Rule のタイトル}}

{{Rule の適用範囲と目的を 1〜2 段落で}}

## 1. {{ルールの章 1}}

- {{ルール内容}}

## 2. {{ルールの章 2}}

- {{ルール内容}}

## 関連参照

- {{関連リンク}}

<!--
雛型使用上の注意:
- Rule は単一ファイル前提（補助ファイルを伴う場合は Skill 化を検討）
- `paths:` を設定しない場合、毎セッションロードされる
- ファイル名は `{{rule-name}}.md` のような kebab-case を推奨
- 配置先: `.claude/rules/<rule-name>.md`
- 公式仕様: code.claude.com/docs/en/memory#path-specific-rules
-->
