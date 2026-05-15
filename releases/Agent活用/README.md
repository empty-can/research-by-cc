# Agent 活用に関する配布物

Claude Code を用いた作業で、sub-agent / background Agent の活用方針・運用ルール・オーケストレーションスキルを一式提供する配布物。

## 同梱物一覧

| ファイル | 配置先 | 役割 |
|---|---|---|
| `agent-usage-guidelines-snippet.md` | （CLAUDE.md にコピペ） | Agent 委任の判断基準・活用パターン・モデル選定原則を定義 |
| `.claude/skills/orchestrate/SKILL.md` | `<your-project>/.claude/skills/orchestrate/SKILL.md` | 複数 Sub-agent を並列/順次協調させるオーケストレーションスキル（パターン A/B/C） |
| `.claude/rules/agent-permission-runtime.md` | `<your-project>/.claude/rules/agent-permission-runtime.md` | Agent 起動時の permission 事前準備・拒否発生時の標準復旧・既知の落とし穴を集約する path-scoped rule |

## 導入手順

1. **ファイル配置**: 上表「配置先」のとおり、`.claude/` 配下に各ファイルをコピー
2. **CLAUDE.md への追記**: `agent-usage-guidelines-snippet.md` 冒頭の HTML コメントを除いた本文を、利用者の CLAUDE.md（プロジェクトルート `CLAUDE.md` または `~/.claude/CLAUDE.md`）に追記
3. **動作確認**:
   - `orchestrate` Skill が認識される
   - Agent 関連ファイル（`.claude/agents/*.md` / `.claude/skills/*/SKILL.md`）の読み書き時に `agent-permission-runtime.md` が自動ロードされる

## ファイル間の依存関係

- 「Agent 活用ガイドライン」節は `orchestrate` Skill のパターン A/B/C を参照する。両方セットでの導入を推奨
- `agent-permission-runtime.md` の path-scoped 自動ロード対象: `.claude/agents/*.md` および `.claude/skills/*/SKILL.md`。利用者の運用に合わせて frontmatter の `paths:` を調整可能

## カスタマイズの観点

- **`agent-permission-runtime.md` の `paths:` 調整**: 計画書系ファイルでも本ルールを参照させたい場合は `paths:` に追加。過剰ロード（不要シーンでの context 消費）が観測された場合は逆に絞る
- **「作業指示者」表現**: チーム内のタスクオーナー・依頼者を指す。社内文化に応じて「ユーザー」「依頼者」等に置換可
- **モデル選定原則**: 「## モデル選定原則」の表は、チームの定常的なモデル運用に合わせて項目追加可

## 公式リファレンス

- `code.claude.com/docs/en/permissions`
- `code.claude.com/docs/en/permission-modes`
- `code.claude.com/docs/en/sub-agents`

## 変更履歴

- 2026-05-14 版（初版）
