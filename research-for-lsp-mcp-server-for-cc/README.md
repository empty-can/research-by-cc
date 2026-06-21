# LSP連携型 MCP Server 調査

Claude Code から言語サーバ（**優先: Java > Spring Boot > Gradle**）に接続する、GitHub 公開の **LSP（Language Server Protocol）連携型 MCP Server** を探索し、脆弱性を含むリスクの小さい採用候補を絞り込んだ調査記録です。

> このドキュメントは公開閲覧者向けの概要です。背景・前提・運用ルールの一次情報は `CLAUDE.md`、詳細な成果物は `reports/` を参照してください。調査スナップショットの基準日は **2026-06-21**。

## 調査の枠組み

### MCP Server のアーキテクチャ3分類

| 分類 | 定義 | 代表例 |
|---|---|---|
| **A: 汎用 LSP→MCP ブリッジ** | 任意の言語サーバに接続。Java は `jdt.ls`（Eclipse JDT Language Server）を指す | jonrad/lsp-mcp, isaacphi/mcp-language-server, bug-ops/mcpls ほか |
| **B: 特定 LSP ラッパー** | jdt.ls 等を直接ラップ。Java 最優先文脈で重要 | stephanj/LSP4J-MCP, sunix/jdtls-mcp |
| **C: LSP非依存・自己完結型** | 言語サーバを起動せず tree-sitter / ctags 等で symbol 抽出・検索を内包（比較対象） | johnhuang316/code-index-mcp, DeusData/codebase-memory-mcp |

### 評価軸
- **能力適合**: jdt.ls 適合度と保守鮮度を重視
- **セキュリティ**: 依存ライブラリの既知 CVE と、セキュリティ Issue の放置状況
- **運用依存フットプリント**: 配布形態（単一バイナリ ≫ JVM/Node ≫ 多依存 Python）による破損・軽快さ・依存衝突リスク
- **メンテナ対応姿勢**

> 利用環境の前提（脅威モデル）: Claude Code・MCP サーバ・言語サーバが**同一ローカル環境で stdio 起動**し、外部ネットワークに出ない。この前提下ではネットワーク/Web 系 CVE の実効リスクが下がり、候補間のセキュリティ差はほぼ平坦化する。

## 調査の流れと成果物

| フェーズ | 内容 | 成果物 |
|---|---|---|
| 01. 候補調査 | GitHub・MCP レジストリ横断で候補33件を3分類に整理（5エージェント並列＋クロスレビュー） | `reports/01.候補調査/01.GitHub検索/` |
| 02. 評価マトリクス | 「jdt.ls適合×保守」重視で活発17件を採点・ランキング → Phase 2 を10件に絞り込み | `reports/01.候補調査/02.評価マトリクス作成/` |
| 03. 脆弱性チェック | Primary 5 を `osv-scanner` で深掘り＋Secondary 5 を軽量照合＋全10件の Issue 調査 | `reports/02.脆弱性チェック/` |
| 04. 総合評価・推奨 | 能力×セキュリティ×運用×姿勢の4軸でリスク調整済み最終ランキング | `reports/03.総合評価・推奨/` |

## 主要な発見

- **Spring Boot 専用・Gradle 専用の LSP連携 MCP Server は存在しない**。実態は「汎用ブリッジ＋言語サーバ本体」の組み合わせ。
- 現実の対応温度差: **Java(jdt.ls) ≫ Spring Boot（条件付き・未実証）≫ Gradle**（`gradle-language-server` が named pipes 専用で stdio 非対応のため LSP 用途はほぼ不可）。
- ローカル脅威モデルではセキュリティ差が平坦化し、**実質の差別化は「能力適合 × 運用フットプリント」**が支配的。能力上位でも Python 多依存の候補は運用面で後退する。

## 最終推奨（リスク調整済み）

| 推奨帯 | 候補 | 決め手 |
|---|---|---|
| 🥇 第1推奨 | **bug-ops/mcpls**（A・Rust） | Java=jdtls＋Gradle 明示・依存スキャン0件・Rust 単一バイナリで運用最軽量 |
| 🥇 第1推奨 | **blackwell-systems/agent-lsp**（A・Go） | jdtls＋30言語CI・能力首位・Go 単一バイナリ・CVE はツールチェーンのみ |
| 🎯 用途特化 | **sunix/jdtls-mcp**（B） | Java 機能カバレッジ最多（7ツール）・自己完結バイナリ・依存クリーン |
| 🎯 汎用基盤 | **isaacphi/mcp-language-server**（A） | 大規模採用・Go 軽量・govulncheck 組込 |
| ⚖️ 条件付き | **oraios/serena**（A） | 能力・実績最大だが Python 211 依存の運用重＋jdt.ls 未確認 |

詳細・採用前の残課題は `reports/03.総合評価・推奨/01.リスク評価まとめ/推奨リスト.md` を参照。

## 注意事項

- 候補のスター数・最終 push・依存バージョン等は **2026-06-21 時点**の値です。採用前に最新状況の再確認を推奨します。
- 依存スキャンは `osv-scanner 1.9.2` によるロックファイル照合（install/build はせず読取のみ）。脅威モデル適用後の実効リスクは各成果物の解釈注記を参照してください。
