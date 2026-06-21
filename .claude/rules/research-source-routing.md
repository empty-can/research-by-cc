# 外部情報源・調査経路の選択ルール

外部情報を調査する際の経路選択ルール。本リポジトリ固有性が薄く、他研究リポジトリへも配布可能な汎用ルール。`paths:` を持たないため毎セッション無条件ロードされる。

> **暫定運用**: 本ルールは本格的なローカル RAG 構築完了までの繋ぎ。完成後は調査ルートが変わり、本ルールは更新または Skill 化される（`research-for-local-RAG-for-cc/improvements/C01-001` / `C01-003` 参照）。

## 大原則: ローカル取得 + Grep を優先

調査対象が GitHub リポジトリ等の**ローカルに一括取得できるリソース**なら、オンラインに WebFetch するより、ローカルに DL/clone して Grep で検索する方が効率が良い。llms.txt など LLM 向けナビゲーションファイルがあれば、Web ページを Fetch するより直接 Grep する方が速いため、**必ず llms.txt の Read → llms-full.txt の Grep** を行う。

したがって、調査対象がローカル取得できる見込みがある場合、Claude は作業指示者に**事前ローカル取得の可否を確認**し、取得不可の回答を得て初めて WebFetch を使う。

ただし以上は**調査対象を取得・精読する段階**の原則であり、その前段の**「どの資料を読むか」を探す discovery 段階は本ルールの適用外**で、オンライン検索を使ってよい。discovery 段階の経路:

- **一般 web の探索 → `WebSearch` を第一選択**（クエリで候補資料・URL を特定する用途。検索エンジンの結果ページ URL を `WebFetch` で叩かない）
- **情報源が特定済みなら専用検索を使う**: Anthropic 公式＝ローカル llms.txt の Grep ／ AWS＝`mcp__awslabs__search_documentation` ／ ライブラリ＝`mcp__context7__resolve-library-id`（いずれも下表の経路で discovery 兼用）
- **読む対象が定まったら、取得・精読は本ルール（ローカル優先＋下表の経路）に戻る**

## 情報源別の調査経路（第一選択 → フォールバック）

第一選択が失敗・不適合の場合のみフォールバックを使う。

| 情報源 | 第一選択 | フォールバック |
|---|---|---|
| Claude Code / Anthropic 公式 docs | ローカル DL 済み llms.txt + Grep（下記手順） | WebFetch |
| AWS 公式 docs | `mcp__awslabs__search_documentation` → `read_documentation` / `read_sections` | WebFetch on `docs.aws.amazon.com` |
| ライブラリ docs（npm / PyPI / 言語標準ライブラリ等） | `mcp__context7__resolve-library-id` → `query-docs` | WebFetch |
| 一般 web（上記以外） | WebFetch（精読）。探す段階は `WebSearch` | — |

### Anthropic 公式 docs の調査手順

1. **セッション開始時に llms.txt をコンテキストに保持**: `research-for-local-RAG-for-cc/resources/references/claude-code-llms.txt` を Read し、全ページカタログを保持する
2. **内容確認はローカル DL 済みファイルを優先**（WebFetch は基本使わない）:
   - 全文: `research-for-local-RAG-for-cc/resources/references/claude-code-llms-full.txt`
   - 構造（見出し階層）: `research-for-local-RAG-for-cc/resources/references/claude_code_docs_map.md`
3. **WebFetch を使う条件**: ローカル DL でカバーされない情報（最新 whats-new の未 DL 分等）に限定する

> **根拠**: WebFetch はネットワーク I/O + Anthropic 側レンダリング往復のコストが発生するが、ローカル Grep は実質ゼロコスト。同等の情報がローカルにあるならローカル参照がほぼ確実にローコスト。
>
> **現スコープ**: ローカル llms.txt + Grep 戦略は **Anthropic 公式ドキュメント限定**で機能する（他公式は上表の経路を使う）。ローカル DL 済みドキュメントの**マシン依存の実体絶対パス**は `CLAUDE.local.md` に定義する（`CLAUDE.local.md.example` 参照）。

## ファイル操作・Web fetch: MCP vs built-in

ファイル操作と Web fetch は **built-in tools を第一選択**とし、MCP 版は「built-in に対して明確な優位性がある場面」に限定する。

| 用途 | 第一選択（built-in） | MCP を使う条件 |
|---|---|---|
| ファイル読み書き・編集 | Read / Write / Edit | （MCP 不要、built-in で十分） |
| 複数ファイル一括読み込み | Read を複数回 | `mcp__filesystem__read_multiple_files` — ターン削減効果が顕著な時のみ |
| ディレクトリ階層俯瞰 | Glob `**/*` 等 | `mcp__filesystem__directory_tree` — JSON 構造化出力が必要な時のみ |
| ファイル / 内容検索 | Glob / Grep | （MCP 不要、built-in が高速） |
| ファイル移動・作成 | Bash `mv` / `mkdir` | （MCP 不要） |
| Web 取得 + 要約 | WebFetch | （MCP 不要） |
| 生 HTML / バイナリ / PDF 取得 | — | `mcp__fetch__fetch` — WebFetch は要約処理が入るため不向き |
| WebFetch がリダイレクト等で失敗 | — | `mcp__fetch__fetch` をフォールバックとして使用 |
