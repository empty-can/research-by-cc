# 候補調査 B: Java/jdt.ls 特化 MCP Server（最優先角度）
作成日: 2026-06-21 / 担当: Agent B

---

## サマリ表

| 名称 | owner/repo | URL | カテゴリ | ★ | 最終push | 最終release | open issues | 言語 | Java機能カバレッジ | Spring | Gradle | License | Sec-Issue放置 | 所見 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| LSP4J-MCP | stephanj/LSP4J-MCP | https://github.com/stephanj/LSP4J-MCP | B | 29 | 2026-06-10 | v1.0.0 | 0 | Java | symbol/references/definition/document-symbols/interface-method-search（5ツール） | ⚠️不明 | ⚠️不明 | MIT | 無 | 最もスター多・活発更新・Claude Codeを明示ターゲット |
| jdtls-mcp | sunix/jdtls-mcp | https://github.com/sunix/jdtls-mcp | B | 3 | 2026-03-16 | v1.0.1 | 0 | Java | hover/definition/references/completion/document-symbols/workspace-symbols/diagnostics（7ツール） | ⚠️不明 | ⚠️不明 | EPL-2.0 | 無 | 機能カバレッジ最多・リリースアーカイブあり・Claude Code統合手順記載 |
| java-lsp-mcp-server | sunix/java-lsp-mcp-server | https://github.com/sunix/java-lsp-mcp-server | B | 0 | 2026-03-13 | なし | 0 | Java | symbols/completion/diagnostics/formatCode/definition（5ツール）+ JDTLS lifecycle管理ツール群 | ✅Maven/Gradle検出あり | ✅Maven/Gradle検出あり | 未確認 | 無 | jdtls-mcpの前身実験・HTTP/SSEトランスポート・Quarkusベース |
| sts5-headless | zlsimon-personal/sts5-headless | https://github.com/zlsimon-personal/sts5-headless | B（Spring特化派生） | 0 | 2026-05-23 | なし | 0 | Java | Spring意味論ツール（getBeanDetails/getRequestMappings/getProjectList/getSpringBootVersion） | ✅Spring Boot専用 | ❌未確認 | EPL-2.0（"Other"表記） | 無 | STS5+jdt.ls橋渡し・Spring意味論に特化しJava LSP機能は直接公開せず・alpha/unofficial |

---

## 各候補の詳細

### 1. stephanj/LSP4J-MCP

**ラップ対象LSP:**
JDTLS (Eclipse JDT Language Server) を LSP4J (Eclipse LSP4J ライブラリ) でラップ。JDTLSをサブプロセスとして起動し、stdin/stdout経由でJSON-RPC通信する構成。MCP Java SDK使用。

**Java機能カバレッジ:**
- `find_symbols` — ワークスペース全体のJavaシンボル（クラス・メソッド・フィールド）を名前で検索
- `find_references` — 指定ファイル位置のシンボルへの全参照を検索
- `find_definition` — シンボルの定義へ移動
- `document_symbols` — Javaファイル内の全シンボルを列挙
- `find_interfaces_with_method` — 指定メソッド名を持つインターフェースを検索

**公開していないもの（6ツール中未実装）:** hover、diagnostics、completion、rename、format。README中に「missing tool」として `java_completions`（textDocument/completion）と `java_format`（textDocument/formatting）への言及あり。

**Spring Boot / Gradle対応:**
README・設定ファイルに spring-boot-language-server や Gradle への明示的な言及なし。⚠️不明。

**特筆事項:**
- `claudecode`, `gemini`, `codex` トピックタグあり — Claude Codeをファーストターゲットとして設計
- `.mcp.json` 設定例をREADMEに掲載
- Java 21+、Maven 3.8+、jdtls事前インストールが前提
- MITライセンス（最も利用しやすい）
- pushed_at: 2026-06-10（2026-06-21基準で11日前・最も活発）
- フォーク4、スター29（カテゴリB最多）
- open issues 0
- テストコードあり（`JdtlsClientTest.java`, `JavaToolsTest.java`, `McpServerMainTest.java`）

---

### 2. sunix/jdtls-mcp

**ラップ対象LSP:**
Eclipse JDT Language Server をOSGiプラグインバンドルとして内包する構成。JDTLSのハンドラークラスを**同一JVM内で直接呼び出す**（サブプロセス不要、ネットワークホップなし）。Tycho/OSGiビルド。MCP Java SDK + langchain4j アノテーション使用。

**Java機能カバレッジ（7ツール・最多）:**
- `java_hover` — Javadoc・型情報のhover取得
- `java_definition` — シンボル定義へ移動
- `java_references` — シンボルへの全参照を検索
- `java_completion` — コード補完候補取得
- `java_document_symbols` — ファイル内の全シンボル列挙
- `java_workspace_symbols` — ワークスペース横断のシンボル検索
- `java_diagnostics` — コンパイルエラー・警告の取得

全ツールは0ベース行/文字オフセット（LSP標準）。README内に `tools/list` のリアルJSON-RPCレスポンス例あり（実動作確認済みを示す）。

**未実装（README言及あり）:** `java_completions`（すでに実装済）と `java_format`（formatting）が「改善候補」として挙げられているが、completionは既に実装済みなので実質 `java_format` のみ未実装。

**Spring Boot / Gradle対応:**
Spring Boot や Gradle への明示的な言及なし（MavenプロジェクトのサンプルWorkspaceのみ）。⚠️不明。

**特筆事項:**
- プレビルドバイナリリリースあり（Linux x86_64, Linux aarch64, macOS x86_64, macOS aarch64, Windows x86_64 の5プラットフォーム対応）
- `scripts/download-and-start.sh` による自動ダウンロード起動をサポート
- Claude Code (`claude mcp add jdtls`) と GitHub Copilot in VSCode の両方に統合手順あり
- `agent.md`（LLMエージェント向けオンボーディングガイド）を同梱
- GitHub Actions による自動リリースワークフロー完備
- Conventional Commits採用
- 初回起動に約60秒（Mavenインポートとインデックス作成のため）
- Java 21以上必須（Mavenビルド時はMaven 3.9+も必要）
- スター3（少ないが機能成熟度は高い）
- pushed_at: 2026-03-16（2026-06-21基準で約3ヶ月前・やや停滞）
- EPL-2.0ライセンス（商用利用時は要確認）
- sunix/java-lsp-mcp-serverとのアーキテクチャ比較表をREADMEに掲載

---

### 3. sunix/java-lsp-mcp-server

**ラップ対象LSP:**
Eclipse JDT Language Server をサブプロセスとして起動し、LSP4Jで接続・管理する。JDTLSのライフサイクル管理をMCPツールとして公開（`startJdtls`, `stopJdtls`, `checkJdtls`, `installJdtls`, `initializeWorkspace`）。Quarkusフレームワーク使用でHTTP/SSEトランスポート。

**Java機能カバレッジ（5 LSPツール + 6ライフサイクルツール）:**

LSPツール（実装済み・Working状態）:
- `getSymbols(filePath)` — ファイル内シンボル取得（documentSymbol）
- `getCompletions(filePath, line, column)` — コード補完（最大20候補）
- `getDiagnostics(filePath)` — コンパイルエラー・警告取得
- `formatCode(filePath)` — ファイルフォーマット（ディスク書き込みあり）
- `getDefinition(filePath, line, column)` — 定義へ移動

ライフサイクルツール: `startJdtls`, `stopJdtls`, `checkJdtls`, `installJdtls`, `initializeWorkspace`, `getTestWorkspacePath`

**未実装（READMEのNext Steps）:** hover、references、rename（将来課題として明記）

**Spring Boot / Gradle対応:**
ワークスペース初期化時にMaven/Gradleプロジェクトを自動検出する機能あり（`initializeWorkspace(path)` がMaven/Gradleプロジェクトを認識してレポートする）。✅両対応（検出レベル）。READMEのコードに「(Maven project)」「Gradle」の検出言及あり。Spring Boot固有の機能はなし。

**特筆事項:**
- jdtls-mcpの「前身実験」として位置付け（README相互参照あり）
- HTTP/SSEトランスポート採用（stdio非対応）— Claude Codeのstdio-onlyには標準では接続不可
- Quarkus native binary生成対応（GraalVM）
- Java 25必須（要件が高い）
- JDTLSの自動ダウンロード機能あり
- タグ（リリース）なし
- pushed_at: 2026-03-13（約3ヶ月前）
- スター0
- ライセンス未確認（README/LICENSEファイル未確認）
- WIP状態であることをREADMEで明示

---

### 4. zlsimon-personal/sts5-headless

**ラップ対象LSP:**
Spring Tools 5 (STS5) の内蔵MCPサーバー + headless jdt.ls を橋渡しする構成。STS5のspring-boot-language-serverとjdt.lsを同一ハーネスJVMで起動し、Spring意味論をMCPとして公開。JDTLSはSTS5がspring-boot-language-serverに提供するために必要とするもの（Spring固有機能に特化）。

**Java機能カバレッジ（Spring意味論特化・4ツール）:**
- `getProjectList` — プロジェクト一覧とSpring Boot版数の取得
- `getSpringBootVersion` — Spring Bootバージョン確認
- `getBeanDetails` — Beanグラフ・DI注入先・ソース位置の取得（セッションスコープでフィルタリング）
- `getRequestMappings` — リクエストマッピング（エンドポイント）の取得

**通常のJava LSP機能（completion/definition/references/hover/diagnostics等）はMCPツールとして公開していない。** これらはjdt.lsが内部的に動作するがSTS5への入力として使われるのみ。

**Spring Boot / Gradle対応:**
Spring Boot専用（✅）。Maven Spring Bootプロジェクトを明示ターゲット（テスト済み）。Gradleはテスト範囲外（未確認）。

**特筆事項:**
- Alpha/unofficial/proof-of-concept。Broadcom/Springチームと無関係。
- STS5 v2.1.1 / STS5.1.1.RELEASE + Eclipse jdt.ls 1.58.0を固定pinした `third_party.lock` とSHA-256検証機構を持つ（セキュリティ意識高め）
- マルチプロジェクト対応設計（複数Claudeセッションで1ハーネス共有、セッションスコープでfail-closed）
- アイドルリーパー機能（600秒でハーネス自動停止）
- ビルドターゲットはJDK 25（macOS arm64でテスト済み; Linuxは未テスト）
- reverse-engineeredなSTS5内部依存あり（STS5更新で壊れるリスク）
- Gradleプロジェクト対応は未確認
- タグ（リリース）なし
- pushed_at: 2026-05-23（約1ヶ月前）
- スター0
- ライセンス EPL-2.0（Otherとして表示されているが README でEPL-2.0と明記）
- シム（sts5-mcp-shim.sh）はmacOS限定

---

## 追加検索メモ

実施した検索クエリ（重複なし）:
- `jdt mcp server language` → 4件ヒット（上記4件を含む）
- `jdtls mcp java language server` → stephanj/LSP4J-MCPのみ
- `lsp4j mcp server eclipse` → stephanj/LSP4J-MCPのみ
- `java language server mcp model context protocol eclipse` → 2件（stephanj/LSP4J-MCP, sunix/java-lsp-mcp-server）
- `java lsp mcp spring boot language server` → 0件
- `spring boot mcp server language intelligence eclipse` → 0件
- `eclipse jdt ls mcp tool code intelligence java` → 0件

カテゴリBの空間は比較的少数の実装に集中している。新規候補の出現は確認できなかった。

---

## 候補の関係図

```
sunix/java-lsp-mcp-server  →（前身実験・改良版として）→  sunix/jdtls-mcp
      （HTTP/SSE, Quarkus,                                     （OSGi内蔵, stdio,
        jdtls外部プロセス）                                      jdtls同一JVM）

stephanj/LSP4J-MCP                                   zlsimon-personal/sts5-headless
（LSP4Jブリッジ, stdio,                               （STS5+jdt.ls橋渡し,
  jdtls外部プロセス）                                  Spring意味論特化）
```
