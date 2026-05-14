# クロスレビューに関する配布物

Claude Code を用いた作業で、成果物のクロスレビューを実施するための Rule・テンプレート・オーケストレーションスキルを一式提供する配布物。

## 同梱物一覧

| ファイル | 配置先 | 役割 |
|---|---|---|
| `.claude/rules/cross-review-runtime.md` | `<your-project>/.claude/rules/cross-review-runtime.md` | レビュー報告書・テンプレート編集時に自動ロードされる詳細運用仕様（セルフレビュー上限・レビューア確認セクション仕様・指摘記載ルール・判断依頼サマリ・件数表運用）を集約する path-scoped rule |
| `.claude/templates/cross-review/README.md` | `<your-project>/.claude/templates/cross-review/README.md` | テンプレート 3 種の役割・使い方・指摘ラベル定義・レビューフロー・態度区分等の基本ルールを集約 |
| `.claude/templates/cross-review/論理整合性観点_template.md` | `<your-project>/.claude/templates/cross-review/論理整合性観点_template.md` | 論理整合性・カバレッジ十分性・調査目的との整合性・仮説の妥当性の観点でレビューするテンプレート（担当: Claude Opus） |
| `.claude/templates/cross-review/実用性観点_template.md` | `<your-project>/.claude/templates/cross-review/実用性観点_template.md` | 完了条件明瞭性・命名規則遵守・文書構造・検証パターン具体性の観点でレビューするテンプレート（担当: Claude Sonnet） |
| `.claude/templates/cross-review/作業指示者+人間読み手観点_template.md` | `<your-project>/.claude/templates/cross-review/作業指示者+人間読み手観点_template.md` | 人間読み手観点（AIスロップ・冗長・Specificity 三点セット・Devil's Advocate 等）・論理整合性・実用性を人間視点でレビューするテンプレート（担当: 作業指示者 or Claude Opus） |
| `.claude/skills/orchestrate/SKILL.md` | `<your-project>/.claude/skills/orchestrate/SKILL.md` | 複数 Sub-agent を並列/順次協調させるオーケストレーションスキル（論理整合性・実用性レビューの並列実行に使用） |

## 導入手順

1. **ファイル配置**: 上表「配置先」のとおり、`.claude/` 配下に各ファイルをコピー
2. **動作確認**:
   - `orchestrate` Skill が認識される
   - レビュー報告書ファイル（`**/レビュー/**/*.md`）またはテンプレートを Claude が読む際に `cross-review-runtime.md` が自動ロードされる
3. **テンプレート使用**: `.claude/templates/cross-review/README.md` の「使い方」セクションを参照

## ファイル間の依存関係

- `cross-review-runtime.md` は path-scoped rule。`paths: ["**/レビュー/**/*.md", ".claude/templates/cross-review/*.md"]` を条件として自動ロードされ、テンプレート 3 種の詳細運用仕様（セルフレビュー上限・レビューア確認セクション・指摘記載ルール等）を提供する
- `orchestrate` Skill は Opus / Sonnet 並列レビュー（パターン A: 並列調査）に使用。論理整合性テンプレートと実用性テンプレートを同時に Claude に実施させる際に呼び出す
- テンプレート 3 種はそれぞれ独立して使用可能。必要な観点のみ取り込んでも動作する

## カスタマイズの観点

- **`cross-review-runtime.md` の `paths:` 調整**: レビュー報告書を `**/レビュー/**/*.md` 以外のパスに配置する場合は `paths:` を調整する。過剰ロード（不要シーンでの context 消費）が観測された場合は逆に絞る
- **担当レビュアーのモデル選定**: テンプレートのメタ情報テーブル（「レビュアー」行）に記載のモデルは推奨設定。チームの運用に合わせて変更可能
- **「作業指示者」表現**: チーム内のタスクオーナー・依頼者を指す。社内文化に応じて「ユーザー」「依頼者」等に置換可
- **テンプレートの観点取捨選択**: 各テンプレートのレビュー観点はレビュー対象に応じてスキップ可能。スキップ方法は `.claude/templates/cross-review/README.md` の「レビュー観点の取捨選択」を参照

## 公式リファレンス

- `code.claude.com/docs/en/permissions`
- `code.claude.com/docs/en/permission-modes`
- `code.claude.com/docs/en/sub-agents`

## 変更履歴

- 2026-05-14 版（初版）
