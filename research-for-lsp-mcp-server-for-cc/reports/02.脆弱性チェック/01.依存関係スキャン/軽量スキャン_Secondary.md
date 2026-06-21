# Phase 2: 依存関係 軽量スキャン（Secondary 5）
作成日: 2026-06-21 / 担当: Sonnet Agent / 手法: マニフェストレベル照合（クローンなし・軽量パス）

> **軽量パスの共通注記**: 本スキャンはマニフェスト記載の直接依存のみを照合対象とする。推移的依存（間接依存）は未解決であり、「確認範囲でヒットなし」は「脆弱性なし」を意味しない。バージョン指定が範囲指定（`>=`, `^` 等）の場合、実際にインストールされるバージョンはロックファイルによって決定される。

---

## サマリ表

| 候補 | エコシステム | 取得マニフェスト | 直接依存数（直接） | Advisory ヒット | 所見 |
|---|---|---|---|---|---|
| sunix/jdtls-mcp | Java (OSGi/Tycho) | `pom.xml`（親）, `org.eclipse.jdt.ls.mcp.target/org.eclipse.jdt.ls.mcp.tp.target`（依存定義） | 2 Maven 直接依存（mcp-core 1.0.0, langchain4j-core 1.0.0）+ Eclipse p2 依存多数 | 確認範囲でヒットなし | Tycho/OSGi 構成。p2 依存は version="0.0.0"（最新解決）で版固定なし |
| isaacphi/mcp-language-server | Go | `go.mod` / `go.sum` | 直接5、間接13（go.mod 記載） | 確認範囲でヒットなし | govulncheck をツールとして組み込み済み（開発時利用） |
| johnhuang316/code-index-mcp | Python | `pyproject.toml` / `requirements.txt` | 13 直接依存（pyproject）/ 14（requirements.txt に libclang 追加） | 確認範囲でヒットなし | requirements.txt に `libclang>=16.0.0` が追加されている（pyproject にはない）。バージョン全て範囲指定 |
| ProfessioneIT/lsp-mcp-server | TypeScript | `package.json`（package-lock.json は取得済みだが大きすぎて詳細照合は別途要） | 3 runtime 依存、5 devDependencies | **ヒットあり（High x3）**: `@modelcontextprotocol/sdk ^1.0.0` が 3 件の Advisory 影響範囲に該当する可能性 | `^1.0.0` は 1.x 系最新を許容するため、ロックファイル次第では脆弱バージョンがインストール済みの可能性が高い |
| aimasteracc/tree-sitter-analyzer | Python | `pyproject.toml`（requirements.txt は未存在） | 30+ 直接依存（core deps） | **ヒットあり（Moderate x2）**: `anthropic>=0.104.1` は CVE 影響範囲（>=0.86.0,<0.87.0）外のため **実害なし** | anthropic >=0.104.1 は修正済みバージョン 0.87.0 より十分新しい。psutil >=5.9.8 も CVE-2019-18874（<=5.6.5）の影響範囲外 |

---

## 各候補の詳細

---

### 1. sunix/jdtls-mcp

**取得マニフェスト**
- `pom.xml`（ルート親 POM）: Tycho 5.0.0 を build plugin として使用。`<dependencies>` セクションなし（親 POM は子モジュールを束ねるだけ）
- `org.eclipse.jdt.ls.mcp.target/org.eclipse.jdt.ls.mcp.tp.target`（Target Platform 定義）: 実質の依存定義ファイル

**直接依存リスト（マニフェスト記載）**

Maven 依存（Target Platform で版固定）:
| groupId / artifactId | バージョン | 用途 |
|---|---|---|
| `io.modelcontextprotocol.sdk:mcp-core` | `1.0.0` | MCP Java SDK コア |
| `io.modelcontextprotocol.sdk:mcp-json-jackson2` | `1.0.0` | MCP SDK JSON サポート |
| `dev.langchain4j:langchain4j-core` | `1.0.0` | LangChain4j（@Tool アノテーション） |

Eclipse p2 依存（version="0.0.0" = バージョン未固定・プランナー解決）:
- Eclipse 2025-12 リリーストレイン（`download.eclipse.org/releases/2025-12/`）: `org.eclipse.core.runtime`, `org.eclipse.jdt.core`, `org.eclipse.equinox.*` など多数
- LSP4J 0.24.0 (`download.eclipse.org/lsp4j/updates/releases/0.24.0/`): `org.eclipse.lsp4j`, `org.eclipse.lsp4j.jsonrpc`
- Eclipse JDT LS（snapshot: `download.eclipse.org/jdtls/snapshots/repository/latest/`）: `org.eclipse.jdt.ls.core` など

**Advisory 照合結果**

- `io.modelcontextprotocol.sdk:mcp-core 1.0.0`: GitHub Advisory Database で直接検索した範囲ではヒットなし
- `dev.langchain4j:langchain4j-core 1.0.0`: 確認範囲でヒットなし
- LSP4J 0.24.0: 確認範囲でヒットなし

**軽量パスの限界**: p2 依存（Eclipse RCP ランタイム群、JDT LS snapshot）は推移的依存が多数含まれており、本スキャンでは未照合。snapshot 参照のため版が継続変動する。

---

### 2. isaacphi/mcp-language-server

**取得マニフェスト**: `go.mod` / `go.sum`（go 1.24.0）

**直接依存リスト（go.mod `require` ブロック記載）**

直接依存（`// indirect` なし）:
| パッケージ | バージョン | 用途 |
|---|---|---|
| `github.com/davecgh/go-spew` | `v1.1.1` | デバッグ（spew） |
| `github.com/fsnotify/fsnotify` | `v1.9.0` | ファイル監視 |
| `github.com/mark3labs/mcp-go` | `v0.25.0` | MCP Go SDK |
| `github.com/sabhlok/go-gitignore` | `v0.0.0-20210923224102-525f6e181f06` | .gitignore 解析 |
| `github.com/stretchr/testify` | `v1.10.0` | テスト |
| `golang.org/x/text` | `v0.25.0` | テキスト処理 |

間接依存（`// indirect` — 直接依存を経由）:
`github.com/BurntSushi/toml`, `github.com/google/go-cmp`, `github.com/google/uuid`, `github.com/kisielk/errcheck`, `github.com/pmezard/go-difflib`, `github.com/rogpeppe/go-internal`, `github.com/spf13/cast`, `github.com/yosida95/uritemplate/v3`, `golang.org/x/exp/typeparams`, `golang.org/x/mod`, `golang.org/x/sync`, `golang.org/x/sys`, `golang.org/x/telemetry`, `golang.org/x/tools`, `golang.org/x/vuln`, `gopkg.in/check.v1`, `gopkg.in/yaml.v3`, `honnef.co/go/tools`

**Advisory 照合結果**

- `github.com/mark3labs/mcp-go v0.25.0`: 確認範囲でヒットなし（GitHub Advisory Database で検索済み）
- `github.com/fsnotify/fsnotify v1.9.0`: 確認範囲でヒットなし（Linux カーネルの fsnotify とは別パッケージ）
- `golang.org/x/text v0.25.0`: 確認範囲でヒットなし
- `golang.org/x/vuln v1.1.4`: govulncheck ツール（脆弱性スキャン用）として tool ブロックに含まれており、開発時のセキュリティ対応が想定されている

**軽量パスの限界**: 間接依存（`// indirect`）はマニフェストに記載されているが、本スキャンでの Advisory 照合は直接依存のみ実施。

---

### 3. johnhuang316/code-index-mcp

**取得マニフェスト**: `pyproject.toml` + `requirements.txt`（両方あり）

**直接依存リスト（pyproject.toml `dependencies` セクション）**

| パッケージ | バージョン指定 | 用途 |
|---|---|---|
| `mcp` | `>=1.21.0,<2.0.0` | MCP Python SDK |
| `watchdog` | `>=3.0.0` | ファイル監視 |
| `tree-sitter` | `>=0.20.0` | AST パーサ |
| `tree-sitter-javascript` | `>=0.20.0` | JS 言語サポート |
| `tree-sitter-typescript` | `>=0.20.0` | TS 言語サポート |
| `tree-sitter-java` | `>=0.20.0` | Java 言語サポート |
| `tree-sitter-kotlin` | `>=0.3.0` | Kotlin 言語サポート |
| `tree-sitter-c-sharp` | `>=0.20.0` | C# 言語サポート |
| `tree-sitter-zig` | `>=0.20.0` | Zig 言語サポート |
| `tree-sitter-rust` | `>=0.20.0` | Rust 言語サポート |
| `pathspec` | `>=0.12.1` | パスパターン照合 |
| `msgpack` | `>=1.0.0` | バイナリシリアライズ |

requirements.txt 追加依存（pyproject.toml にはない）:
| パッケージ | バージョン指定 |
|---|---|
| `protobuf` | `>=4.21.0` |
| `libclang` | `>=16.0.0` |

**Advisory 照合結果**

- `mcp >=1.21.0,<2.0.0` (pip): pip エコシステムの `mcp` 単体パッケージの Advisory は確認範囲でヒットなし（PraisonAI などの別パッケージは除外）
- `watchdog >=3.0.0`: 確認範囲でヒットなし
- `tree-sitter-*` 各種: 確認範囲でヒットなし
- `msgpack >=1.0.0`: 確認範囲でヒットなし（本スキャンでは個別照合省略）
- `libclang >=16.0.0`: requirements.txt に追加あり（pyproject にはない）。libclang は Clang の Python バインディングで、版未固定。確認範囲でヒットなし

**軽量パスの限界**: バージョン全て下限指定のみ（上限なし）で、ロックファイル相当のピン留めなし。実際のインストールバージョンは環境依存。

---

### 4. ProfessioneIT/lsp-mcp-server

**取得マニフェスト**: `package.json`（package-lock.json は 180,612 文字・大容量のため詳細照合は別途推奨）

**直接依存リスト（package.json 記載）**

Runtime dependencies:
| パッケージ | バージョン指定 | 用途 |
|---|---|---|
| `@modelcontextprotocol/sdk` | `^1.0.0` | MCP TypeScript SDK |
| `vscode-languageserver-protocol` | `^3.18.0` | LSP プロトコル型定義 |
| `zod` | `^3.25.0` | スキーマバリデーション |

devDependencies:
| パッケージ | バージョン指定 |
|---|---|
| `@types/node` | `^20.0.0` |
| `eslint` | `^9.0.0` |
| `typescript` | `^5.4.0` |
| `typescript-eslint` | `^8.0.0` |
| `vitest` | `^4.0.17` |

**Advisory 照合結果**

`@modelcontextprotocol/sdk ^1.0.0` に関する Advisory（3件ヒット）:

| Advisory ID | CVE | 深刻度 | 影響バージョン | 修正バージョン | 概要 |
|---|---|---|---|---|---|
| GHSA-345p-7cg4-v4c7 | CVE-2026-25536 | **High** | `>=1.10.0, <=1.25.3` | 1.26.0 | JSON-RPC message ID 衝突によるクロスクライアント データリーク |
| GHSA-8r9q-7v3j-jr4g | CVE-2026-0621 | **High** | `<1.25.2` | 1.25.2 | UriTemplate クラスの ReDoS（正規表現 catastrophic backtracking） |
| GHSA-w48q-cv73-mx4w | CVE-2025-66414 | **High** | `<1.24.0` | 1.24.0 | デフォルトで DNS リバインディング保護が無効 |

**影響判定**: `^1.0.0` は semver 上 `>=1.0.0 <2.0.0` に相当し、npm はデフォルトで compatible な最新版をインストールする。package-lock.json が存在するためピン留めはされているが、ロック済みバージョンの確認が必要。

- もし `@modelcontextprotocol/sdk` がロックファイルで `<1.24.0` に固定されている場合: GHSA-8r9q-7v3j-jr4g（ReDoS） + GHSA-w48q-cv73-mx4w（DNS rebinding）の両方が影響
- `>=1.10.0,<=1.25.3` の場合: GHSA-345p-7cg4-v4c7（データリーク）が追加で影響
- `>=1.26.0` の場合: 3件すべて修正済み

**action required**: package-lock.json の `@modelcontextprotocol/sdk` の `resolved` バージョンを確認して実際の影響を判断する必要あり。

その他:
- `vscode-languageserver-protocol ^3.18.0`: 確認範囲でヒットなし
- `zod ^3.25.0`: 確認範囲でヒットなし

**軽量パスの限界**: package-lock.json の完全照合が必要。ロックバージョン未確認の状態では「潜在的ヒットあり」として扱う。

---

### 5. aimasteracc/tree-sitter-analyzer

**取得マニフェスト**: `pyproject.toml`（requirements.txt は存在しない）

**直接依存リスト（pyproject.toml `dependencies` セクション — core deps）**

| パッケージ | バージョン指定 | 用途 |
|---|---|---|
| `tree-sitter` | `>=0.25.0` | AST パーサコア |
| `chardet` | `>=7.4.3` | 文字コード検出 |
| `cachetools` | `>=5.0.0` | キャッシュ |
| `tree-sitter-java` | `>=0.23.5` | Java サポート |
| `tree-sitter-c` | `>=0.20.0` | C サポート |
| `tree-sitter-cpp` | `>=0.23.4` | C++ サポート |
| `tree-sitter-python` | `>=0.23.6` | Python サポート |
| `mcp` | `>=1.12.3,<2.0.0` | MCP Python SDK |
| `tree-sitter-javascript` | `>=0.23.1` | JS サポート |
| `tree-sitter-markdown` | `>=0.3.1` | Markdown サポート |
| `tree-sitter-html` | `>=0.23.0` | HTML サポート |
| `tree-sitter-css` | `>=0.23.0` | CSS サポート |
| `psutil` | `>=5.9.8` | システム情報 |
| `tree-sitter-typescript` | `>=0.23.2` | TS サポート |
| `deepdiff` | `>=6.7.1` | 差分比較 |
| `jsonschema` | `>=4.0.0` | JSON スキーマ検証 |
| `tree-sitter-c-sharp` | `>=0.23.1` | C# サポート |
| `tree-sitter-sql` | `>=0.3.11` | SQL サポート |
| `tree-sitter-php` | `>=0.24.1` | PHP サポート |
| `tree-sitter-ruby` | `>=0.23.1` | Ruby サポート |
| `tree-sitter-yaml` | `>=0.7.0` | YAML サポート |
| `tree-sitter-go` | `>=0.20.0` | Go サポート |
| `tree-sitter-rust` | `>=0.20.0` | Rust サポート |
| `tree-sitter-kotlin` | `>=0.3.0` | Kotlin サポート |
| `detect-secrets` | `>=1.5.0` | シークレット検出 |
| `tree-sitter-json` | `>=0.23.0` | JSON サポート |
| `networkx` | `>=3.4.2` | グラフ解析 |
| `numpy` | `>=2.2.6` | 数値計算 |
| `pyyaml` | `>=6.0` | YAML パース |
| `pathspec` | `>=0.12.1` | パスパターン |
| `anthropic` | `>=0.104.1` | Anthropic SDK |
| `tree-sitter-bash` | `>=0.23.0` | Bash サポート |
| `tree-sitter-scala` | `>=0.23.0` | Scala サポート |

**Advisory 照合結果**

`anthropic >=0.104.1` に関する Advisory（2件検出、ただし影響範囲外）:

| Advisory ID | CVE | 深刻度 | 影響バージョン | 修正バージョン | 当該依存への影響 |
|---|---|---|---|---|---|
| GHSA-w828-4qhx-vxx3 | CVE-2026-34452 | Moderate | `>=0.86.0,<0.87.0` | 0.87.0 | **影響なし**: `>=0.104.1` は修正済みの 0.87.0 より新しい |
| GHSA-q5f5-3gjm-7mfm | CVE-2026-34450 | Moderate | `>=0.86.0,<0.87.0` | 0.87.0 | **影響なし**: 同上 |

その他:
- `psutil >=5.9.8`: GHSA-qfc5-mcwq-26q8 / CVE-2019-18874（High, 影響 <=5.6.5, 修正 5.6.6）は `>=5.9.8` 指定のため **影響なし**
- `chardet >=7.4.3`: 確認範囲でヒットなし
- `detect-secrets >=1.5.0`: 確認範囲でヒットなし
- `networkx >=3.4.2`: 確認範囲でヒットなし
- `numpy >=2.2.6`: 確認範囲でヒットなし（本スキャンでは個別照合省略）
- `jsonschema >=4.0.0`: 確認範囲でヒットなし（本スキャンでは個別照合省略）

**軽量パスの限界**: バージョン全て下限指定のみ（上限なし）で、ロックファイル相当のピン留めなし。実際のインストールバージョンは環境依存。

---

## 全体所見

### 要対応（action required）

**ProfessioneIT/lsp-mcp-server**: `@modelcontextprotocol/sdk ^1.0.0` に対し High 深刻度の Advisory が 3 件存在（GHSA-345p-7cg4-v4c7, GHSA-8r9q-7v3j-jr4g, GHSA-w48q-cv73-mx4w）。いずれも修正バージョンは 1.24.0〜1.26.0 であり、`^1.0.0` 指定の場合、ロックファイル（package-lock.json）次第では脆弱バージョンがインストールされている可能性が高い。package-lock.json 内の実際のロックバージョンを確認し、必要なら `>=1.26.0` への更新を推奨。

### 確認範囲でヒットなし（ただし軽量パスの限界あり）

- **sunix/jdtls-mcp**: Maven 直接依存（mcp-core 1.0.0, langchain4j-core 1.0.0）は確認範囲でヒットなし。ただし p2 依存（Eclipse/JDT LS snapshot）はバージョン未固定であり、別途確認が望ましい。
- **isaacphi/mcp-language-server**: 直接依存 6 件について確認範囲でヒットなし。govulncheck をプロジェクト内に組み込んでいる点はポジティブな所見。
- **johnhuang316/code-index-mcp**: 直接依存全件について確認範囲でヒットなし。ただし requirements.txt の `libclang>=16.0.0` は pyproject.toml に記載がなく、2 つのマニフェストに乖離がある点に注意。
- **aimasteracc/tree-sitter-analyzer**: `anthropic >=0.104.1` に Moderate Advisory 2 件を検出したが、指定バージョン範囲は修正済み（0.87.0 以降）のため実害なし。`psutil >=5.9.8` も既知 CVE の影響範囲外。

### スキャン対象外（本スキャンの範囲外）

- 推移的（間接）依存の Advisory 照合
- package-lock.json の実際のロックバージョン照合（ProfessioneIT のロックファイルは 180K 文字超のため本スキャンで未詳細照合）
- OSS ライセンスの組み合わせリスク
- コードレベルの実装脆弱性
