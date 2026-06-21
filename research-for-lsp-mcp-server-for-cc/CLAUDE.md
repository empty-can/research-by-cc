# CLAUDE.md — LSP連携 MCP Server 調査

## 調査の目的

GitHub 上で公開されている **LSP（Language Server Protocol）連携型の MCP Server** を探索し、Claude Code から Java / Spring Boot / Gradle の言語サーバに接続して開発体験を向上させる候補を特定する。

有力候補に対しては脆弱性リスクを評価し、実際に試用・導入できるものを絞り込む。

## 対象言語・優先順位

1. **Java**（最優先）
2. **Spring Boot**（Java エコシステム内での優先度高）
3. **Gradle**（ビルドツール連携として）

## 評価基準（候補絞り込みに使う指標）

有力候補の条件（すべて満たすことが望ましい）:

- GitHub スター数が相対的に多い（同カテゴリ内で上位）
- 最終リリースまたは最終コミットが 6 ヶ月以内（2025-12-21 以降）
- セキュリティ関連 Issue が放置されていない（クローズ済みか、未報告）
- `package.json` / `go.mod` / `requirements.txt` 等の依存関係に既知の重大脆弱性がない

## タスク構成と進捗

- [ ] **01. 候補調査**
  - [ ] `01.GitHub検索` — GitHub 検索・候補一覧の作成（スター数・最終リリース日・README 概要）
  - [ ] `02.評価マトリクス作成` — 評価基準に基づくスコアリングと絞り込み
- [ ] **02. 脆弱性チェック**
  - [ ] `01.依存関係スキャン` — 絞り込み候補の `package.json` 等を取得し既知 CVE を確認
  - [ ] `02.Issue調査` — セキュリティ関連 Issue の放置状況を確認
- [ ] **03. 総合評価・推奨**
  - [ ] `01.リスク評価まとめ` — リスク低の候補を推奨リストとして整理

## 成果物の格納先

```
research-for-lsp-mcp-server-for-cc/
└── reports/
    ├── 01.候補調査/
    │   ├── 01.GitHub検索/
    │   │   └── 候補一覧.md
    │   └── 02.評価マトリクス作成/
    │       └── 評価マトリクス.md
    ├── 02.脆弱性チェック/
    │   ├── 01.依存関係スキャン/
    │   │   └── スキャン結果.md
    │   └── 02.Issue調査/
    │       └── Issue調査結果.md
    └── 03.総合評価・推奨/
        └── 01.リスク評価まとめ/
            └── 推奨リスト.md
```

## 調査メモ・前提知識

### MCP Server と LSP の関係

- **MCP Server**: Claude Code が外部ツール・情報源と通信するための標準インターフェース
- **LSP**: IDE/エディタが言語サーバ（補完・定義ジャンプ・診断等を提供）と通信するプロトコル
- 両者を組み合わせた MCP Server は、Claude Code に「LSP 経由の言語情報」（型情報・シンボル・診断）を渡す役割を担う

### 検索キーワード（参考）

- GitHub: `mcp server lsp java`, `mcp language server`, `mcp java lsp`, `model context protocol language server`
- 関連ツール: `eclipse.jdt.ls`（Java Language Server）, `spring-boot-language-server`

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-06-21 | 初版作成（調査フォルダ・ブランチ新設） |
