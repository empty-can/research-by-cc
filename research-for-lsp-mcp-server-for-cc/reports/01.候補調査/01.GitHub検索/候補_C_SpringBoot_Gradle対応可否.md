# 候補調査 C: Spring Boot / Gradle 対応可否
作成日: 2026-06-21 / 担当: Agent C

## 結論サマリ

Spring Boot 特化・Gradle 特化の LSP 連携型 MCP Server は現時点で存在しない（専用サーバは確認不可）。  
ただし両者とも汎用ブリッジ経由の接続経路は存在する。  
**Spring Boot** は `spring-projects/spring-tools` に含まれる `spring-boot-language-server` が LSP 実装として存在し、`.vsix` から JAR を抽出すれば `isaacphi/mcp-language-server` や `rockerBOO/mcp-lsp-bridge` 等の汎用ブリッジに接続可能と見込まれる。ただし JDT-LS との共存が必須で、ドキュメントに「tbd」箇所が多く、セットアップ難度は高い。  
**Gradle** は `microsoft/vscode-gradle` の gradle-language-server が **named pipes** 通信のみで stdio 非対応のため汎用ブリッジへの直結は困難。一方で `gradle/declarative-lsp` は JAR 単独起動が可能だが Declarative Gradle 構文専用。Gradle ビルド操作（タスク実行・依存確認）に特化した MCP Server（`rnett/gradle-mcp`、Develocity MCP Server）は別途存在する。

---

## Part 1: 専用 MCP Server 存在確認

### 探索クエリ一覧

| # | クエリ | 手段 | ヒット |
|---|---|---|---|
| 1 | "spring boot mcp language server" | GitHub search_repositories | 0件（LSP 連携型は 0 件。Spring AI で MCP サーバを作るデモ等のみ） |
| 2 | "spring-tools mcp lsp" | GitHub search_repositories | 0件 |
| 3 | "spring boot language server mcp protocol" | GitHub search_repositories | 4件（いずれも Spring Boot で MCP サーバを構築するデモ。LSP ブリッジではない） |
| 4 | "spring boot mcp language server LSP" | WebSearch | LSP 連携型の Spring Boot 専用 MCP Server は出現せず |
| 5 | "gradle mcp language server LSP" | GitHub search_repositories | 0件 |
| 6 | "gradle lsp mcp", "build server protocol mcp" | GitHub search_repositories | 0件 |
| 7 | "gradle mcp language server LSP" | WebSearch | ビルド操作専用の Gradle MCP が複数出現（LSP 機能なし） |
| 8 | "spring boot language server mcp lsp bridge" | GitHub search_repositories | 0件 |
| 9 | "build server protocol bsp mcp" | GitHub search_repositories | 0件 |

### 発見された近縁リポジトリ（専用ではないが言及に値するもの）

| リポジトリ | 内容 | 備考 |
|---|---|---|
| `thomas-hochbichler/spring-ai-mcp-actuator` | Spring Boot Actuator を MCP で公開するデモ | LSP 機能なし・言語補完と無関係 |
| `brunosantoslab/spring-mcp-bridge` | Spring Boot REST エンドポイントを MCP に変換 | LSP 機能なし |
| `IlyaGulya/gradle-mcp-server` | Gradle Tooling API でプロジェクト情報・タスク実行 | 2026-03-14 アーカイブ済み・LSP 機能なし |
| `rnett/gradle-mcp` | Gradle ビルド・テスト・依存関係確認に特化した MCP | LSP 機能なし（後述 Part 2 参照） |

**判定: Spring Boot 専用・Gradle 専用の「LSP 連携型 MCP Server」は存在しない。**

---

## Part 2: 言語サーバ本体と汎用ブリッジ接続可否

### Spring Boot

#### spring-boot-language-server の実在と提供機能

- **リポジトリ**: `spring-projects/spring-tools` > `headless-services/spring-boot-language-server`  
  URL: https://github.com/spring-projects/spring-tools/tree/main/headless-services/spring-boot-language-server
- **実在**: 確認済み（970 stars、2026 年 6 月に v5.2.0.RELEASE リリース、活発に保守）
- **スタンドアロン版**: `headless-services/spring-boot-language-server-standalone` モジュールも存在（`src/` + `pom.xml` 構成）
- **提供機能（公式記載より）**: Spring Boot プロパティファイルのコード補完・バリデーション、Java ファイルの Spring Boot 固有診断・クイックフィックス、Cloud Foundry manifest / BOSH deployment / Concourse CI の補完もサポート
- **配布形式**: Maven アーティファクトとしての公式単独配布はなし。VSCode 拡張 `.vsix` ファイル（ZIP）内の JAR を抽出して利用するのが現実的な入手方法（出典: https://github.com/spring-projects/spring-tools/wiki/Developer-Manual-Integrate-Language-Server-Into-Client）
- **依存関係**: JDT Language Server（eclipse.jdt.ls）が別プロセスで動作している必要あり（出典: 上記 Wiki）

#### 汎用ブリッジ接続可否

- `isaacphi/mcp-language-server`（1.6k stars）: 「`--lsp` フラグで任意のLSPバイナリを指定、それ以降の引数をサーバに渡す」「言語サーバは stdio で通信する必要がある」と README に明記（出典: https://github.com/isaacphi/mcp-language-server）。spring-boot-language-server は LSP プロトコル準拠であり、stdio 起動が可能なら接続できる設計。ただし Java/Spring Boot は言及なし。
- `jonrad/lsp-mcp`（187 stars）: `--lsp` 引数で任意のサーバコマンドを指定可能（出典: https://github.com/jonrad/lsp-mcp）。同様に接続できる設計だが、複数 LSP 同時使用は未対応と明記。
- `rockerBOO/mcp-lsp-bridge`（29 stars）: `lsp_config.json` で LSP を指定可能、対応言語例に「Java」を明記（出典: https://github.com/rockerBOO/mcp-lsp-bridge）。ただし 2025-08 時点で v0.2.0、active development 段階。

**接続可否判定**: 「spring-boot-language-server が stdio モードで起動できる」前提であれば、汎用ブリッジ（特に isaacphi/mcp-language-server）への接続は**構造的には可能**。ただし実際の起動手順は Wiki に「tbd」が残っており、JDT-LS との連携セットアップも含めると **難度高・未実証**。

---

### Gradle

#### gradle-language-server（microsoft/vscode-gradle）

- **リポジトリ**: `microsoft/vscode-gradle` > `gradle-language-server/`  
  URL: https://github.com/microsoft/vscode-gradle
- **実在**: 確認済み（170 stars、2026-04-16 に v3.17.3 リリース、保守中）
- **提供機能**: `.gradle` / `.gradle.kts` ファイルの構文補完・エラー診断・シンボルナビゲーション（Groovy パーシングと Gradle API を使用）
- **通信方式**: **named pipes のみ**（出典: GitHub ARCHITECTURE.md の記述 + DeepWiki 解説。Windows では TypeScript 層 BspProxy 経由）。stdio では動作しない。
- **汎用ブリッジ接続可否**: **不可**。現状の汎用 LSP→MCP ブリッジ（isaacphi 等）は stdio を前提とする。named pipes 専用サーバをそのまま接続することはできない。

#### gradle/declarative-lsp

- **リポジトリ**: https://github.com/gradle/declarative-lsp
- **実在**: 確認済み（8 stars、初期段階・小規模）
- **対象**: Declarative Gradle 構文専用（`build.gradle` / `build.gradle.kts` の汎用的な LSP ではない）
- **配布**: `./gradlew shadowJar` でビルドした `lsp-all.jar` が実行可能 JAR として利用可能
- **通信方式**: 明示記載なし（lsp4j ベースの典型的実装なら stdio 対応の可能性あり）
- **汎用ブリッジ接続可否**: **未確認**（stdio 対応を確認できていないため「未確認」）。対象が Declarative Gradle 専用という点でも用途が限定的。

#### BSP（Build Server Protocol）と MCP

- BSP は JetBrains/Scala/Bloop 系のビルドサーバー接続プロトコルであり、LSP→MCP ブリッジとは別経路。
- BSP と MCP を橋渡しする実装は GitHub 検索・WebSearch いずれでも確認できず。

#### Gradle 向けビルド操作専用 MCP（参考）

以下は LSP 機能（コード補完・診断）ではなく、Gradle ビルド操作に特化した MCP Server。LSP 連携の代替にはならない。

| リポジトリ | 機能 | 状態 |
|---|---|---|
| `rnett/gradle-mcp` | ビルド・テスト・依存関係・Kotlin REPL | アクティブ（52 stars、v0.0.11） |
| Develocity MCP Server | CI ビルド情報・テスト分析（Develocity 2025.3+必須） | 公式（有料製品付帯）|
| `IlyaGulya/gradle-mcp-server` | Gradle Tooling API でタスク実行 | **アーカイブ済み** 2026-03-14 |

---

## 対応可否マトリクス

| 経路 | Spring Boot | Gradle | 備考 |
|---|---|---|---|
| 専用 LSP MCP Server | 存在しない | 存在しない | 両者とも調査範囲で出現せず |
| 汎用ブリッジ（isaacphi/mcp-language-server） | **条件付き可**（stdio起動が前提） | **不可**（gradle-language-serverがnamed pipes専用のため） | spring-bootは要 JDT-LS 同時起動、Spring固有機能（プロパティ補完等）は提供 |
| 汎用ブリッジ（jonrad/lsp-mcp） | **条件付き可**（同上） | **不可**（同上） | 複数 LSP 同時使用不可の制限あり |
| 汎用ブリッジ（rockerBOO/mcp-lsp-bridge） | **条件付き可**（Java 言語への対応を明記） | **不可**（同上） | v0.2.0・active dev 段階 |
| gradle/declarative-lsp + 汎用ブリッジ | 対象外 | **未確認**（stdio対応要確認・Declarative Gradle専用） | lsp4j ベースなら stdio 対応の可能性 |
| Gradle ビルド操作専用 MCP（rnett/gradle-mcp） | 対象外 | コード補完目的には**不可**（ビルド操作専用） | Gradle タスク実行・依存確認は可能 |

---

## 要注意点

1. **spring-boot-language-server の stdio 起動は未文書化**: Wiki の「Developer Manual Integrate Language Server Into Client」は「tbd」箇所が多く、stdio で単独起動する公式コマンドが現時点では不明。`.vsix` 解凍して JAR を特定 → 実際に `--stdio` オプション等で起動できるか要実機検証。
2. **JDT-LS 共存が必須**: spring-boot-language-server は Eclipse JDT Language Server に依存しており、単独では Java 基本補完が提供できない。セットアップが 2 層構造になる。
3. **gradle-language-server の named pipes 制約は回避困難**: 汎用ブリッジの接続前提（stdio）と相性が悪い。named pipes 対応のブリッジ実装が存在すれば別だが、確認できていない。
4. **Gradle 向け代替**: コード補完・診断ではなく「Gradle ビルド操作を AI に任せる」目的であれば `rnett/gradle-mcp` が実用的。ただし LSP 的な用途（エディタ支援）とは別物。
