# 執筆ガイドラインに関する配布物

Claude Code を用いた作業で、成果物の執筆品質を高めるための予防的ガイドライン Skill を提供する配布物。計画書・調査報告書・レビュー報告書・改訂提案の各ドキュメント種別に対応した、構造設計・執筆中・完成前セルフチェック 3 フェーズの観点を整理。

## 同梱物一覧

| ファイル | 配置先 | 役割 |
|---|---|---|
| `writing-guideline-snippet.md` | （CLAUDE.md にコピペ） | 執筆ガイドライン参照ルールの CLAUDE.md 追記用文言 |
| `.claude/skills/writing-guideline/SKILL.md` | `<your-project>/.claude/skills/writing-guideline/SKILL.md` | Skill 入口。`paths:` 指定でドキュメント編集時に自動ロード（`user-invocable: false`） |
| `.claude/skills/writing-guideline/references/common/01_構造設計編.md` | 同左 | 全種別共通・構造設計フェーズの観点（G1-1〜G1-4） |
| `.claude/skills/writing-guideline/references/common/02_執筆中編.md` | 同左 | 全種別共通・執筆中フェーズの観点（G2-1〜G2-8） |
| `.claude/skills/writing-guideline/references/common/03_完成前セルフチェック編.md` | 同左 | 全種別共通・完成前セルフチェックの観点（G3-1〜G3-11） |
| `.claude/skills/writing-guideline/references/計画書.md` | 同左 | 計画書固有の追加観点 |
| `.claude/skills/writing-guideline/references/調査報告書.md` | 同左 | 調査報告書・統合報告書固有の追加観点 |
| `.claude/skills/writing-guideline/references/レビュー報告書.md` | 同左 | レビュー報告書固有の追加観点（クロスレビュー資産との連携情報含む） |
| `.claude/skills/writing-guideline/references/改訂提案.md` | 同左 | 改訂提案・運用考察ドキュメント固有の追加観点 |
| `.claude/skills/writing-guideline/references/執筆者見解レポート.md` | 同左 | 執筆完了後に執筆者が別ファイルとして作成する見解レポートの仕様 |

## 導入手順

1. **ファイル配置**: 上表「配置先」のとおり、`.claude/` 配下に各ファイルをコピー
2. **CLAUDE.md への追記**: `writing-guideline-snippet.md` 冒頭の HTML コメントを除いた本文を、利用者の CLAUDE.md（プロジェクトルートまたはサブフォルダ）に追記
3. **動作確認**: 報告書ファイル（`**/reports/**/*.md` 等）を Claude が読み書きする際に `SKILL.md` が自動ロードされることを確認

## ファイル間の依存関係

- `SKILL.md` は Skill の入口。`user-invocable: false` のため `/` メニューには表示されず、frontmatter `paths:` に指定したパスのファイルを編集する際に自動ロードされる
- `references/common/` 配下 3 ファイルは全ドキュメント種別で共通。各種別ファイルと組み合わせて参照する
- `references/<種別>.md` はそれぞれ独立して使用可能。必要な種別のみ取り込んでも動作する
- `references/レビュー報告書.md` はクロスレビューテンプレート（`.claude/templates/cross-review/`）への参照を含む。クロスレビュー資産（配布物「クロスレビュー」）と組み合わせて使用することを推奨

## カスタマイズの観点

- **`SKILL.md` の `paths:` 調整**: 報告書が `**/reports/**/*.md` 以外のパスに配置される場合は frontmatter の `paths:` を調整する。過剰ロード（不要シーンでの context 消費）が観測された場合は逆に絞る
- **`improvements/**` パスの要否**: `paths:` の `**/improvements/**/*.md` は改善提案ファイル向け。プロジェクトで `improvements/` フォルダを使わない場合は削除してよい
- **「作業指示者」表現**: チーム内のタスクオーナー・依頼者を指す。社内文化に応じて「ユーザー」「依頼者」等に置換可

## 公式リファレンス

- `code.claude.com/docs/en/claude-code/skills`（Skill 仕様）

## 変更履歴

- 2026-05-15 版（初版）
