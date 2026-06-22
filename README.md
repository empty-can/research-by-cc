# research-by-cc

Claude Code を利用した様々な調査を行うためのリポジトリ。

## 構成

```
CLAUDE.md                       # Claude へのプロジェクト説明（毎セッション自動ロード）
CLAUDE.local.md.example         # 個人用補足指示のテンプレート（コピーして CLAUDE.local.md として使用）
.mcp.json                       # リポジトリ単位の MCP サーバー設定（現状は空）
.gitignore                      # 個人ローカル設定・一時物・機密情報を除外
.env.example                    # 環境変数のサンプル（実値は .env に記載／gitignore 対象）
.claude/
├── settings.json               # チーム共有のパーミッション・hooks 設定
├── settings.local.json.example # 個人ローカル設定のテンプレート（コピーして settings.local.json として使用）
├── rules/
│   └── coding-standards.md     # path-scoped コーディング規約（コードファイル編集時のみロード）
├── skills/
│   ├── commit-and-pr/          # /commit-and-pr — コミット・プッシュ・PR 作成
│   ├── orchestrate/            # /orchestrate — マルチエージェント協調
│   ├── request-new-skill/      # /request-new-skill — Skill 作成依頼を起こす
│   └── review-skill-request/   # /review-skill-request — Skill 作成依頼をレビュー
├── agents/
│   └── code-reviewer.md        # code-reviewer エージェント
├── output-styles/
│   └── code-review.md          # コードレビュー出力フォーマット定義
└── templates/
    ├── skill-request/          # Skill 作成依頼書テンプレート（request/review フローで使用）
    └── cross-review/           # クロスレビュー報告書テンプレート（論理整合性 / 実用性 / 作業指示者レビュー）

research-for-xxx/               # XXX に関する調査用のフォルダ。調査対象ごとに作成する。
├── CLAUDE.md                     # research-for-xxx フォルダでの作業内容・調査目的・背景の説明（遅延ロード：そのフォルダでの作業指示を受けた時に初めてロード）
├── .claude/                      # その調査固有の Skill / 設定があれば（任意）
├── .mcp.json                     # その調査固有の MCP サーバー設定があれば（任意）
└── reports/                      # 調査の成果物の格納先
    └── <タスク名>/                   # 基本 2 階層構成（タスク → フェーズ）。命名規則の詳細は CLAUDE.md 参照
        └── <フェーズ名>/              # 順序を示す数値プレフィックスは先頭、日付はファイル名末尾の運用
```

## ルート `.claude/` に含まれるもの

### Skills（スラッシュコマンド）

| コマンド | 説明 |
|---|---|
| `/commit-and-pr` | 変更をコミットして PR を作成（明示呼び出し限定） |
| `/orchestrate` | 複数エージェントを協調させる（並列調査・段階的処理・役割分担） |
| `/request-new-skill` | 新しい Skill の作成依頼を開始する（依頼書テンプレを生成） |
| `/review-skill-request` | 記入済み Skill 作成依頼書をレビューする |

### Sub-agents

| エージェント | 説明 |
|---|---|
| `code-reviewer` | コード変更の品質・セキュリティ・保守性レビュー |

### Templates

| テンプレート | 説明 |
|---|---|
| `skill-request/` | Skill 作成依頼書（`/request-new-skill` ↔ `/review-skill-request` フローで使用） |
| `cross-review/` | クロスレビュー報告書 3 種（論理整合性 / 実用性 / 作業指示者レビュー）。各レビューエントリに作業指示者の態度表明テーブルを内蔵 |

### MCP サーバー

ルート `.mcp.json` は現状空であり、リポジトリ単位で必須の MCP サーバーは無い。
調査テーマ固有で必要な MCP サーバーは `research-for-xxx/.mcp.json` に定義する。

MCP サーバーの起動には Node.js（v18 以上）が必要。  
GitHub MCP を使う場合は `GITHUB_TOKEN` 環境変数（OS レベルで設定）が必要。

## 調査用フォルダ（research-for-xxx）一覧

既存の調査用フォルダの一覧と、その概要および配下の `CLAUDE.md` へのリンク。

| フォルダ | 概要 | CLAUDE.md |
|---|---|---|
| `research-for-claude-dir-sharing-governance/` | ポータブルな最小 `.claude/` を Marketplace のようにチーム共有・統制する仕組みの調査・設計（3 配布チャネルのマトリクス・実装テンプレート） | [CLAUDE.md](research-for-claude-dir-sharing-governance/CLAUDE.md) |
| `research-for-local-RAG-for-cc/` | Claude Code から利用するローカル RAG（OSS／商用利用無料プロダクトのみで構築）の調査・設計・フィジビリティ検証・有効性検証 | [CLAUDE.md](research-for-local-RAG-for-cc/CLAUDE.md) |

## 動作環境

- [Claude Code](https://claude.ai/code) CLI
- Node.js v18 以上（MCP サーバー用）
- Git

## ライセンス

[MIT](LICENSE)
