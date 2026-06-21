# 候補調査 D: MCP レジストリ横断
作成日: 2026-06-21 / 担当: Agent D

---

## 横断したレジストリと検索条件

| レジストリ | 使用した検索語 | 概況 |
|---|---|---|
| **glama.ai/mcp/servers** | lsp, language server, code intelligence | 新規 4 件発見（agent-lsp, vue-ts-lsp-mcp, CesarPetrescu/lsp-mcp, sminnee/lsp-mcp）。41,000+ 件中 lsp 関連が数十件程度 |
| **mcpservers.org** | lsp, language server, code intelligence, code index | 新規 4 件発見（agent-lsp, mcp-gopls, nvim-lsp-mcp×2, zig-mcp, typescript-mcp）。既知候補含め 10+ 件ヒット |
| **pulsemcp.com** | lsp, language server, code intelligence, code index | 新規 2 件（asimihsan/multilspy-lsp, mcp-gopls）。既知候補も多数掲載 |
| **smithery.ai** | language server, lsp, Java | 新規は限定的（nzrsky/lsp-mcp-server が Smithery 経由でインストール可能と判明）。既知候補と一致が多い |
| **mcp.so** | lsp, language server, code intelligence | 新規 2 件（headless-editor-mcp, leonardcser/nvim-lsp-mcp）。既知候補も多数掲載 |
| **modelcontextprotocol.io / GitHub awesome-mcp-servers** | lsp, language server, awesome mcp | 公式 example/servers には LSP 系なし。appcypher/awesome-mcp-servers（★5616）を確認したが LSP セクション記述なし |
| **GitHub検索（補完）** | awesome-mcp, language-server-protocol topic | appcypher / YuzeHao2023 / mctrinh の awesome リストを確認。新規として t3ta/mcp-language-server, nzrsky/lsp-mcp-server, sminnee/lsp-mcp を確認 |

---

## 新規発見候補サマリ表

既知候補リスト: jonrad/lsp-mcp, ProfessioneIT/lsp-mcp-server, thomasgazzoni/vsc-mcp, TwoWells/Catenary, rockerBOO/mcp-lsp-bridge, isaacphi/mcp-language-server, Tritlo/lsp-mcp, bug-ops/mcpls, axivo/mcp-lsp, karellen/karellen-lsp-mcp, stephanj/LSP4J-MCP, sunix/java-lsp-mcp-server, johnhuang316/code-index-mcp

| 名称 | owner/repo | URL | カテゴリ | ★ | 最終push | open issues | 言語 | Java | License | 発見元レジストリ | 所見 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| agent-lsp | blackwell-systems/agent-lsp | https://github.com/blackwell-systems/agent-lsp | A | 59 | 2026-06-14 | 3 | Go | あり（jdtls） | MIT | glama.ai / mcpservers.org | 65ツール・30言語CI検証済み。最も活発な汎用LSP→MCPブリッジ。旧 blackwell-systems/LSP-MCP（アーカイブ済み）から移行した現行版 |
| headless-editor-mcp | oakenai/headless-editor-mcp | https://github.com/oakenai/headless-editor-mcp | A | 13 | 2024-12-14 | 0 | TypeScript | 未確認 | MIT | mcp.so | 「言語非依存のヘッドレスコードエディタ、LSP+MCPで動作」と説明。最終pushが2024-12-14でほぼ休止状態。ドキュメントに language-server-integration.md あり |
| vue-ts-lsp-mcp | enc0ded/vue-ts-lsp-mcp | https://github.com/enc0ded/vue-ts-lsp-mcp | B | 0 | 未確認 | 0 | TypeScript | なし | MIT | glama.ai | cclsp のフォーク。Vue/TS/JS 特化の自己完結型（language server バンドル済み）。Java 非対応 |
| MultilspyLSP (mcp-multilspy) | asimihsan/mcp-multilspy | https://github.com/asimihsan/mcp-multilspy（推定；exact URL 404） | A | 未確認 | 未確認 | 未確認 | Python | あり（microsoft/multilspy 経由） | 未確認 | pulsemcp.com | microsoft/multilspy ライブラリをラップした MCP サーバ。Java 含む多言語に対応（multilspy が jdtls 対応）。PyPI パッケージ asimihsan-multilspy-lsp で公開。v0.1.0 / Python ≥3.12 |
| mcp-gopls | hloiseaufcms/mcp-gopls | https://github.com/hloiseaufcms/mcp-gopls | B | 88 | 未確認 | 未確認 | Go | なし | Apache-2.0 | mcpservers.org / mcp.so | Go 専用 LSP（gopls）ラッパー。Docker イメージあり。Java 非対応 |
| lsp-mcp (sminnee) | sminnee/lsp-mcp | https://github.com/sminnee/lsp-mcp | A | 6 | 未確認（2025以降？） | 0 | TypeScript | 未確認（設定次第） | 未指定 | glama.ai / smithery.ai | リファクタリング特化（rename/extract/move/find-references）。TypeScript/Python 明示。他言語は設定で追加可能。MCP SDK v1.17.5 使用 |
| lsp-mcp-server (nzrsky) | nzrsky/lsp-mcp-server | https://github.com/nzrsky/lsp-mcp-server | A | 10 | 2026-04-16 | 1 | Zig | あり（jdtls） | MIT | smithery.ai / mcpservers.org | Zig 製高性能 LSP-MCP ブリッジ。Homebrew/apt/dnf/Docker 等多数のインストール手段。Java(jdtls)含む多言語対応を明記 |
| t3ta/mcp-language-server | t3ta/mcp-language-server | https://github.com/t3ta/mcp-language-server | A | 3 | 未確認 | 未確認 | Go | 設定次第（任意LSP） | BSD-3-Clause | awesome-mcp / WebSearch | isaacphi/mcp-language-server の多言語対応フォーク。1プロセス内で複数 LSP を設定ファイルで管理。Java サーバを設定すれば対応可 |
| nvim-lsp-mcp (leonardcser) | leonardcser/nvim-lsp-mcp | https://github.com/leonardcser/nvim-lsp-mcp | B? | 4 | 未確認 | 0 | Go | 設定次第 | MIT | mcp.so | Neovim に接続して diagnostics を取得するのみ。Neovim セッションが前提。診断読み出し特化で LSP 全機能は持たない |
| nvim-lsp-mcp (trevorprater) | trevorprater/nvim-lsp-mcp | https://github.com/trevorprater/nvim-lsp-mcp | B? | 未確認（GitHub 404） | 未確認 | 未確認 | 未確認 | 未確認 | 未確認 | mcpservers.org / WebSearch | Neovim の LSP を通じたコードインテリジェンス・ナビゲーション全般を提供と説明。GitHub URL は登録されているが現時点で 404（削除または private 化の可能性） |
| CesarPetrescu/lsp-mcp | CesarPetrescu/lsp-mcp | https://github.com/CesarPetrescu/lsp-mcp | A | 未確認 | 未確認 | 未確認 | Python | なし（Python/Rust/C++/TS/JS/React/HTML/CSS） | 未確認（permissive） | glama.ai | 「Codex LSP Bridge」と呼称。Python/Rust/C++/TS 等対応。Java は対象外。Glama 上で「unclaimed」「インストール不可」と表示されており実用性に疑問 |

---

## 各候補の詳細

### 1. blackwell-systems/agent-lsp（カテゴリ: A）
- **アーキ概要**: Go 製の MCP サーバ。内部で各言語の language server（gopls, rust-analyzer, jdtls 等）を subprocess として起動・管理し、65 ツール・24 エージェントワークフローを提供する。speculative execution（書き込み前にシミュレーション）が特徴。
- **Java 対応**: あり。CI の 30 言語リストに Java（jdtls）を明記。
- **分類根拠**: 特定言語 LSP に依存しない汎用ブリッジ = カテゴリ A。
- **注記**: 旧 blackwell-systems/LSP-MCP（archived）はトピックタグに java を含んでいたが、現在は agent-lsp に統合済み。★59・2026-06 まで活発に更新中で最注目候補。

### 2. oakenai/headless-editor-mcp（カテゴリ: A）
- **アーキ概要**: TypeScript 製。「headless code editor」として LSP + MCP を組み合わせた設計。`language-server-integration.md` が存在しブリッジ設計を持つ。
- **Java 対応**: 未確認。README には言語固有の記述なし。
- **分類根拠**: 言語非依存のヘッドレスエディタ＋LSP ブリッジ = カテゴリ A。
- **注記**: 最終 push が 2024-12-14 と半年基準日（2025-12-21）の約 1 年前。実質休止の可能性が高い。★13・issues 0。

### 3. enc0ded/vue-ts-lsp-mcp（カテゴリ: B）
- **アーキ概要**: cclsp のフォーク。Vue/TypeScript/JavaScript に特化し、language server をバンドルして自己完結。グローバルインストール不要。
- **Java 対応**: なし。
- **分類根拠**: 特定言語セット（Vue/TS/JS）の LSP ラッパー = カテゴリ B。
- **注記**: ★0・フォーク元 cclsp（既知候補外）は汎用ブリッジ設計。ニッチな特化型。

### 4. asimihsan/mcp-multilspy（カテゴリ: A）
- **アーキ概要**: Python 製。Microsoft/multilspy ライブラリを内部で使用し、定義発見・参照・補完・ドキュメント取得等を MCP ツールとして提供。
- **Java 対応**: あり（microsoft/multilspy は jdtls 対応）。
- **分類根拠**: multilspy を通じて複数 LSP に接続する汎用ブリッジ = カテゴリ A。
- **注記**: GitHub URL が確定できない（asimihsan/mcp-multilspy は 404、asimihsan/multilspy-lsp も 404）。PulseMCP・Glama に掲載ありで存在は確認済みだがメタデータ不明。Smithery の elasticdotventures/mcp-lsp-multilspy と同一か別物か要確認。

### 5. hloiseaufcms/mcp-gopls（カテゴリ: B）
- **アーキ概要**: Go 製。Go の公式 LSP である gopls を起動し、定義・参照・hover・診断・テスト・カバレッジ・go mod 等を MCP ツールとして提供。
- **Java 対応**: なし。Go 専用。
- **分類根拠**: 特定 LSP（gopls）のラッパー = カテゴリ B。
- **注記**: ★88 で本調査の新規発見候補中最多。Docker イメージあり。Go 言語調査では最有力候補。

### 6. sminnee/lsp-mcp（カテゴリ: A）
- **アーキ概要**: TypeScript 製（MCP SDK v1.17.5 使用）。LSP クライアントを内部で管理し、rename_file / move_function / extract_function / find_references / rename_symbol の 5 ツールに特化したリファクタリング向け MCP サーバ。TypeScript/JavaScript/Python の language server をデフォルトサポート。
- **Java 対応**: 設定次第（任意 LSP を設定可能だが Java の明示的記述なし）。
- **分類根拠**: 任意 LSP と接続するブリッジ構造 = カテゴリ A（ただしリファクタリング特化の限定実装）。
- **注記**: ★6・issues 0・npm で公開予定だが未公開。Claude Code との連携を明示的に記述している点が特徴。

### 7. nzrsky/lsp-mcp-server（カテゴリ: A）
- **アーキ概要**: Zig 製高性能 LSP-MCP ブリッジ。設定ファイルで任意の LSP サーバ（zls/rust-analyzer/gopls/jdtls 等）を指定して接続。BDD テストスイート・Docker・Homebrew/apt/dnf 対応。
- **Java 対応**: あり（README の対応言語テーブルに Java/jdtls を明記）。
- **分類根拠**: 特定 LSP に依存しない汎用ブリッジ = カテゴリ A。
- **注記**: ★10・push 2026-04-16。Zig 0.14.1 ベース。パフォーマンス特化（起動 <100ms・<10ms レイテンシ）。実用性は今後の評価が必要。

### 8. t3ta/mcp-language-server（カテゴリ: A）
- **アーキ概要**: Go 製（isaacphi/mcp-language-server のフォーク）。設定ファイルで複数 language server を 1 プロセス内で管理し、ファイル拡張子でルーティング。polyglot リポジトリ向け。workspace/applyEdit 対応でリファクタリングも可能。
- **Java 対応**: 設定次第（任意 LSP を config.json で指定可能。Java LSP を書けば動作するはず）。
- **分類根拠**: 複数 LSP を束ねる汎用ブリッジ＝カテゴリ A。
- **注記**: ★3。元リポジトリへのマージ意図なし。現状は Go/Python/TypeScript/Rust を検証済み。Java は未検証。

### 9. leonardcser/nvim-lsp-mcp（カテゴリ: B?）
- **アーキ概要**: Go 製。Neovim セッションに接続し、Neovim の LSP が収集した diagnostics のみを返す単機能サーバ（`read-lints` ツール 1 本のみ）。Neovim が起動していることが前提。
- **Java 対応**: Neovim で Java LSP（jdtls 等）を設定していれば間接的に取得可能だが、直接 LSP を操作するわけではない。
- **分類根拠**: Neovim 経由で LSP diagnostics を読む特殊ラッパー。自ら LSP に接続するわけではない点が他と異なる。B?（LSP 特定ラッパーに近いが、LSP 自体は Neovim が担う）
- **注記**: ★4・issues 0・MIT。非常に限定的な機能（診断読出のみ）。

### 10. trevorprater/nvim-lsp-mcp（カテゴリ: B?）
- **アーキ概要**: mcpservers.org/Lobehub では「Neovim の LSP を通じたコードナビゲーション・24 ツール」と記述されているが、GitHub URL（github.com/trevorprater/nvim-lsp-mcp）が 404 で実態確認不可。
- **Java 対応**: 未確認。
- **分類根拠**: B?（Neovim LSP ラッパーと推定されるが実体不明）。
- **注記**: レジストリ掲載あり・GitHub 404。削除・private 化・URL 変更のいずれかの可能性。追跡困難。

### 11. CesarPetrescu/lsp-mcp（カテゴリ: A）
- **アーキ概要**: Python 製。LSP features（定義・参照・hover・signature help・symbol search・code actions・formatting・call hierarchy）を MCP ツールとして公開。HTTP/stdio 両対応。
- **Java 対応**: なし（対応言語: Python/Rust/C++/TS/JS/React/HTML/CSS）。
- **分類根拠**: 汎用 LSP→MCP ブリッジ = カテゴリ A（ただし Java 非対応）。
- **注記**: Glama 上で「unclaimed」「インストール不可」と表示。実用性・メンテ状況に疑問。メタデータ不明。

---

## 既知候補との重複確認（レジストリ掲載確認のみ・表に含まず）

以下は既知候補として除外したが、各レジストリで掲載を確認した候補:

| 既知 owner/repo | 発見したレジストリ |
|---|---|
| jonrad/lsp-mcp | glama.ai, mcp.so, mcpservers.org |
| ProfessioneIT/lsp-mcp-server | glama.ai |
| isaacphi/mcp-language-server | glama.ai, pulsemcp.com, mcpservers.org, mcp.so |
| Tritlo/lsp-mcp | glama.ai, pulsemcp.com, mcpservers.org, mcp.so, smithery.ai |
| rockerBOO/mcp-lsp-bridge | mcp.so |
| axivo/mcp-lsp | WebSearch 経由 |
| nzrsky/zig-mcp | mcpservers.org（lsp-mcp-server とは別の Zig 特化版も存在） |

---

## 要注意事項

1. **blackwell-systems/LSP-MCP（アーカイブ）と agent-lsp の関係**: 前者は既知候補リストに記載がなく、後者（agent-lsp）が実質的に前身から発展した現行版。agent-lsp は完全新規として扱った。
2. **asimihsan/mcp-multilspy の URL**: PulseMCP・Glama では掲載確認済みだが、`asimihsan/mcp-multilspy` も `asimihsan/multilspy-lsp` も GitHub では 404。Smithery に `elasticdotventures/mcp-lsp-multilspy` という類似名があり同一実装の別ホストか不明。
3. **trevorprater/nvim-lsp-mcp の実在性**: レジストリに登録があるが GitHub が 404。
4. **mcp-gopls（hloiseaufcms/mcp-gopls）の高 star（★88）**: Go 専用のため Java 調査には直結しないが、「特定言語 B 型」として最多 star。
5. **半年基準日（2025-12-21）以前の候補**: headless-editor-mcp（push 2024-12-14）は基準日をさらに遡り約 1 年前で実質停止の可能性。
