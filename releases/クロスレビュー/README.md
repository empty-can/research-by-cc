# クロスレビューに関する配布物

Claude Code を用いた作業で、成果物のクロスレビューを実施するための Skill 一式を提供する配布物。3 観点（論理整合性・実用性・作業指示者+人間読み手）のレビュー報告書テンプレートと詳細運用仕様を Skill 統合構造として同梱。

## 同梱物一覧

| ファイル | 配置先 | 役割 |
|---|---|---|
| `.claude/skills/cross-review/SKILL.md` | `<your-project>/.claude/skills/cross-review/SKILL.md` | クロスレビュー Skill 入口。概観・使い方・基本ルール（指摘ラベル定義・態度区分・版数管理基本）。`paths:` でレビュー報告書編集時に自動ロード（`user-invocable: false`） |
| `.claude/skills/cross-review/references/runtime-rules.md` | 同左 | SKILL.md から参照される詳細運用仕様（セルフレビュー上限・レビューア確認セクション仕様・指摘記載ルール・判断依頼サマリ運用・件数表運用） |
| `.claude/skills/cross-review/templates/論理整合性観点_template.md` | 同左 | 論理整合性・カバレッジ十分性・調査目的との整合性・仮説の妥当性の観点でレビューするテンプレート（推奨担当: Claude Opus） |
| `.claude/skills/cross-review/templates/実用性観点_template.md` | 同左 | 完了条件明瞭性・命名規則遵守・文書構造・検証パターン具体性の観点でレビューするテンプレート（推奨担当: Claude Sonnet） |
| `.claude/skills/cross-review/templates/作業指示者+人間読み手観点_template.md` | 同左 | 人間読み手観点（AIスロップ・文章品質・Specificity 三点セット・Devil's Advocate 等）・論理整合性・実用性を人間視点でレビューするテンプレート（推奨担当: 作業指示者 or Claude Opus） |
| `.claude/skills/orchestrate/SKILL.md` | `<your-project>/.claude/skills/orchestrate/SKILL.md` | 複数 Sub-agent を並列/順次協調させるオーケストレーションスキル（論理整合性・実用性レビューの並列実行に使用） |

## 導入手順

1. **ファイル配置**: 上表「配置先」のとおり、`.claude/` 配下にディレクトリごとコピー
2. **動作確認**:
   - `cross-review` Skill が認識される
   - レビュー報告書ファイル（`**/レビュー/**/*.md`）またはクロスレビュー Skill 配下のファイルを Claude が読む際に SKILL.md が自動ロードされる
3. **テンプレート使用**: `.claude/skills/cross-review/SKILL.md` の「使い方」セクションを参照

## ファイル間の依存関係

- `SKILL.md` は Skill の入口。`user-invocable: false` のため `/` メニューには表示されず、frontmatter `paths:` に指定したパスのファイル編集時に自動ロードされる
- `references/runtime-rules.md` は SKILL.md 内のリンクから必要時のみ参照される詳細運用仕様（Progressive Disclosure）
- `templates/` 配下の 3 テンプレートはそれぞれ独立して使用可能。必要な観点のみ取り込んでも動作する
- `orchestrate` Skill は Opus / Sonnet 並列レビューに使用。論理整合性テンプレートと実用性テンプレートを同時に Claude に実施させる際に呼び出す

## カスタマイズの観点

- **`SKILL.md` の `paths:` 調整**: レビュー報告書を `**/レビュー/**/*.md` 以外のパスに配置する場合は `paths:` を調整する。過剰ロード（不要シーンでの context 消費）が観測された場合は逆に絞る
- **担当レビュアーのモデル選定**: テンプレートのメタ情報テーブル（「レビュアー」行）に記載のモデルは推奨設定。チームの運用に合わせて変更可能
- **「作業指示者」表現**: チーム内のタスクオーナー・依頼者を指す。社内文化に応じて「ユーザー」「依頼者」等に置換可
- **テンプレートの観点取捨選択**: 各テンプレートのレビュー観点はレビュー対象に応じてスキップ可能。スキップ方法は `.claude/skills/cross-review/SKILL.md` の「レビュー観点の取捨選択」を参照

## 公式リファレンス

- `code.claude.com/docs/en/skills`（Skill 仕様）
- `code.claude.com/docs/en/sub-agents`

## 変更履歴

- 2026-05-15 版（初版）
