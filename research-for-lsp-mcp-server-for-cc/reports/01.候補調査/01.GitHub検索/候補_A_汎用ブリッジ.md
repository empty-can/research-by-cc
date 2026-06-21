# 候補調査 A: 汎用 LSP→MCP ブリッジ

作成日: 2026-06-21 / 担当: Agent A

> スコープ: カテゴリ A（任意の言語サーバに接続する汎用 LSP→MCP ブリッジ）の網羅的列挙。各候補の Java(jdt.ls)/Spring/Gradle 対応の実態を評価。脆弱性の深掘りは本フェーズ対象外（Sec-Issue 放置は表層シグナルのみ）。
>
> 基準日: 今日=2026-06-21、半年基準日=2025-12-21（これより古い push は「半年以上更新なし」）。
>
> 記入規則: カテゴリ A/B/C。Java/Spring/Gradle は ✅対応 / ⚠️不明・要確認 / ❌非対応。最終release 無しは「リリース無し」。最終push は `pushed_at`（コード最終更新）。

## サマリ表

| 名称 | owner/repo | URL | カテゴリ | ★ | 最終push | 最終release | open issues | 言語 | Java | Spring | Gradle | License | Sec-Issue放置 | 所見 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| serena | oraios/serena | https://github.com/oraios/serena | A | 25604 | 2026-06-19 | (タグ確認推奨) | 131 | Python | ✅ | ⚠️ | ⚠️ | MIT | 無(security label未確認) | **本カテゴリ最大級★**。デフォルトバックエンドが「LSPを実装する言語サーバ（40+言語）」で、その上にIDE級セマンティックツール（find symbol/references/rename/refactor等）を載せる汎用ブリッジ。**対応40+言語にJavaを明示**。別オプションでJetBrainsプラグインbackendも選択可（有償）。Claude Code等のMCPクライアント全般に対応。LSPバックエンドのJava用LSP具体実装(jdt.ls等)はドキュメント側参照要 |
| mcp-language-server | isaacphi/mcp-language-server | https://github.com/isaacphi/mcp-language-server | A | 1554 | 2026-03-01 | v0.1.1 | 62 | Go | ⚠️ | ⚠️ | ⚠️ | BSD-3-Clause | 無(security label該当0) | 最有力級の汎用ブリッジ。`--lsp <任意の実行可能LSP>` を渡す設計で言語非依存。READMEの動作確認例は go/rust/python/typescript/C・C++。Javaは明記なしだが「stdio で話す LSP なら多くと互換」と記載→jdt.ls も理論上可。スター多・実績豊富 |
| lsp-mcp-server | ProfessioneIT/lsp-mcp-server | https://github.com/ProfessioneIT/lsp-mcp-server | A | 19 | 2026-06-12 | リリース無し | 2 | TypeScript | ✅ | ⚠️ | ✅ | MIT | 無 | **Java を「10言語 out of the box」に明示**。Java サーバは `jls`（idelice/jls, Java20+/Maven/npm/protobuf ビルド要）を採用、root patterns に `pom.xml`/`build.gradle`/`build.gradle.kts`/`settings.gradle` を含む→Gradle 認識あり。jdt.ls ではなく jls 採用な点に留意。29ツール・SKILL.md 同梱。Windows非対応issueあり(#2) |
| mcp-lsp-bridge | rockerBOO/mcp-lsp-bridge | https://github.com/rockerBOO/mcp-lsp-bridge | A | 29 | 2025-08-03 | v0.2.0 | 0 | Go | ✅ | ⚠️ | ⚠️ | Apache-2.0 | 無 | 「20+言語サポート、Java含む」と明記。単一バイナリ、`lsp_config.json` で任意LSP定義。**最終push 2025-08-03 で半年以上更新停滞**。Java の具体LSP/Gradle設定はREADME非記載→要確認 |
| mcp-lsp | axivo/mcp-lsp | https://github.com/axivo/mcp-lsp | A | 23 | 2026-06-18 | v1.0.5 | 6 | TypeScript | ⚠️ | ⚠️ | ⚠️ | BSD-3-Clause | 無 | VSCode の `vscode-jsonrpc`/`vscode-languageserver-protocol` ベースで「全VSCode言語サーバ互換」を標榜→汎用。コア言語例に Go/Helm/Kotlin/Python/Terraform/TypeScript。**Kotlin対応明記=JVM系の実績あり**だが Java/jdt.ls 明示なし。npm配布(`@axivo/mcp-lsp`)、36+ツール、活発 |
| lsp-mcp | jonrad/lsp-mcp | https://github.com/jonrad/lsp-mcp | A | 187 | 2025-03-31 | リリース無し(Docker tag 0.3.1) | 6 | TypeScript | ⚠️ | ⚠️ | ⚠️ | MIT | 無 | 汎用ブリッジの草分け。`--lsp "<任意のLSP起動コマンド>"` を渡す設計で言語非依存→jdt.ls も指定可能。ただし **README自身が「POC状態」と明記**、example は TypeScript のみ、**最終push 2025-03-31 で更新停滞**。Dockerイメージ配布あり |
| lsp-mcp | Tritlo/lsp-mcp | https://github.com/Tritlo/lsp-mcp | A | 125 | 2025-07-21 | リリース無し | 7 | TypeScript | ⚠️ | ⚠️ | ⚠️ | MIT | 無 | `npx tritlo/lsp-mcp <language-id> <path-to-lsp> <lsp-args>` の汎用設計で任意LSP対応。ただし機能は hover/completions/code_actions/diagnostics 中心と限定的。example/extension は Haskell 特化。**最終push 2025-07-21 で停滞**。Java は理論上可だが未検証 |
| mcpls | bug-ops/mcpls | https://github.com/bug-ops/mcpls | A | 43 | 2026-06-17 | v0.3.6 | 46 | Rust | ✅ | ⚠️ | ✅ | Apache-2.0 / MIT (dual) | 無(security label該当0) | 「Universal MCP→LSP bridge」。**サポート表に Java=`jdtls`「Maven/Gradle projects」と明示**→本フェーズの要件に最も合致する記述。単一Rustバイナリ、LSP 3.17準拠なら任意サーバ可。activ・最新release あり。ただし **open issues 46 と多め**（要中身確認、本フェーズでは深掘りせず） |
| Catenary | TwoWells/Catenary | https://github.com/TwoWells/Catenary | A | 8 | 2026-06-21 | v1.6.1 | 7 | Rust | ⚠️ | ⚠️ | ⚠️ | AGPL-3.0 | 無 | LSP サーバプールを管理しMCP/CLI/Hooks/TUIの4面で公開する汎用ルータ。config.toml に任意言語サーバを定義（例は rust/python）。Java明示なし。**AGPL-3.0（商用は別途商用ライセンス要）→ライセンス要注意**。Claude Code プラグイン対応。スターは少なめだが活発 |
| vsc-mcp | thomasgazzoni/vsc-mcp | https://github.com/thomasgazzoni/vsc-mcp | A? | 31 | 2025-05-16 | リリース無し | 2 | TypeScript | ⚠️ | ⚠️ | ⚠️ | (LICENSE未設定) | 無 | 「LSP機能をMCPツールとして公開」。VS Code拡張寄り（topics: vscode-extension）で汎用ブリッジか VSCode依存ラッパーか判別曖昧→**A?**。**最終push 2025-05-16 で停滞**、ライセンス未設定（再配布・改変上の懸念）。Java対応の記述なし |
| karellen-lsp-mcp | karellen/karellen-lsp-mcp | https://github.com/karellen/karellen-lsp-mcp | A? | 0 | 2026-04-10 | リリース無し | 1 | Python | ⚠️ | ⚠️ | ⚠️ | Apache-2.0 | 無 | description で「Starts with C/C++ via clangd, **extensible to any language**」=汎用志向だが現状 clangd 起点→A?。**topics に java/kotlin あり**（拡張先として想定）が本体はまだ C/C++ 実装段階。多セッション共有デーモン+refcounted LSP インスタンスという設計は特徴的。スター0・新興 |

### 補足: 検索ノイズについて
GitHub 検索（"lsp mcp bridge" / "language server protocol mcp" / "mcp lsp server"、各 `in:name,description,readme`）では、Claude Code のソースリーク系フォーク（`*/claude-code`, `claude-code-source` 等）や awesome-list（`punkpeye/awesome-mcp-servers` 等）、無関係な大規模MCPカタログ（`awslabs/mcp`, `modelcontextprotocol/servers` 等）が大量にヒットしたが、いずれもカテゴリ A の汎用 LSP ブリッジではないため上表から除外した。各検索クエリの total_count は数千〜数万件規模だが、ページ1（各25件）の範囲で本物の LSP→MCP ブリッジ実体は上記に収斂。

---

## 各候補の詳細

### oraios/serena （★25604・本カテゴリ最大級・Java明示）
- **アーキテクチャ概要**: 「The IDE for Your Coding Agent」。シンボルレベルで動作するセマンティックな検索/編集/リファクタ/デバッグツール群を MCP 経由で任意のクライアント/LLM に提供。**2 つのバックエンドを選択可能**: (1) **LSP を実装する言語サーバ（デフォルト、free/OSS）**、(2) Serena JetBrains プラグイン（有償、JetBrains IDE のコード解析を利用）。`uv tool install serena-agent` で導入、`serena init`（デフォルトで LSP バックエンド、`-b JetBrains` で切替）。retrieval/refactoring/symbolic editing/memory の各ツール群。
- **Java(jdt.ls)対応の実態**: LSP バックエンドで「**over 40 programming languages**」をサポートし、列挙リストに **Java を明示的に含む**（✅）。Java 用に内部で起動する具体的な言語サーバ実装（jdt.ls か否か）は README 本文では未明示で、`020_programming-languages` ドキュメントページ参照が必要 → 後続フェーズで確認推奨。JetBrains バックエンド選択時は IntelliJ IDEA の Java 解析を利用（jdt.ls 非経由）。
- **Spring・Gradle対応**: README に明示なし（⚠️）。バックエンドの言語サーバ/IDE 解析能力に依存。
- **特筆issue・備考**: open issues 131。最終 push 2026-06-19（最新）。MIT。本カテゴリで突出したスター（25604）と採用実績。README は「MCP/プラグインマーケットプレイス経由で入れるな（古い導入コマンドを含むため）、Quick Start に従え」と注意喚起。security ラベルの放置 issue は本フェーズ未精査（「無(未確認)」）。**カテゴリ判定**: デフォルトが LSP バックエンドの汎用ブリッジのため A と判定。ただし JetBrains バックエンドも持つハイブリッドな性格に留意。

### isaacphi/mcp-language-server （★1554・最有力級）
- **アーキテクチャ概要**: MCP サーバが内部で LSP クライアントを起動し、`--lsp <executable>` で指定した任意の言語サーバを stdio 経由で駆動。`--` 以降の引数はそのまま LSP に渡る。gopls のプロトコルコードを流用して LSP 型を実装。提供ツール: `definition` / `references` / `diagnostics` / `hover` / `rename_symbol` / `edit_file`。
- **Java(jdt.ls)対応の実態**: README の動作確認済みは go(gopls)/rust(rust-analyzer)/python(pyright)/typescript/C・C++(clangd)。Java は明記なし。ただし「I have only tested this repo with the servers above but it should be compatible with many more（stdio で話す LSP なら互換）」とあり、jdt.ls を `--lsp` に渡す形で**理論上は接続可能**。要実証。
- **Spring・Gradle対応**: 言語サーバ非依存設計のため、jdt.ls 側が解決する範囲に依存。本体側に Gradle/Spring 固有処理は無い。⚠️未検証。
- **特筆issue・備考**: open issues 62。security ラベル該当 0。最終 release v0.1.1。最終 push 2026-03-01（半年以内）。スター最多で採用実績が厚く、汎用ブリッジの第一候補。

### ProfessioneIT/lsp-mcp-server （Java を明示的にサポート）
- **アーキテクチャ概要**: Claude Code ⇄ lsp-mcp-server ⇄ 言語サーバ（stdio/JSON-RPC）。29 の MCP ツール（navigation/reference/diagnostics/refactoring 他）。`.lsp-mcp.json` 等で言語サーバ定義。push 型 diagnostics キャッシュ、マルチルートワークスペース対応。セキュリティ機能（絶対パス強制・ワークスペース境界検証・10MBファイル上限・`shell:false`）を明記。SKILL.md 同梱。
- **Java(jdt.ls)対応の実態**: 「10 Languages Supported out of the box」に **Java を明示**。ただし採用 Java サーバは **`jls`（idelice/jls）であり jdt.ls ではない**。jls は Java20+/Maven/npm/protobuf でのソースビルドが必要。root patterns に `pom.xml`/`build.gradle`/`build.gradle.kts`/`settings.gradle`/`settings.gradle.kts`/`BUILD`/`.classpath` を含む。
- **Spring・Gradle対応**: **Gradle は root pattern として認識**（✅）。Spring 固有機能は無し（⚠️、jls の解析能力に依存）。
- **特筆issue・備考**: open issues 2（#2 Windows 非対応の報告、#3 cwd 修正 PR）。リリースタグ無し。最終 push 2026-06-12（最新）。スター 19 と少なめだが Claude Code 連携を明確にうたう活発な新興候補。Windows 利用時は #2 に留意。

### rockerBOO/mcp-lsp-bridge （Java明記・更新停滞）
- **アーキテクチャ概要**: Go 製単一バイナリ。`lsp_config.json` で任意の言語サーバを定義。16 の MCP ツール（analysis/navigation/refactoring/intelligence）。Docker ベースイメージ配布（LSP サーバは別途追加）。
- **Java(jdt.ls)対応の実態**: 「Supports 20+ languages including Go, Python, TypeScript, Rust, **Java**, C#, C++」と Java を明示（✅）。ただし Java 用の具体的な LSP 実装（jdt.ls か否か）や設定例は README に無く、汎用 `lsp_config.json` にユーザが定義する前提。
- **Spring・Gradle対応**: README 非記載（⚠️）。config 次第。
- **特筆issue・備考**: open issues 0。release v0.2.0。**最終 push 2025-08-03 で半年以上更新停滞**（基準日 2025-12-21 より前）。メンテ継続性に懸念。

### axivo/mcp-lsp （VSCode系汎用・活発・Kotlin実績）
- **アーキテクチャ概要**: VSCode の `vscode-jsonrpc` / `vscode-languageserver-protocol` を基盤に「全 VSCode 言語サーバと互換」を標榜。`lsp.json` で言語サーバ＋プロジェクトを定義、`LSP_FILE_PATH` 環境変数で設定参照。36+ の MCP ツール（server管理/解析/ナビゲーション/補完/フォーマット/リファクタ）。プロセス分離・レート制限等のセキュリティ機能あり。npm 配布（`@axivo/mcp-lsp`）。
- **Java(jdt.ls)対応の実態**: コア言語例は Go/Helm/Kotlin/Python/Terraform/TypeScript。**Kotlin（JVM 系）対応を明記**しており JVM 言語サーバの実績はあるが、**Java/jdt.ls は明示なし**（⚠️）。「全 VSCode 言語サーバ互換」の建付け上、jdt.ls を設定すれば接続可能と推測されるが要検証。
- **Spring・Gradle対応**: 明記なし（⚠️）。設定例に Kotlin/Ktor があるため Gradle プロジェクトの利用実績は推測される。
- **特筆issue・備考**: open issues 6。release v1.0.5。最終 push 2026-06-18（最新）。Organization アカウント、ドキュメント充実、活発。

### jonrad/lsp-mcp （草分け・POC明記・停滞）
- **アーキテクチャ概要**: 汎用 LSP→MCP の草分け的存在（★187 と本カテゴリ上位）。`--lsp "<LSP起動コマンド>"` を渡す設計で言語非依存。LSP JSON Schema から対応メソッドを動的生成。npx / Docker で起動。
- **Java(jdt.ls)対応の実態**: 言語非依存設計のため jdt.ls を `--lsp` に指定可能（⚠️理論上）。ただし README の example は TypeScript のみ。Java の実証記載なし。
- **Spring・Gradle対応**: 記載なし（⚠️）。
- **特筆issue・備考**: open issues 6。**README が自ら「This is in a POC state」と明記**。**最終 push 2025-03-31 で更新停滞**。「Multiple LSPs at the same time is not yet supported」。スター数は本カテゴリ最多級だが成熟度・継続性に懸念。

### Tritlo/lsp-mcp （汎用設計だが機能限定・Haskell寄り・停滞）
- **アーキテクチャ概要**: `npx tritlo/lsp-mcp <language-id> <path-to-lsp> <lsp-args>` で任意 LSP を駆動。ツールは hover(`get_info_on_location`)/completions/code_actions/diagnostics/open・close_document/start・restart_lsp と限定的。言語別 extension 機構あり（現状 Haskell のみ）。
- **Java(jdt.ls)対応の実態**: 汎用設計のため jdt.ls 指定は理論上可（⚠️）。ただし example・extension は Haskell 特化で、定義ジャンプ/参照検索といった重要ナビゲーション系ツールが見当たらず、コードナビゲーション用途では機能不足の可能性。
- **Spring・Gradle対応**: 記載なし（⚠️）。
- **特筆issue・備考**: open issues 7。リリースタグ無し（README 上は v0.2.0+ への言及あり）。**最終 push 2025-07-21 で停滞**。

### bug-ops/mcpls （Java=jdtls/Maven・Gradle を明示／要件最適合）
- **アーキテクチャ概要**: 「Universal MCP→LSP bridge」。Rust 製単一バイナリ（Node/Python ランタイム不要）、Tokio 非同期で複数 LSP を並行管理、pure Rust（unsafe 無し）。LSP 3.17 準拠なら任意サーバ対応。`mcpls.toml` でヒューリスティック（プロジェクトマーカー）と言語サーバを定義。Code Intelligence/Diagnostics/Refactoring/Call Hierarchy/Server Monitoring の各ツール群。
- **Java(jdt.ls)対応の実態**: サポートサーバ表に **Java = `jdtls`、Notes「Maven/Gradle projects」と明示**。本フェーズの優先要件（Java>Spring Boot>Gradle、jdt.ls）に最も近い記述を持つ候補。
- **Spring・Gradle対応**: **Gradle を明示**（✅、jdtls 経由）。Spring 固有は記載なし（⚠️）。
- **特筆issue・備考**: release v0.3.6（活発）。最終 push 2026-06-17（最新）。crates.io / docs.rs 公開、CI・codecov あり。**open issues 46 と多め**（本フェーズでは中身を深掘りしないが、後続フェーズで内容確認推奨）。security ラベル該当の放置 issue は確認範囲で無し。dual ライセンス（Apache-2.0 / MIT）。

### TwoWells/Catenary （4面ルータ・AGPL注意）
- **アーキテクチャ概要**: LSP サーバプールを管理し、MCP / CLI / Hooks / TUI の 4 つの独立サーフェスから公開する「マルチサーフェス・インテリジェンスルータ」。`~/.config/catenary/config.toml` に任意言語サーバを定義（例は rust-analyzer / pyright）。Claude Code プラグイン（`/plugin install`）・Gemini CLI 拡張に対応。全プロトコルメッセージを SQLite に記録し TUI で可観測。
- **Java(jdt.ls)対応の実態**: 任意 LSP 定義可能だが config 例・doctor 出力は rust/python のみ。**Java 明示なし**（⚠️）。
- **Spring・Gradle対応**: 記載なし（⚠️）。
- **特筆issue・備考**: release v1.6.1（活発）。最終 push 2026-06-21（当日）。**ライセンスが AGPL-3.0-or-later**（商用利用は別途 LICENSE-COMMERCIAL 要）→ 配布・組込み形態によっては要注意。スター 8 と少なめだが開発は活発。

### thomasgazzoni/vsc-mcp （A?・VSCode依存疑い・停滞・ライセンス未設定）
- **アーキテクチャ概要**: 「LSP 機能を MCP ツールとして公開」。topics に `vscode-extension`/`vs-code` を含み、VS Code 拡張に依存した実装の可能性があり、純粋な汎用ブリッジか VSCode ランタイム依存ラッパーか README からは判別が曖昧 → **カテゴリ A?**（後続で実装確認推奨）。
- **Java(jdt.ls)対応の実態**: 記載なし（⚠️）。
- **Spring・Gradle対応**: 記載なし（⚠️）。
- **特筆issue・備考**: open issues 2。リリースタグ無し。**最終 push 2025-05-16 で停滞**。**LICENSE 未設定**（search_repositories の license フィールド欠落）→ 再配布・改変時の法的リスクに注意。

### karellen/karellen-lsp-mcp （A?・clangd起点の汎用志向・新興）
- **アーキテクチャ概要**: LLM⇄LSP ブリッジ。**多セッション共有デーモン + refcounted LSP サーバインスタンス**という運用設計が特徴。definitions/references/call・type hierarchies/hover/symbols/diagnostics を提供。
- **Java(jdt.ls)対応の実態**: description は「**Starts with C/C++ via clangd, extensible to any language**」で現状 C/C++ 起点。汎用志向だが Java はまだ実装段階に見える → **A?**。topics に `java`/`kotlin`/`polyglot` を含み、拡張先として JVM 系を想定（⚠️）。
- **Spring・Gradle対応**: 記載なし（⚠️）。
- **特筆issue・備考**: open issues 1。リリースタグ無し。最終 push 2026-04-10（半年以内）。スター 0 の新興。topics に `claude-code`/`claude-code-plugin`/`claude-skills` があり Claude Code 連携を志向。

---

## メモ（メインセッション向け・取捨選択の参考、却下はしない）
- **Java/jdt.ls 明示 + 活発 + Gradle 言及**の三拍子が揃うのは **bug-ops/mcpls**（Java=jdtls/Maven・Gradle明示）と **ProfessioneIT/lsp-mcp-server**（Java明示・Gradle root pattern、ただし jls 採用で jdt.ls ではない）。
- **実績・スター最多**は **oraios/serena**（★25604、Java明示・LSPバックエンド汎用、ただしJava用LSP具体実装はドキュメント要確認・JetBrainsハイブリッド）と **isaacphi/mcp-language-server**（★1554、Java未検証だが言語非依存設計で接続自体は可能性大）。
- serena は機能の充実度・実績で突出するが、(a) JetBrains バックエンドも併設するハイブリッド設計、(b) Java 用 LSP の具体実装がREADME非明示、の2点を後続フェーズで確認すべき。
- **更新停滞（半年基準日 2025-12-21 より前の最終 push）**: jonrad(2025-03-31) / Tritlo(2025-07-21) / rockerBOO(2025-08-03) / thomasgazzoni(2025-05-16)。継続性の観点で要注意。
- **ライセンス注意**: TwoWells/Catenary は AGPL-3.0、thomasgazzoni/vsc-mcp は LICENSE 未設定。
- 各候補の Java 欄が ⚠️ 中心なのは、汎用ブリッジは「任意 LSP を設定で渡す」性質上、README で個別言語の実証を省くものが多いため。実機検証（jdt.ls を実際に接続）は後続フェーズで必要。
