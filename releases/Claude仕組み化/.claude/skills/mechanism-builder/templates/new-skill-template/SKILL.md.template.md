---
name: {{skill-name}}
description: {{何をするか + いつ使うか の一行説明。Claude の自動 invoke 判断材料}}
# 以下は必要に応じて設定:
# user-invocable: false              # /メニュー非表示にする場合（Claude のみ呼べる）
# disable-model-invocation: true    # ユーザーのみ呼べるようにする場合（副作用がある操作等）
# paths:                              # path-scoped 自動ロード
#   - "**/{{path-pattern}}/**"
# allowed-tools: Read Grep           # 事前承認するツール
# context: fork                       # subagent で実行する場合
# agent: Explore                      # fork モード時のエージェント種別
---

# {{Skill 名（日本語表記）}}

{{Skill の目的・概要を 1〜2 段落で}}

## 1. このSkillが提供するもの

- {{提供物 1}}
- {{提供物 2}}

## 2. いつ使うか

- {{ユースケース 1}}
- {{ユースケース 2}}

## 3. {{主要な章のタイトル（判断フロー / 実行手順 / 等）}}

{{本文}}

詳細は [references/{{detail-file}}.md](references/{{detail-file}}.md) を参照。

## 4. 実装ステップ

### 4.1 {{ステップ 1 のタイトル}}

1. {{手順 1}}
2. {{手順 2}}

### 4.2 {{ステップ 2 のタイトル}}

{{手順}}

## 5. 同梱テンプレート一覧

| ファイル | 用途 |
|---|---|
| `templates/{{template-name}}` | {{用途}} |

## 6. 関連参照

- {{関連リンク・公式ドキュメント URL 等}}

## 変更履歴

- {{YYYY-MM-DD}} 版（初版）
