# 候補調査 E: 非LSP型コードインテリジェンス MCP（カテゴリC・比較併走）

作成日: 2026-06-21 / 担当: Agent E

---

## サマリ表

| No | 名称 | owner/repo | URL | C判定 | 判定根拠（技術） | ★ | 最終push | open issues | 言語 | Java対応 | License | 所見 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | mcp-server-tree-sitter | wrale/mcp-server-tree-sitter | https://github.com/wrale/mcp-server-tree-sitter | ✅C | tree-sitter + language-pack。LSP依存なし | 309 | 2026-05-21 | 4 | Python | ✅ | MIT | **archived**（2026-05-21）。実績あり、入門用には依然有用 |
| 2 | codebase-memory-mcp | DeusData/codebase-memory-mcp | https://github.com/DeusData/codebase-memory-mcp | ✅C※ | 158言語の tree-sitter グラマーを静的バイナリに同梱。「Hybrid LSP」バッジあるが README で「No language server process, no per-project setup」と明記 | 9820 | 2026-06-20 | 134 | C | ✅ | MIT | カテゴリC最大手。「Hybrid LSP」は独自実装の型解決アルゴリズム名でありLSPプロセス起動なし（要注記） |
| 3 | codesearch | flupkede/codesearch | https://github.com/flupkede/codesearch | ✅C | tree-sitter AST chunking + fastembed ベクター + tantivy BM25。Cargo.toml にLSP依存なし | 46 | 2026-06-21 | 0 | Rust | ✅ | Apache-2.0 | マルチリポ対応のオフライン完結型セマンティック検索。活発に更新中 |
| 4 | tree-sitter-analyzer | aimasteracc/tree-sitter-analyzer | https://github.com/aimasteracc/tree-sitter-analyzer | ✅C | tree-sitter + SQLite FTS5。「per-language resolver gates every binding by language family」でLSP不使用を明示 | 40 | 2026-06-21 | 14 | Python | ✅ | MIT | 13言語のクロスファイル call-graph。言語ファミリーゲート方式による誤接続抑制が特徴 |
| 5 | code-graph-mcp | sdsrss/code-graph-mcp | https://github.com/sdsrss/code-graph-mcp | ✅C | tree-sitter + SQLite + sqlite-vec（ベクター検索拡張）。READMEにLSP記述なし、Cargo.tomlにLSP依存なし | 44 | 2026-06-21 | 1 | Rust | ✅ | 未確認（LICENSE file あり） | Rust製シングルバイナリ。16言語でJavaはFull tier（calls + imports + inheritance + HTTP routes） |
| 6 | toktoken | mauriziofonte/toktoken | https://github.com/mauriziofonte/toktoken | ✅C | universal-ctags + SQLite FTS5。LSP依存なし（ctags単体で動作） | 53 | 2026-04-23 | 2 | C | ✅ | AGPL-3.0 | ctags ベースで49言語対応。Java はuniversal-ctagsの標準対応言語（docs/LANGUAGES.md に記載） |

※ codebase-memory-mcp の「Hybrid LSP」は「LSPと構造的に互換性のある軽量C実装」という意味であり、言語サーバープロセスは起動しない。カテゴリCとして扱う。

**誤検出（実はLSP使用でカテゴリA/B）: 0件**

---

## 各候補の詳細

### 1. wrale/mcp-server-tree-sitter

**symbol抽出技術:**
- `tree-sitter>=0.24.0,<0.25` + `tree-sitter-language-pack>=0.6.1` による AST ベース symbol 抽出
- ツール: `get_symbols`（関数・クラス等の symbol 抽出）、`get_ast`（AST取得）、`run_query`（tree-sitter クエリ）
- キャッシュ機構あり（パースツリーキャッシュ）

**LSP不使用の確認根拠:**
- `pyproject.toml` の依存関係: `tree-sitter>=0.24.0,<0.25`, `tree-sitter-language-pack>=0.6.1` のみ。`python-lsp-server`, `pylsp`, `jedi-language-server` 等の記述なし
- README にも LSP への言及なし

**Java対応:**
- ✅ `tree-sitter-language-pack` に Java グラマーが含まれる（README に「Java」が明示列挙）

**備考:**
- 2026-05-21 に **archived（アーカイブ済み）**。新規採用には注意が必要
- ★309 と人気があり、実績・参考実装として引き続き有用
- PyPI: `mcp-server-tree-sitter` として公開済み

---

### 2. DeusData/codebase-memory-mcp

**symbol抽出技術:**
- 158言語の tree-sitter グラマーをバイナリに同梱・コンパイル済み
- SQLite + FTS5（BM25）+ sqlite-vec（ベクター検索）の複合検索
- ナレッジグラフ構造：Function / Class / Method / Route 等のノード、CALLS / IMPORTS / INHERITS 等のエッジ
- Nomic `nomic-embed-code` エンベディング（int8, 40K tokens）をバイナリ内蔵

**LSP不使用の確認根拠:**
- README Hybrid LSP 節に明記: 「**a lightweight C implementation of language type-resolution algorithms... No language server process, no per-project setup, no API key**」
- 「Hybrid LSP」は独自命名。LSP（Language Server Protocol）を使うのではなく、tsserver / Roslyn / Eclipse JDT 等の LSP実装と互換性のあるアルゴリズムをCで自前実装したもの
- ゼロ依存の単一静的バイナリで配布

**Java対応:**
- ✅ v0.8.0 で Hybrid LSP 対応。README に「Java: imports（single-type, on-demand, static）, class hierarchies with `this`/`super` dispatch, generics, annotations, overload matching by arity and parameter types, lambdas / method references bound to functional interfaces, field-type inference, common JDK stdlib」と詳細記載
- 言語サポートテーブルで「Good（75-89%）」評価

**備考:**
- カテゴリC候補の中で圧倒的な ★9820。実質デファクトスタンダード的地位
- arXiv 論文あり（arXiv:2603.27277）
- Claude Code / Codex / Gemini CLI 等11エージェント対応
- SLSA Level 3 / VirusTotal スキャン済みの高セキュリティ配布
- Issues 134件は活発な開発・利用の証左

---

### 3. flupkede/codesearch

**symbol抽出技術:**
- tree-sitter による AST チャンキング（16言語対応）
- fastembed-rs（Rust 実装エンベディングライブラリ）でベクター生成
- arroy（ベクター近傍探索）+ tantivy（BM25 全文検索）によるハイブリッド検索
- マルチリポ対応（複数リポジトリを横断的に検索可能）

**LSP不使用の確認根拠:**
- `Cargo.toml` 依存: `fastembed-rs`, `arroy`, `tantivy`, `tree-sitter` 系のみ
- LSP 関連ライブラリ（lsp-types, tower-lsp 等）の記述なし
- README 説明は「fully offline」「no API key」を強調しており、外部プロセス依存なし

**Java対応:**
- ✅ README の supported languages table に `.java` が明示記載

**備考:**
- Rust 製でシングルバイナリに近い配布
- オフライン完結型として Claude Code / OpenCode / Cursor 対応を明記
- 2026-06-21 更新と活発な開発継続中

---

### 4. aimasteracc/tree-sitter-analyzer

**symbol抽出技術:**
- tree-sitter + SQLite FTS5（インデックスは `.ast-cache/index.db`）
- 13言語でクロスファイル call-graph を構築（Python・Java・Go・JS・TS・C・C++・C#・Swift・Kotlin・Ruby・PHP・Rust）
- Synapse クロスファイルリゾルバー（import-aware）
- 「per-language resolver gates every binding by language family」でクロスファイル誤接続を抑制

**LSP不使用の確認根拠:**
- README に「no LSP」と明記した記述あり
- Python ベース（requirements.txt / pyproject.toml）。`tree-sitter` 系パッケージのみで LSP 依存なし
- 言語ファミリーゲート方式は tree-sitter AST の import グラフ解析による自前実装

**Java対応:**
- ✅ 13言語リストに Java 明示
- v0.8.0 で「Hybrid LSP-inspired resolver」追加（class hierarchies + overload + lambda resolution）

**備考:**
- 競合 code-graph-mcp との miswire比較を README に記載（TSA: 6件、code-graph-mcp: 745件）と誤接続の少なさをアピール
- PyPI: `tree-sitter-analyzer` として公開済み
- TOON（Token-Optimized Output Notation）形式で出力サイズを削減

---

### 5. sdsrss/code-graph-mcp

**symbol抽出技術:**
- tree-sitter による AST 解析（16言語対応）
- SQLite + sqlite-vec（ベクター検索 SQLite 拡張）+ FTS5 の複合検索
- ナレッジグラフ構造でコールグラフ・依存関係を管理
- HTTP ルートトレース・影響分析機能

**LSP不使用の確認根拠:**
- `Cargo.toml` に LSP 依存ライブラリの記述なし
- README に LSP 言及なし
- Rust 製シングルバイナリ（sqlite-vec 拡張を埋め込み）

**Java対応:**
- ✅ 言語サポートテーブルで Java は「Full tier」: calls + imports + inheritance + HTTP routes + test markers まで対応

**備考:**
- npm: `@sdsrss/code-graph` として公開
- 2026-06-21 更新と活発な開発継続
- LICENSE ファイルあり（README に License 種別未記載のため要確認）

---

### 6. mauriziofonte/toktoken

**symbol抽出技術:**
- universal-ctags（NOT exuberant-ctags）でシンボル抽出（49言語対応）
- SQLite FTS5 でインデックス構築・検索
- カスタムパーサー 16本を追加実装（ctags の対応を補完）
- ripgrep をフォールバックとして全文検索に利用

**LSP不使用の確認根拠:**
- C単一静的バイナリ。実行時依存は universal-ctags のみ
- README に「Zero runtime dependencies」（ctags を除く）と明記
- LSP プロセス起動の記述なし

**Java対応:**
- ✅ universal-ctags は Java を標準対応言語として含む（docs/LANGUAGES.md に記載）
- ただし README の主要サンプルは C/PHP 中心。Java 固有機能（アノテーション処理等）の詳細は `docs/LANGUAGES.md` 参照

**備考:**
- AGPL-3.0 ライセンス（商用利用には別途商用ライセンスが必要）
- 最終更新 2026-04-23 と他候補と比較してやや更新停滞
- GitHub リポインデックス機能（clone不要でインデックス）あり
- MCP 27ツールを提供

---

## 調査まとめ

| 項目 | 結果 |
|---|---|
| C確定候補数 | 6件 |
| 誤検出（A/B判定）件数 | 0件 |
| 誤検出候補（注意が必要だったもの） | DeusData/codebase-memory-mcp（「Hybrid LSP」バッジあり→LSPプロセス起動なしと確認済み） |
| Java対応注目候補 | DeusData/codebase-memory-mcp（★9820、v0.8.0でJava Hybrid LSP対応、Javaのクラス階層/オーバーロード/ラムダ解決）、sdsrss/code-graph-mcp（Full tier、HTTP routes・テストマーカーまで追跡）、aimasteracc/tree-sitter-analyzer（13言語call-graph、Synapse import-awareリゾルバー） |
| wrale/mcp-server-tree-sitter に関する注意 | archived（アーカイブ済み）のため新規採用は要検討。★309の実績・参考実装としては有効 |
