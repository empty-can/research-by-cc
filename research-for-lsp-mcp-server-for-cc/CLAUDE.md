# CLAUDE.md — LSP連携 MCP Server 調査

## 調査の目的

GitHub 上で公開されている **LSP（Language Server Protocol）連携型の MCP Server** を探索し、Claude Code から Java / Spring Boot / Gradle の言語サーバに接続して開発体験を向上させる候補を特定する。

有力候補に対しては脆弱性リスクを評価し、実際に試用・導入できるものを絞り込む。

## 対象言語・優先順位

1. **Java**（最優先）
2. **Spring Boot**（Java エコシステム内での優先度高）
3. **Gradle**（ビルドツール連携として）

> **重要な再フレーム（先行調査 2026-06-21 で確定）**: 「Java / Spring Boot / Gradle の MCP Server」が個別に存在するのではなく、実態は **汎用 LSP→MCP ブリッジ + 言語サーバ本体（jdt.ls 等）** の組み合わせが主流。よって優先順位は **評価軸** として適用する:
> - **Java** = jdt.ls（Eclipse JDT Language Server）対応の成熟度（必達軸）
> - **Spring Boot / Gradle** = 「汎用ブリッジに spring-boot-language-server / Gradle LS(BSP) を接続できるか」を**対応可否**として評価。専用 MCP Server はほぼ存在しないと見込まれ、存在確認自体を調査タスクとして格上げ済み

## MCP Server のアーキテクチャ3分類（A / B / C）

先行調査で確定した、本調査における候補の分類軸。fan-out の担当角度・マージ・最終評価はこの3分類を前提とする。

| 分類 | 定義 | 代表例 |
|---|---|---|
| **カテゴリ A** | **汎用 LSP→MCP ブリッジ**。任意の言語サーバに接続。Java は jdt.ls を指す | `jonrad/lsp-mcp` / `ProfessioneIT/lsp-mcp-server` / `rockerBOO/mcp-lsp-bridge` / `isaacphi/mcp-language-server` ほか |
| **カテゴリ B** | **特定 LSP のラッパー**（特に jdt.ls 特化）。Java 最優先文脈で最重要 | `stephanj/LSP4J-MCP` / `sunix/java-lsp-mcp-server` |
| **カテゴリ C** | **LSP 非依存・自己完結型コードインテリジェンス**。言語サーバを起動せず tree-sitter / libclang / ctags / 自前インデックスで symbol 抽出・検索・解析を内包。LSP の成果を近似するが意味解析の深さは LSP に劣る | `johnhuang316/code-index-mcp`（tree-sitter + ripgrep + 自前 index、LSP クライアント皆無） |

**カテゴリ C の扱い（案1: 比較併走）**: 本調査の主対象は LSP 連携型（A / B）。C は定義上スコープ外だが、「jdt.ls 等の重い言語サーバを起動せず同等の開発支援を得る現実的な競合」として**別枠で少数を追跡**し、最終リスク評価で「LSP型 vs 非LSP型」の対比材料とする。

## 評価基準（候補絞り込みに使う指標）

有力候補の条件（すべて満たすことが望ましい）:

- GitHub スター数が相対的に多い（同カテゴリ内で上位）
- 最終リリースまたは最終コミットが 6 ヶ月以内（2025-12-21 以降）
- セキュリティ関連 Issue が放置されていない（クローズ済みか、未報告）
- `package.json` / `go.mod` / `requirements.txt` 等の依存関係に既知の重大脆弱性がない

## タスク構成と進捗

- [ ] **01. 候補調査**
  - [x] 先行ランドスケープ確認（2026-06-21・メイン直接実施）— A/B/C 3分類の確定、code-index-mcp=C 判定
  - [x] `01.GitHub検索` — Sonnet subagent 5本で総当たり（角度別 A〜E）→ `候補一覧.md` に統合完了（A:18 / B-Java:4 / B-他言語:4 / C:7）。一次スクリーニング + Phase 2 推奨ショートリスト整理済み
    - Agent A: 汎用ブリッジ網羅 / Agent B: Java特化深掘り（最優先）/ Agent C: Spring Boot・Gradle 対応可否 / Agent D: MCP レジストリ横断 / Agent E: カテゴリC（非LSP型）少数列挙
  - [x] `02.評価マトリクス作成` — 「jdt.ls適合×保守」重視＋カテゴリC統合の方針で活発17件を採点・ランキング。Phase 2 対象10件（Primary 5 + Secondary 5）＋依存LSP本体スキャンを確定
- [x] **02. 脆弱性チェック**（対象10件）
  - [x] `01.依存関係スキャン` — ハイブリッド（Primary5=osv-scanner深掘り / Secondary5=軽量照合）。mcpls クリーン、serena 依存面最大、LSP本体も定性評価。テストフィクスチャ除外
  - [x] `02.Issue調査` — 全10件でセキュリティIssue放置なし。serena/code-index-mcp は対応姿勢良好
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
| 2026-06-21 | 先行ランドスケープ確認を反映。アーキテクチャ3分類（A/B/C）を定義、優先順位を評価軸へ再フレーム、code-index-mcp を C と判定。fan-out を 5 agent 構成に確定 |
