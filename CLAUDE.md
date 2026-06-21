# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの役割

**Claude Code を使って各種テーマを調査するためのワークスペース**であり、製品コードを置く場所ではない。中身は大きく 2 種類:

1. **チーム共有の Claude Code 設定** (`.claude/`) — 全調査で共通利用する skills / agents / rules / output-styles / templates / settings.json
2. **個別調査フォルダ** (`research-for-xxx/`) — 調査テーマ単位のサブプロジェクト。テーマ固有の `.claude/` / `.mcp.json` / `CLAUDE.md` を任意で持てる

## 個別調査フォルダの構造

新規テーマで `research-for-<テーマ>/` を切る時、その直下に置けるもの:

- `CLAUDE.md` — その調査の前提・目的・参照リソース（必須に近い）。**遅延ロード**: ルート直下のこのファイルは毎セッション自動ロードされるが、`research-for-xxx/` 配下の `CLAUDE.md` はそのフォルダ内のファイルを読んだ時に初めてロードされる。各調査の細かい背景はそこに書き、ルートには書かない
- `.claude/` / `.mcp.json` — そのテーマだけに必要な skill / 設定 / MCP（必要なら）。共通で使う設定はルート `.claude/` に入れ、重複させない
- `reports/` — **成果物の格納先**。配置・命名規則は `.claude/CLAUDE.md` 参照
- `README.md` — GitHub 閲覧者向けの公開ドキュメント。CLAUDE.md からの派生物として作成し、本質的な情報の真の出所は CLAUDE.md とする（二重管理を避ける）

## 進捗マーカー

進捗を記載するファイル（各 `CLAUDE.md` のタスク進行状況など）では:

- `- [ ]` 未着手 / `- [x]` 完了
- 中間状態は `(進行中)` / `(保留: <理由>)` をタスク名の後に注記

## 環境特性

- **OS**: Windows 11（プライマリ）。bash シェル経由で操作、パスは `C:\workspace\research-by-cc` 形式
- **Node.js v18+** — MCP サーバー起動用
- **MCP** — ルート `.mcp.json` は空。`anthropic-docs` / `context7` / `fetch` / `github` はユーザレベル（`~/.claude/`）で定義済み。GitHub MCP は `GITHUB_TOKEN`（OS レベル）が必要。テーマ固有 MCP は `research-for-xxx/.mcp.json` に追加
- **Git** — Git 化済み・GitHub 公開済み

## 運用ルールの所在

詳細な運用ルールは以下に分散している。CLAUDE.md 本体を軽く保つため、本ファイルには俯瞰と索引のみを置く（ルート `CLAUDE.md` と `.claude/CLAUDE.md` は同じ Project スコープで毎セッション自動ロードされる）。

| 知りたいこと | 参照先 |
|---|---|
| Claude Code 設定の操作（skill/agent 追加、settings 階層、hook、成果物の命名規則、rules 機構） | `.claude/CLAUDE.md` |
| 外部情報の調査経路（ローカル優先・llms.txt 戦略・MCP vs built-in） | `.claude/rules/research-source-routing.md` |
| Agent 委任判断・モデル選定 | `.claude/rules/agent-delegation.md` |
| コミット運用・`.gitignore` 方針 | `.claude/rules/git-workflow.md` |
| コードファイル編集規約（path-scoped） | `.claude/rules/coding-standards.md` |
| クロスレビュー実施 / Agent 権限事前準備（path-scoped） | `.claude/rules/cross-review-runtime.md` / `agent-permission-runtime.md` |
| 個人ローカル設定（マシン固有の実体パス等） | `CLAUDE.local.md`（`CLAUDE.local.md.example` をコピー） |

## よくある作業

| やりたいこと | 起点 |
|---|---|
| 既存調査の続き | `research-for-<テーマ>/CLAUDE.md` を読んでから着手 |
| 新規調査の開始 | `research-for-<新テーマ>/` を切り、`CLAUDE.md` と `reports/` を用意 |
| タスクの成果物作成 | `research-for-<テーマ>/reports/<タスク名>/<フェーズ名>/` を切ってその中で完結 |
| 共通 skill の追加 | `/request-new-skill` → `/review-skill-request` |
| 大規模変更後のレビュー | `code-reviewer` agent を呼ぶ（output-style: `code-review`） |
| 並列調査・段階処理 | `/orchestrate` を読んでパターン A/B/C を選ぶ |
