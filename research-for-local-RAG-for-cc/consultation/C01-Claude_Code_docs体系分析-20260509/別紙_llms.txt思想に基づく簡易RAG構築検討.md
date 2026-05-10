# 別紙: llms.txt 思想に基づく簡易 RAG 構築検討

## 0. 本別紙の位置付け

C01 相談「Claude Code 公式ドキュメント体系分析」（本紙: `Claude_Code_docs体系分析.md`）の派生検討。本紙の **観点 C「3 ファイル構造が RAG アーキテクチャと同型」** および **結論サマリ「ローカル RAG 構築はスクレイピング不要・公式提供のみで完結可能」** を出発点として、本格的なベクトル検索ベース RAG 構築までの「繋ぎ」として利用できる、整備コストの低い **簡易 RAG** の構築検討を行う。

> **検証ステータスの注記**: 本別紙は、本紙（クロスレビュー Round 3 を経た検証済み）と異なり **未検証の派生提案を含む議論ログ + 結論** として扱う。結論が確定した後、必要に応じてクロスレビュー対象とする。

---

## 1. 背景

### 1.1 動機

本紙の活用方法 3「llms-full.txt をローカル RAG コーパスとして活用」では、本格的なベクトル RAG 構築を前提としたチャンク分割・メタデータ・更新検出の方針が示されている。しかし、本格 RAG 構築には以下のコストが発生する:

- 埋め込みモデル選定 + ベクトル DB セットアップ
- 埋め込み生成（GPU 推奨）
- 更新時の差分埋め込みパイプライン
- 検索精度チューニング

本プロジェクト（local RAG for cc）の主目的は本格 RAG の構築であるため、上記コストは本来の調査・検証の中で発生して然るべきものではあるが、**本格 RAG 完成までの「繋ぎ」として、後続フェーズで Claude Code 公式ドキュメントを参照する場面で利用可能な簡易版** が低コストで構築できれば、後続フェーズの作業効率向上に寄与する。

### 1.2 適用対象とスコープ

| 項目 | 内容 |
|---|---|
| ✅ 対象 | Anthropic 公式 Claude Code ドキュメント（`llms.txt` / `llms-full.txt` / `docs_map` をインプット） |
| 用途想定 | 後続フェーズで Claude Code の公式情報に当たる場面での参照効率化 |
| ❌ 除外 | ローカル文書（`ハマりどころ.md` 等）。事前フォーマッティング作業が必要なため、別フェーズで判断 |

---

## 2. 提案アプローチ: 3 段階ハイブリッド検索

### 2.1 着想の起点

本紙活用方法 3 のチャンク分割・メタデータ活用方針を、ベクトル DB ではなく **SQLite + SQL LIKE + メタデータフィルタ** で実現する案。llms-full.txt は性質上、検索対象本文全量を保持する。これに対して LIKE 検索を直接かけると、**キーワードを含む行の周辺に関連性の薄いテキストがあると LLM 側のコンテキストを汚染するリスク** がある。この課題を、メタデータベースの 2 段階目フィルタで緩和する。

### 2.2 検索フロー

```
Stage 1: SQL LIKE による全文 lexical 検索 → 候補行抽出
Stage 2: 候補のメタデータ（title / description / 見出し階層）を Claude が読む → 意味的絞り込み
Stage 3: 真に必要な本文のみを精読
```

ベクトル RAG が「ベクトル類似度」で意味的絞り込みを行う部分を、Stage 2 で **「LLM がメタデータを読んで判断する」** に置き換えている。これが成立する根拠:

- メタデータは小さいので、複数候補のメタデータを 1 度のコンテキストで比較できる
- LLM はメタデータ + クエリ意図から関連度を判断するのが得意
- 結果として「ベクトル類似度の代替」が実質ゼロ追加コストで実現

### 2.3 SQL DB スキーマ設計（確定）

ソースファイル 3 種の構造をそれぞれ別テーブルにマッピングする方針で確定。個別 `.md` は llms-full.txt に内容が完全包含されるため除外。

```sql
-- Table 1: llms.txt のリンク群（H2 セクション + 1 行説明付き URL リスト）
CREATE TABLE llms_index (
    source_url TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,        -- 1 行説明
    section TEXT             -- 配下にある H2 名（仕様上 optional なため NULL 許容）
);

-- Table 2: llms-full.txt のページ全文
CREATE TABLE llms_full (
    source_url TEXT PRIMARY KEY,
    title TEXT NOT NULL,     -- # 見出し
    body TEXT NOT NULL       -- 本文
);

-- Table 2 の本文 FTS5 インデックス（trigram tokenizer、日本語含む部分一致対応）
CREATE VIRTUAL TABLE llms_full_fts USING fts5(
    title, body,
    content='llms_full',
    content_rowid='rowid',
    tokenize='trigram'
);

-- Table 3: docs_map の見出し階層
CREATE TABLE docs_map (
    source_url TEXT NOT NULL,
    heading_order INTEGER NOT NULL,  -- ページ内の出現順
    heading_level INTEGER NOT NULL,  -- 2=H2, 3=H3, ...
    heading_text TEXT NOT NULL,
    PRIMARY KEY (source_url, heading_order)
);
```

検索クエリ例:

```sql
-- Stage 1+2: FTS でヒットしたページのメタ情報一覧（Claude が読んで絞り込む）
SELECT
    f.source_url,
    f.title,
    i.description,
    i.section,
    GROUP_CONCAT(d.heading_text, ' › ') AS headings
FROM llms_full f
LEFT JOIN llms_index i ON i.source_url = f.source_url
LEFT JOIN docs_map d ON d.source_url = f.source_url
WHERE f.rowid IN (SELECT rowid FROM llms_full_fts WHERE body MATCH ?)
GROUP BY f.source_url;

-- Stage 3: 絞り込み後、本文取得
SELECT body FROM llms_full WHERE source_url = ?;
```

> **注**: FTS5 trigram tokenizer は SQLite 3.34+（2021-01）で利用可能。Python 3.11+ の標準 `sqlite3` モジュールが内包する SQLite で問題なく動作することを構築時に確認する。

### 2.4 構築フロー

1. ingestion スクリプトで `llms.txt` / `llms-full.txt` / `docs_map` をパースし、`docs` / `headings` テーブルに投入
2. Claude Code は SQL クエリ（`sqlite3` CLI 経由 or MCP 経由）で検索を実行
3. 更新時はスクリプトを再実行（埋め込みステップ不要のため低コスト）

---

## 3. ベクトル RAG との比較

### 3.1 コスト構造の比較

| 項目 | ベクトル RAG | 本提案（SQL + LIKE） |
|---|---|---|
| 構築 | 埋め込みモデル選定 + ベクトル DB セットアップ + 埋め込み生成 | SQLite + ingestion スクリプト（数百行）のみ |
| 更新 | 差分埋め込み（GPU 推奨） | スクリプト再実行（CPU で十分） |
| 実行 | クエリ埋め込み + ベクトル検索 + re-rank | SQL LIKE + LLM 判断 |
| 依存 | 埋め込みモデル / ベクトル DB | SQLite（標準ライブラリ） |

→ **簡易 RAG としての繋ぎ用途には、本提案の方が確実にコスト対効果が高い**。

### 3.2 トレードオフ

| 観点 | ベクトル RAG | 本提案 |
|---|---|---|
| 同義語・言い換え対応 | ◎（埋め込みが意味的に類似性判定） | △（lexical match のみ。Stage 2 でメタデータベースの絞り込み補完あり） |
| キーワードが分かっている前提のクエリ | ○ | ◎（LIKE が直接ヒット） |
| 構築・運用コスト | △ | ◎ |
| 精度の上限 | 高い | 中程度（ただしユースケース次第で十分） |

ドキュメントルックアップ（ユーザが概ね正しいキーワードを把握している前提）であれば、lexical で十分機能する見込み。

---

## 4. 検討論点と決定事項

### 4.1 論点 1: 日本語 LIKE 制限と FTS5 採用判断 ─ 決定済

| 案 | 内容 | Pros | Cons |
|---|---|---|---|
| A | 素の LIKE のまま運用 | 実装が最も単純 | 日本語精度に難（将来拡張時） |
| **B（採用）** | **FTS5 + trigram tokenizer** | **3-gram で部分一致、日本語にも有効、SQLite 標準（拡張機能、追加依存なし）** | **仮想テーブル管理がやや複雑** |
| C | FTS5 + 外部トークナイザ（icu / mecab） | 日本語形態素を正確に扱える | 依存ライブラリ追加、ビルド複雑化 |

**決定理由**: FTS5 は SQLite 公式拡張機能で構築コスト・リスク増加が小さい。trigram tokenizer により本検討範囲（英語の Anthropic docs）+ 将来的な日本語対応の双方をカバーできる。

### 4.2 論点 2: メタデータ Stage の品質依存と DB スキーマ設計 ─ 決定済

**決定**: ソースファイル 3 種（`llms.txt` / `llms-full.txt` / `docs_map`）の構造をそれぞれ独立テーブルにマッピング（§2.3 参照）。個別 `.md` は llms-full.txt に内容が完全包含されるため除外。

**メタデータ Stage の品質**: Anthropic docs に限定する前提のため、llms.txt の 1 行説明 + docs_map の見出し階層を JOIN するだけで十分な情報量を確保できる（§2.3 検索クエリ例参照）。要約抽出等の追加処理は不要。

### 4.3 論点 3: ingestion スクリプト仕様と実装言語 ─ 決定済

| 項目 | 決定内容 |
|---|---|
| 実装言語 | **Python**（ingestion + runtime query 両方） |
| 採用理由 | (1) 標準ライブラリ `sqlite3` で完結、外部依存なし／(2) `settings.local.json` の `Bash(python3 *)` で既に実行許可済み、追加権限設定不要／(3) スクリプト内部のファイル I/O は Python プロセス内で完結し Claude Code の権限プロンプトを発生させない |
| ソースファイル取得方式 | **(a) 事前 DL → ローカル参照**。WebFetch 等での直接参照ではなく、定期 DL されたローカルファイルを ingestion スクリプトが読む。投入データは全量揃った状態で扱う必要があるため |
| 定期 DL 運用 | **スケジューラされたタスクで実行**（具体仕組みは別途検討） |
| DB ファイル配置 | `research-for-local-RAG-for-cc/resources/data/anthropic_docs.sqlite`（gitignore 対象、再生成可能） |
| ソースファイル配置 | `research-for-local-RAG-for-cc/resources/references/`（プロジェクト直下） |
| スクリプト配置 | `research-for-local-RAG-for-cc/scripts/`（プロジェクト直下） |
| MCP Server 化 | 本検討範囲外（Python 単独でスタートし、効果検証後に MCP 化を検討する流れで合意） |

### 4.4 論点 4: 適用ファイル層別の使い分け ─ クローズ

Anthropic docs に限定する方針で確定。`ハマりどころ.md` 等のローカル文書は本検討スコープ外（C01-001 §4 参照）。本論点はクローズ扱い。

---

## 5. 結論

### 5.1 採用設計サマリ

Anthropic 公式 Claude Code ドキュメント（`llms.txt` / `llms-full.txt` / `docs_map`）を入力とする **SQLite + FTS5 trigram + 3 段階ハイブリッド検索** ベースの簡易 RAG を構築する。本格的なベクトル RAG 完成までの「繋ぎ」として、後続フェーズで Claude Code 公式情報に当たる場面の参照効率化を目的とする。

### 5.2 確定事項

| 項目 | 内容 |
|---|---|
| 検索方式 | SQL FTS5 trigram による本文全文検索 → メタデータ JOIN による絞り込み → 該当ページ本文取得（3 段階） |
| DB スキーマ | 3 テーブル構成（`llms_index` / `llms_full` + FTS5 仮想テーブル / `docs_map`）、§2.3 参照 |
| 実装言語 | Python（ingestion + runtime query 両方）、標準ライブラリ `sqlite3` のみ使用 |
| DB ファイル配置 | `research-for-local-RAG-for-cc/resources/data/anthropic_docs.sqlite`（gitignore） |
| スクリプト配置 | `research-for-local-RAG-for-cc/scripts/` |
| ソースファイル取得 | (a) 事前 DL → ローカル参照。定期 DL はスケジューラされたタスクで運用 |
| ソースファイル配置 | `research-for-local-RAG-for-cc/resources/references/`（プロジェクト直下、既存ワークスペース直下のソースファイルもここへ移行） |

### 5.3 想定スクリプト構成

```
research-for-local-RAG-for-cc/scripts/
├── build_db.py            # ingestion: ソース 3 ファイルをパース → SQLite に投入
├── query_db.py            # Stage 1+2: FTS 検索 → メタ一覧返却（CLI: query_db.py "<キーワード>"）
├── fetch_doc.py           # Stage 3: 該当 source_url の本文取得（CLI: fetch_doc.py "<URL>"）
└── schema.sql             # CREATE TABLE 定義（参考用、build_db.py から実行）
```

### 5.4 運用フロー

1. **初回構築**: ソースファイルを DL → `python3 scripts/build_db.py` で DB 構築
2. **更新**: スケジューラされたタスクでソースファイルを定期 DL → `build_db.py` を再実行（差分更新ではなく全量再構築）
3. **検索**: Claude Code セッション内で `python3 scripts/query_db.py "キーワード"` → 候補メタデータを LLM が読んで絞り込み → `python3 scripts/fetch_doc.py "<URL>"` で本文取得

### 5.5 配置場所に関する補足

当初想定では、本簡易 RAG はワークスペース内の共有ナレッジとして workspace 直下（`C:/cc-workspace/research-by-cc/resources/`）に配置する予定だった。しかし以下の整理により、開発期間中はプロジェクト直下に配置する方針とした:

- 現時点でワークスペース内のプロジェクトは本プロジェクト 1 つのみ
- 構築から安定動作・効果実感までは「開発中」ステータスとして扱うのが妥当
- 安定後・他プロジェクトでの利用ニーズ確認後に workspace 直下への昇格を検討する流れが安全

本方針の判断時点（2026-05-10）でワークスペース直下 `resources/references/` に既存配置されていた 3 ソースファイル（`claude-code-llms.txt` / `claude-code-llms-full.txt` / `claude_code_docs_map.md`）も、本判断に従いプロジェクト直下に移行する。

### 5.6 残課題（本検討範囲外、将来検討対象）

- **MCP Server 化**: runtime query を Python CLI ではなく SQLite MCP Server 経由に移行する選択肢。Python 単独運用での効果検証後に判断
- **ローカル文書への適用**: `ハマりどころ.md` 等のローカル文書への llms.txt スタイル適用（C01-001 §4 参照）。事前フォーマッティング作業の必要性から本検討スコープ外
- **個別 `.md` URL パターンを活用したオンデマンド全文補強**（本紙活用方法 13）: llms-full.txt キャッシュの欠落要素（callout / blockquote）をオンデマンド取得で補強する戦略。本検討の RAG 構成と直交するが、組み合わせ可能

---

## 変更履歴

- 2026-05-10: 初版作成（議論進行中）。背景・スコープ・提案アプローチ・ベクトル RAG との比較を整理、検討中論点 4 件をプレースホルダ化（論点 4 はスコープ確定によりクローズ）
- 2026-05-10: 論点 1〜3 の議論結果を反映し決定済に更新。§2.3 スキーマを 3 テーブル構成（`llms_index` / `llms_full` + FTS5 / `docs_map`）に確定。§5 結論セクションを記載（採用設計サマリ・確定事項・想定スクリプト構成・運用フロー・残課題）。ソースファイル配置場所のみ TBD 残
- 2026-05-10: ソースファイル配置場所を `research-for-local-RAG-for-cc/resources/references/`（プロジェクト直下）に確定。§5.5「配置場所に関する補足」を追加（開発期間中はプロジェクト直下、安定後に workspace 直下への昇格検討）。既存ワークスペース直下 3 ソースファイルの移行も併せて方針決定
