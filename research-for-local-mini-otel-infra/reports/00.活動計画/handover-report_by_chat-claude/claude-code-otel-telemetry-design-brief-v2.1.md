# Claude Code トークン/コスト計測基盤 — 設計引き継ぎ資料（v2.1）

- **作成日**: 2026-09-26（v2.1 改訂: 2026-09-27）
- **対象バージョン**: Claude Code v2.1.283（利用者がローカル環境で確認済み）
- **執筆**: v1 は Claude Opus 5 が執筆した。v2 の改訂と反復セルフレビューは Claude Opus 5.5 が行った。どちらも同一セッション・同一コンテキストの中での作業である。v2.1 は、第三者クロスレビュー（論理整合性・実用性、2026-09-27）の確定指摘を Claude Code（Opus）が反映した。レビュー報告書は `../レビュー/` を参照。
- **位置づけ**: 設計と構築を担当する Claude Code セッションへの引き継ぎ資料。論点、観点、リスク、要検討事項、注意事項、留意事項をまとめている。

---

## 0. 凡例と情報源

### 0.1 確度ラベル

- ラベルは文の末尾に付ける。その一文だけに適用される。
- 箇条書きの1項目が複数の文から成る場合、項目の末尾に付けたラベルは、その項目内のラベルのない文すべてに適用される。そのため、確度の異なる文が同じ項目に混ざる場合は、文ごとにラベルを付ける。
- 見出しの直後に【節全体：〜】とある場合は、その節の全文に適用される。
- 複数のラベルに当てはまる場合は、【推測・要検証】のように「・」でつないで併記する。
- 手順や方針を示す文（「〜すること」「〜する」）は事実の主張ではないため、ラベルを付けない。

| ラベル | 意味 |
|---|---|
| （無印） | 公式ドキュメントで記述を確認済み。Claude Code については v2.1.283 時点のドキュメント、OSS については当該プロジェクトのドキュメントで確認している。 |
| 【要検証】 | ドキュメントでは確認できたが、実際に動かして確かめる必要があるもの。理由は、記述が曖昧、バージョンの境界に近い、アルファ段階の機能、実装コードまでは確認していない、などである。 |
| 【要確認】 | 公式ドキュメントで裏付けが取れていないもの。旧版ドキュメントにしか載っていない記述、非公式な情報源、執筆モデルの一般知識に基づく記述がこれに当たる。 |
| 【推測】 | 本セッションのやり取りや調査をもとに、執筆モデルが組み立てた推論。現在の仕様や挙動についての推論である。 |
| 【仮説】 | データや実験で検証すべき命題。分析したときに何が観測されるかの見立てである。 |

**ラベルの対象外**: §1〜§2.3 は利用者が定めた目的と要件なので、確度ラベルは付けない。

**無印の扱い**: 本資料では、ドキュメントの記述がソースコードや実際の挙動と一致するかを網羅的には確認していない。したがって無印の記述にも、厳密には動作確認の余地が残る。【要検証】は、確認すべき具体的な理由がある項目と、設計への影響が特に大きい項目に限って付けた。無印の項目のうち実機で確かめるべきものは、§8.2 の V-11(b) で確認する。対象は §8.5 に列挙する。v2.1 でドキュメントの確認によりラベルを外した項目も本文は無印とし、実際の挙動との一致は同じく V-11(b) で確認する。

### 0.2 情報源

| ID | 情報源 | 状態 |
|---|---|---|
| S1 | Claude Code Monitoring https://code.claude.com/docs/en/monitoring-usage （2026-09-26 取得） | **冒頭から「Tool decision event」節の途中までしか取得できていない。** 取得ツールが長いページを途中で切り詰めるためと考えられる。【推測】 |
| S1' | Claude Code 公式ドキュメント全文 `llms-full.txt` のローカル保存版（2026-09-26 15:00 取得、v2.1.283 相当）。Monitoring 節は L85686〜L87178 | 全文を参照できる。ローカルに保存した版なので、オンライン版とは取得時刻の差がありうる。本資料の「L<番号>」は、このファイルの行番号を指す。v2.1 の改訂で照合に使った。 |
| S2 | 同じページの旧版（約2ヶ月前、本セッション前半で取得） | ほぼ全文を取得した。末尾の「Audit security events」節の最後の表だけが欠けている。v2.1 では S1' と照合した。 |
| S3 | Claude API Extended thinking https://platform.claude.com/docs/en/build-with-claude/extended-thinking | 必要な記述を取得した。2026-09-27 のクロスレビューで再確認した（WebFetch 経由）。 |
| S4 | OTel Collector contrib fileexporter README https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/fileexporter/README.md | 設定オプションの記述を取得した（main ブランチ）。2026-09-27 のクロスレビューで再確認した（論理整合性レビューは WebFetch の要約経由、実用性レビューは原文を取得）。README 自身が、logs と metrics の安定度をアルファとしている。 |
| S5 | DuckDB Loading JSON https://duckdb.org/docs/lts/data/json/loading_json | 必要な記述を取得した。2026-09-27 のクロスレビューで再確認した（WebFetch の要約経由）。`sample_size` の既定値は確認したが、サンプルをファイルのどこから取るかの記述は確認できていない。 |
| S6 | Prometheus Storage https://prometheus.io/docs/prometheus/latest/storage/ 、OpenTelemetry ガイド https://prometheus.io/docs/guides/opentelemetry/ 、Feature flags https://prometheus.io/docs/prometheus/latest/feature_flags/ | Storage は取得した。OTel ガイドは、v2 では検索結果の抜粋でのみ確認した。2026-09-27 のクロスレビューで OTel ガイドと Feature flags を確認した（WebFetch の要約経由）。 |
| S7 | 非公式の技術ブログ（VictoriaMetrics の運用記事など） | 公式情報ではない。 |

**S1 の取得が途中で切れたことの影響と v2.1 での対応**: v2 では、S1 の後半にある次の部分を確認できず、これらに依拠する記述に【要確認】を付けていた。

- Tool decision event より後に定義されているイベント（compaction など）
- 「Interpret metrics and events data」節
- 「Audit security events」節

v2.1 では S1' でこれらを照合し、ドキュメントで確定できた記述のラベルを外した。実際の挙動との一致は V-11(b)（§8.5）で確認する。

---

## 1. 目的とゴール

### 1.1 一次目的
利用するモデルの種類と effort が、実際のトークン消費とコストにどの程度影響するかを定量的に測る。

### 1.2 測定結果で答えたい問い
1. `/compact` と `/clear` をどう使い分けるとコストを抑えられるか（利用者向けのコスト抑制テクニックを開発するため）
2. Skill、workflow、カスタムサブエージェントによるオーケストレーションで、出力品質を保ったままどこまでコストを下げられるか
3. どの作業、どのエージェント、どのツールがコストのボトルネックになっているか

### 1.3 背景
Opus をオーケストレータ、Sonnet をサブエージェントとするマルチエージェント構成を運用している。Sonnet に作業を移すことで Opus への依存をどれだけ減らせたかを、説得力のあるデータで示したい。

---

## 2. 要件

### 2.1 必須要件
| # | 要件 |
|---|---|
| R1 | モデルとバージョンを識別できること |
| R2 | メインセッションとサブエージェントを区別できること（Skill や workflow の中で実行されるサブエージェントも含む） |
| R3 | 送信トークン数と受信トークン数を取得できること。値には**モデルの思考中に発生するトークンも含まれている**こと |
| R4 | 1ヶ月程度の期間の時系列データとして出力できること |
| R5 | 集積した生データを取得できること |

### 2.2 あると望ましいもの
- 実行中のセッション名
- リポジトリ名
- あるトークン消費が「どのセッションで、どの作業のために」発生したかの紐付け

### 2.3 非機能要件
- Claude Code を実行している端末上で起動できる、軽量な OSS 構成であること
- テレメトリ製品そのものに GUI は不要。描画や集計に必要なデータが取れればよい
- 送信先は localhost（127.0.0.1）

**実行環境（v2.1 で追記）**: 引き継ぎ先の環境は Windows 11 ネイティブで、Docker と WSL は使わない。本資料のコマンド例やパス例のうち、この環境でそのまま使えないものには注記を付けた（§5.2、§5.4、§6 R-3、§8.1）。

### 2.4 要件充足の見通し

**R1（モデルとバージョン）**
- 「バージョン」には2つの意味がありうるので、両方に対応する。【推測】
  - **モデルのバージョン**: `model` 属性に入るモデル識別子の文字列（例: `claude-sonnet-5`）で区別できる。
  - **Claude Code のバージョン**: リソース属性 `service.version` で区別できる。すべてのメトリクスとイベントに、設定なしで付く（S1' L87139〜L87142）。
- `service.version` は、Claude Desktop の Code タブから起動したセッションでは Desktop アプリのバージョンになる（S1' L87142）。
  - ターミナルのセッションと区別するには、`service.name`（`claude-code` / `claude-code-desktop`）を併用する（S1' L87141）。
- `app.version`（§4.2）は、バージョンをデータポイントの属性としても持たせたい場合の補助手段とする。
- `service.version` はリソース属性なので、fileexporter の出力では各レコードの属性とは別の場所に入る見込みである（§5.5、§8 V-4）。【推測・要検証】

**R2（メインとサブエージェントの区別）**
- `query_source`、`agent.name`、`skill.name`、`workflow.run_id` で区別できる（§4.2〜§4.4）。
- `skill.name` については、S1 に「Skill ツールや `/` コマンドで設定されるほか、起動されたサブエージェントにも引き継がれる」と記載がある。したがって、Skill の中で起動したサブエージェントのリクエストにも同じ skill 名が付く。
- 実際にどの値が入るかは §8 の V-5、V-7、V-12 で確かめる。【要検証】
- `api_request` イベントには `agent_id` / `parent_agent_id` がない（S1' L86434〜L86451）。これらはスパンの属性である（S1' L85908〜L85909）。
- そのため、同じ型のサブエージェントが並列に動いた場合の個体の区別や入れ子の階層は、イベントだけでは得られない。【推測】
- サブエージェント単位の分析材料と、その注意点は §4.8 にまとめた。

**R3（思考トークンを含む送受信トークン数）**
- S3 によると、API レスポンスの `usage.output_tokens_details.thinking_tokens` は「課金される出力トークンのうち、内部推論に当たるものが何トークンか」を示す。つまり思考トークンは、課金される出力トークンの一部として数えられている。
- Claude Code の `api_request` イベントの `output_tokens`（説明は "Number of output tokens"）は、API の usage の出力トークン数をそのまま反映した値と考えられる。【推測】
  - 根拠: 同じ S1 のスパン属性では `input_tokens` が "from the API usage block" と説明されている。
- 以上から、`output_tokens` には思考トークンが含まれると判断した。【推測・要検証】
  - なお S3 は、`usage.output_tokens` フィールドそのものに思考分が含まれるとまでは明記していない。
  - 確認は2段で行う。V-2a（トランスクリプトとの突き合わせ）で矛盾がないことを確かめ、V-2b（生のレスポンスボディ）で確定させる（§8.2）。
- statusline に思考トークンが表示されないのは表示側の都合であり、テレメトリの値には影響しない。【推測】

**R3 に関連して新たに見つかった論点（思考トークンの内訳）**
- `claude_code.api_request` イベントの属性一覧（S1' L86434〜L86451）には、思考トークンの内訳を示す属性がない。
- そのため、effort を変えたときに思考トークンが単独でどれだけ増減したかは、OTel のイベントやメトリクスからは直接わからない。【推測】
- 内訳を得る経路は2つある。経路 A を主とし、経路 B は補助とする。
- **経路 A（トランスクリプト）**: トランスクリプト（`~/.claude/projects/*/*.jsonl`）の assistant エントリにある `message.usage.output_tokens_details.thinking_tokens` を読み、`api_request` イベントと結合する。
  - 結合キーは `request_id` である。API イベントの `request_id` は、トランスクリプトの assistant エントリに `requestId` として保存される（S1' L86354）。
  - `request_id` は、API が返した場合にだけ付く（S1' L86446）。結合できない行が出ることを前提に集計すること。
  - 引き継ぎ先の Phase 0 の実測（cc 2.1.282、2026-09-25）では、メインセッションの assistant エントリに `thinking_tokens` と `requestId` があった。公式ドキュメントには `thinking_tokens` がトランスクリプトに載るという記述はない。【要確認】
  - サブエージェント、compact、リトライのエントリでも同じく取れるか、また v2.1.283 でも同じ形式かは確認していない（§8 V-2a）。【要確認】
  - この経路は、内容記録のフラグ（§5.2）を必要としない。
  - トランスクリプトの形式は Claude Code の内部仕様であり、バージョンごとに変わりうる（S1' L86351、R-13）。そのため、この経路の用途は思考トークンの内訳の取得に限り、集計の主軸は OTel のデータのままとする。
  - トランスクリプトは既定で30日後に削除される（R-13）。1ヶ月を超えて使う場合は `cleanupPeriodDays` を見直す（§10 手順 6）。
- **経路 B（生のレスポンスボディ）**: `OTEL_LOG_RAW_API_BODIES`（§7.2）で保存したレスポンスボディの `usage.output_tokens_details.thinking_tokens` を読む。【推測】
  - Claude Code が記録するレスポンスボディに、このフィールドが含まれる。【要確認】
  - この経路は、会話履歴の全体を記録するフラグを必要とする（§7.1）。承認が得られた時点で使う。
- Amazon Bedrock 経由の場合に、経路 A・B のどちらでもこのフィールドが得られるかは確認していない（§9.6）。【要確認】
- 参考として、S3 によるとストリーミング時にはこの内訳は最後の `message_delta` イベントにだけ載る。

**R4（時系列）・R5（生データ）**
- R4 は満たせる見通しである（§3）。【推測】
- ただし R4 を満たすには、§6 R-1（Collector を再起動するとデータが消える問題）への対策が済んでいることが前提になる。【推測】
- R5 の「生データ」は2通りに解釈できる。【推測】
  - **解釈 A**: 集計する前のテレメトリのレコード。§3 の fileexporter が出力する JSONL で満たせる。
  - **解釈 B**: Messages API のリクエストとレスポンスの JSON 全体。`OTEL_LOG_RAW_API_BODIES`（§7.2）が必要になり、会話履歴の全体がディスクに残る。
- どちらの解釈かは、作業指示者に確認する事項である。確認できるまでは解釈 A を既定とし、`OTEL_LOG_RAW_API_BODIES` は任意の設定（§5.2）として扱う。
- 思考トークンの内訳は経路 A で取れるので、そのために解釈 B を選ぶ必要はない。【推測】

**2.2 の「セッション名」**
- S1' の標準属性の一覧には、人が付けたセッション名に当たる属性がない。取れるのは `session.id`（UUID）である。
- Claude Code でセッションに名前を付けた場合に、その名前がテレメトリに載るかは確認していない（§8.5）。【要確認】
- 名前が載らない場合は、`session.id` をキーにして、トランスクリプトのファイルパスや `index.jsonl` の `session_id`（§7.2）と後から対応付ける。【推測】

---

## 3. 採用構成

```
Claude Code
  └─ OTLP (http/protobuf) → 127.0.0.1:4318
       └─ otelcol-contrib
            ├─ logs    → file exporter → otel-logs.jsonl     ← 分析の主軸
            └─ metrics → file exporter → otel-metrics.jsonl  ← 産出量の指標
                 └─（指標が確定した後で Prometheus + Grafana を追加）

  └─ トランスクリプト ~/.claude/projects/*/*.jsonl（OTel とは別に Claude Code が保存する）
       └─ 思考トークンの内訳（§2.4 経路 A）

  └─（任意。R5 を解釈 B で読む場合）OTEL_LOG_RAW_API_BODIES=file:<dir>
       （Collector を経由せず、Claude Code が直接ディスクに書き込む）
       └─ 生データ（Messages API のリクエスト/レスポンス JSON 全体）+ index.jsonl
```

### 3.1 この構成にした理由

**DuckDB を分析の主軸にする理由**
- 探索段階では、何を指標として見るべきかがまだ決まっていない。Grafana はダッシュボード定義を試行錯誤するコストが高く、この段階では足かせになる。【推測】
- DuckDB は JSON ファイルを直接読み込んでクエリできる（S5）。
- そのため、`GROUP BY` を書き換えるだけで、分析の切り口をすぐに変えられる。【推測】
- DuckDB にはデータの保持期限という概念がない。そのため、1ヶ月を超えるデータでもそのまま扱える。【要確認】

**JSONL をアーカイブの実体にする理由**
- DuckDB は、グロブパターンやファイルのリストを指定して複数ファイルをまとめて読める（S5）。
- 圧縮形式は既定でファイルの拡張子から自動判別される（例: `.gz` は gzip）。指定できる値は `none` / `gzip` / `zstd` / `auto_detect` である（S5）。
- データの保存とクエリを分離できる。【推測】
- **注意**: Collector の `compression` 設定で圧縮したファイルは行区切りの JSON にならないので、DuckDB では直接読めない（§6 R-3）。【要検証】
  - 圧縮する場合は、外部ツールでファイル全体を gzip または zstd に圧縮する（§6 R-3）。

**Prometheus を後から追加する理由**
- トークンの分析には Prometheus は必要ない（§4.1）。【推測】
- 一方で、産出量（変更行数など）の指標は、ほぼメトリクスとしてしか出力されない（§4.1）。これはコスト対効果を計算するときの分母になる。そのため、見るべき指標が固まった段階で Prometheus を追加する。【推測】

### 3.2 導入の段階
1. **探索期**: otelcol-contrib + file exporter（logs と metrics の両方）+ DuckDB で構成する。保存先は JSONL の1系統だけで済む。メトリクスの temporality は既定の `delta` のままにする。増分がそのまま記録されるので、差分の集計がしやすいためである。【推測】
2. **定常期**: 見るべき指標が確定したら Prometheus + Grafana を追加する。このとき `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` に切り替える（§6 R-5）。

---

## 4. データモデル：どの値がどこにあるか

### 4.1 【最重要】メトリクスとイベントの役割分担

| 取りたいもの | ある場所 | 理由 |
|---|---|---|
| リクエスト単位のトークン内訳 | **イベント** `claude_code.api_request` | メトリクスは時間ごとに集計されたカウンタであり、リクエスト単位には分解できないため【推測】 |
| `prompt.id`（作業単位の紐付け） | **イベントのみ** | メトリクスには意図的に付けられていない。値がプロンプトごとに一意なので、時系列の数が際限なく増えてしまうためである |
| 生のサブエージェント名 | **イベント**の `query_source` | フラグなしでも墨消しされない（§4.4）【要検証】 |
| 産出量（変更行数、PR 数、アクティブ時間） | **メトリクスのみ** | イベントからは復元できない【推測】 |
| 産出量のうち commit 数 | **メトリクス**。`OTEL_LOG_TOOL_DETAILS=1`（§5.2）を設定すれば**イベント**からも数えられる | `git commit` が成功すると、`tool_result` イベントにコミット SHA とブランチが載る（S1' L86417、L86419。v2.1.269 以降）。§6 R-8 も参照 |

**結論**: トークンとコストの分析では、イベントのデータが主になる。Prometheus は、トークンのためではなく、コスト対効果の分母を得るために置く。【推測】

### 4.2 要件と属性の対応（Claude Code のバージョンを除き、`claude_code.api_request` イベントだけで揃う）

| 要件 | 属性 |
|---|---|
| R1 モデル | `model`（モデル識別子。モデルのバージョンもこの値で区別できる） |
| R1 Claude Code のバージョン | `service.version`（リソース属性）。すべてのメトリクスとイベントに既定で付く（S1' L87142）。Code タブのセッションでは Desktop アプリのバージョンになるので、`service.name` で区別する（§2.4） |
| （補助）`app.version` | データポイントの属性。Standard attributes 節は、すべてのメトリクスとイベントがこの属性を共有するとし、制御する変数を `OTEL_METRICS_INCLUDE_VERSION`（既定 false）としている（S1' L86179〜L86184）。一方、同じ変数の別の説明（S1' L77389、L85830）は "in metrics" と対象をメトリクスに限った書き方で、両者の関係を明記した記述はない。イベントに既定で付くのか、メトリクスでだけ変数が必要なのかは V-3 で確かめる。【要検証】 |
| effort | `effort`（`low` / `medium` / `high` / `xhigh` / `max`）。Claude Code が effort を送らないリクエストでは、この属性自体が付かない（例: effort に対応していないモデル）。集計では、値がない行を別のグループとして扱う必要がある。 |
| R2 メイン/サブエージェント | `query_source`、`agent.name`（サブエージェント単位の集計材料は §4.8） |
| R2 Skill / workflow の中の処理 | `skill.name`（起動されたサブエージェントにも引き継がれる）、`workflow.run_id`、`workflow.name` |
| R3 送信 | `input_tokens`、`cache_read_tokens`、`cache_creation_tokens` |
| R3 受信 | `output_tokens`（思考トークンを含むと判断している。§2.4 参照）【推測・要検証】 |
| コスト | `cost_usd`（説明は "Estimated cost in USD"）、`cost_usd_micros`（100万分の1ドル単位の整数） |
| その他 | `duration_ms`、`speed`（`fast` / `normal`）、`request_id`、`client_request_id`（サードパーティのプロバイダ経由では付かない。§9.2） |

### 4.3 紐付けの3つの階層

| 粒度 | キー | ある場所 |
|---|---|---|
| セッション | `session.id` | メトリクスとイベントの両方 |
| 作業（1回のプロンプト） | `prompt.id` | イベントのみ |
| 実行主体 | `query_source` / `skill.name` / `workflow.run_id` | イベントとスパン（スパンでは一部の属性に出力条件がある。§6 R-14）。メトリクスにも `query_source` はあるが、値は `main` / `subagent` / `auxiliary` の3種類に集約される（§4.8） |

- `prompt.id` は UUID v4 で、1回のユーザープロンプトを処理する間に出たすべてのイベントを結び付ける。
- これを使えば「この指示のために合計で何トークン使ったか」を集計できる見込みである。【推測】
- `OTEL_LOG_USER_PROMPTS=1` を併用すると、`claude_code.user_prompt` イベントにプロンプト本文が記録される。
- `prompt.id` で結合すれば、それがどんな作業だったかを人が読める形で復元できる。ボトルネック分析では、これが実質的な主キーになる。【推測】
- `workflow.run_id` でイベントを絞り込むと、その run で発生した API リクエストとツール実行を再構成できる。範囲は、workflow スクリプトが起動したエージェントと、そのエージェントがさらに起動したエージェント（skill の呼び出しを含む）まで、再帰的に含まれるとドキュメントに明記されている。

### 4.4 墨消し（redaction）の規則

`OTEL_LOG_TOOL_DETAILS=1` を設定すると、下の表の属性がすべて元の名前のまま出力される。

| 属性 | 既定（フラグなし） | `OTEL_LOG_TOOL_DETAILS=1` |
|---|---|---|
| `agent.name` | ユーザーが定義したエージェント名は `"custom"` に置き換わる | 元の名前 |
| `skill.name` | `api_request` とトークン・コストのメトリクスでは、サードパーティ製プラグインの skill が `"third-party"` に置き換わる。`skill_activated` イベントでは、ユーザー定義とサードパーティ製プラグインの skill が `"custom_skill"` に置き換わる（S1' L86291、L86707） | 元の名前 |
| `plugin.name` | サードパーティ製プラグインは `"third-party"` に置き換わる | 元の名前 |
| `mcp_server.name` / `mcp_tool.name` | ユーザーが設定したサーバは `"custom"` に置き換わる | 元の名前 |
| `workflow.name` | ユーザーが作成した workflow は `"custom"` に置き換わる | 元の名前 |
| `command_name`（user_prompt イベント） | カスタム・プラグイン・MCP のコマンドは `custom` / `mcp` にまとめられる | 元の名前 |

- 組み込みのエージェント名と、公式マーケットプレイスのプラグイン由来のエージェント名は、フラグがなくても元の名前で出力される（S1' L86290）。
- 組み込み、同梱（bundled）、ユーザー定義、公式マーケットプレイス由来の skill 名は、`api_request` とトークン・コストのメトリクスでは、フラグがなくても元の名前で出力される（S1' L86291）。
- ただし `skill_activated` イベントの `skill.name` は、ユーザー定義の skill も既定で `"custom_skill"` になる（S1' L86707）。
  - skill の利用回数を `skill_activated` で数えると、フラグなしではユーザー定義の skill がすべて1つの値にまとまる。【推測】

**設計上の含意**
- `OTEL_LOG_TOOL_DETAILS=1` を設定すれば、メトリクスだけでもカスタムサブエージェントごとのトークン集計ができる。ただし時系列の数（カーディナリティ）が増える。【推測・要検証】
- イベントの `query_source` については、S1 の説明に出力条件が書かれていない。値は `"repl_main_thread"`、`"compact"`、またはサブエージェント名そのものである。
- したがって、フラグなしでもサブエージェントを識別できると判断した。【推測・要検証】
- ただし、スパン側では、生の `query_source` に出力条件が付いている（§6 R-14）。
- このことから、イベント側でも将来同じような制限が加わる可能性は否定できない。【推測】
- このフラグを有効にすると、ツールの入力内容なども記録される（§7.1）。

### 4.5 `/compact` と `/clear` の分析材料

- `claude_code.compaction` イベントは、v2.1.283 でも次の属性を持つ（S1' L86834〜L86852）。旧版（S2）の属性と同じである。
  - `trigger`（`auto` / `manual`）
  - `pre_tokens`（圧縮前のおおよそのトークン数）
  - `post_tokens`（圧縮後のおおよそのトークン数）
  - `duration_ms`
  - `success`
  - `error`
  - `precompute_reuse`（`manual` のときだけ付く。値は `hit` / `miss_custom_instructions` / `miss_hook` / `miss_not_ready`）
- 圧縮処理そのものの API 呼び出しは、`api_request` イベントに `query_source: "compact"` として記録される（S1 に値の例として `"compact"` が挙がっている）。
  - これを使えば、「圧縮で減ったコンテキストの量」と「圧縮のために払ったトークン代」を突き合わせられる。【推測】
- `/clear` を実行すると、新しい `session.id` が割り当てられる（S1' L86349）。
- したがって、`/clear` の区切りは `session.id` が切り替わった地点としても取得できる。【推測】
  - ただし `session.id` の切り替わりだけでは、プロセスの再起動など別の理由による切り替わりと区別できない。【推測】
- S1' のイベント一覧（L86357〜L86980）には、`/clear` 専用のイベントはない。
- `/clear` と手動の `/compact` を実行した時点は、`user_prompt` イベントの `command_name` で取れる見込みである。【推測】
  - 組み込みのコマンド名（`compact` など）は、フラグがなくてもそのまま出力される（S1' L86372）。
  - `/clear` の実行時に `user_prompt` イベントが出るかは、ドキュメントに明記がない（§8 V-8）。【要確認】
  - 別名（`reset` など）は、入力したとおりの名前で出力される（S1' L86372）。集計するときに正規化すること。
- `user_prompt` イベントが出ない場合の代わりとして、`SessionStart` hook で区切りを記録する方法がある。hook の入力の `source` は、`startup` / `resume` / `clear` / `compact` / `fork` のいずれかの値をとる（S1' L25429）。

**分析のための仮説**

**H-1**: effort が高いセッションほど、`/compact` による input 側の削減効果が大きい。【仮説】
- S3 によると、Claude Opus 4.5 と、バージョン番号が 4.6 以上のモデルは、過去のターンの thinking ブロックをコンテキストに残し、input として課金する。
- S3 は Claude Opus 5.5 と Claude Sonnet 5 を「Claude 4.7 or a later model」の例として挙げている。したがって、この2つは「4.6 以上」に当たる。
- Opus 5 もこれに当たるというのは、番号から執筆モデルが判断したものである。【推測】
- Claude Code が過去のターンの思考を API に送り返していることは、次の記述から読み取れる。【推測】
  - v2.1.282 の changelog に、継続または再開したセッションで以前のメッセージが形を変えて再送され、API が以前の推論を落とすことがあった問題を修正した、とある（S1' L3917）。
  - 記録されるリクエストボディでは、過去のアシスタントのターンに含まれる extended thinking の内容が伏せられる（S1' L86513）。
- もし当たるなら、effort が高い（思考量が多い）セッションほど、後のターンの input トークンが蓄積した思考の分だけ膨らむ。そのため、`/compact` や `/clear` による削減効果も大きく出るはずである。【仮説】
- **測定方法**: H-1 は、次の2つの指標で検証する。比較する effort の水準を固定した対照実験として設計する。
  - トークン: `input_tokens`、`cache_read_tokens`、`cache_creation_tokens` の合計
  - コスト: `cost_usd`
- 2つの指標を分ける理由は次のとおりである。
  - 過去のターンの思考ブロックは、多くの場合キャッシュ読み込み（`cache_read_tokens`）として課金される。そのため、トークン数の削減効果とコストの削減効果は、大きさが異なりうる（R-6）。【推測】
  - adaptive thinking では、effort が低いと、簡単な入力に対して思考そのものを省くことがある（S3）。そのため、「effort が高いほど思考が蓄積する」という関係は単調とは限らない。【推測】
- `compaction` イベントの `pre_tokens` / `post_tokens` はおおよその値である（S1' L86849〜L86850）。効果の測定には、圧縮の前後の `api_request` の input 系トークンを使う。

**H-2**: 同じ作業でも、`/clear` をして必要な文脈だけを渡し直すほうが、`/compact` よりも総トークン数が少なくなる場合がある。ただし、作業品質への影響は作業の種類によって異なる。【仮説】

**H-3**: effort がコストに与える影響は、そのリクエストの `output_tokens` だけでは測りきれない。【仮説】
- H-1 の仕組みがはたらくなら、影響は後のターンの `input_tokens` や `cache_read_tokens` にも及ぶ。【仮説】
- したがって effort の影響は、リクエスト単位ではなく、セッション単位または作業（`prompt.id`）単位の合計で比べる必要がある。【推測】
- 比べるときは、H-1 と同じくトークン数とコストの両方を見る。

### 4.6 ボトルネックの特定に役立つ追加の指標
- `claude_code.tool_result` イベントの `tool_result_size_bytes` と `tool_input_size_bytes`
- `claude_code.tool` スパンの `result_tokens`（ツールの結果のおおよそのトークン数。トレースを有効にする必要がある）

これらを見ると、どのツールの出力がコンテキストを膨らませ、後続のリクエストの `input_tokens` を押し上げているかがわかる。`/compact` が必要かどうかの判断に直結する。【推測】

### 4.7 メトリクスの一覧（8種類）

| メトリクス名 | 説明 | 単位 |
|---|---|---|
| `claude_code.session.count` | 開始されたセッションの数。`start_type` 属性がある（§6 R-9） | none |
| `claude_code.lines_of_code.count` | 変更された行数（`type`: added / removed、`model` 属性あり） | none |
| `claude_code.pull_request.count` | 作成された PR の数 | none |
| `claude_code.commit.count` | 作成された commit の数（`model` 属性はない） | none |
| `claude_code.cost.usage` | コスト | USD |
| `claude_code.token.usage` | トークン数（`type`: input / output / cacheRead / cacheCreation） | tokens |
| `claude_code.code_edit_tool.decision` | 編集系ツールの使用を許可したか拒否したかの回数 | none |
| `claude_code.active_time.total` | アクティブだった時間（`type`: user / cli） | s |

このうち `lines_of_code.count`、`commit.count`、`pull_request.count`、`active_time.total` が、§1.2 の問い2 に答えるときの分母になる。【推測】

- `cost.usage` と `token.usage` には、`model`、`query_source`、`speed`、`effort`、`agent.name`、`skill.name`、`plugin.name`、`marketplace.name`、`mcp_server.name`、`mcp_tool.name` の属性も付く（S1' L86279〜L86309）。
- ただしメトリクスの `query_source` は `main` / `subagent` / `auxiliary` の3種類であり、イベントより粒度が粗い（§4.8）。
- そのため Prometheus を追加する前でも、`model` × `query_source`（3種類）× `effort` の粗い切り口であれば、メトリクスだけで時系列に集計できる。【推測】

### 4.8 サブエージェントの分析材料

サブエージェント単位の分析に使えるシグナルと、その注意点をまとめる。R2 と、§1.2 の問い2・問い3 に関わる。

**`claude_code.subagent_completed` イベント**（S1' L86854〜L86876）
- サブエージェントが完了し、起動元の会話に結果を返した時点で1回出力される。
- 主な属性は `agent_type`、`agent.source`、`is_built_in`、`is_async`、`total_tokens`、`total_tool_uses`、`duration_ms`、`model`、`final_model`、`model_swapped` である。
- `agent_type` は `agent.name` と同じ墨消しの規則に従う（S1' L86290、L86866）。
  - 組み込みと、公式マーケットプレイスのプラグイン由来のエージェントは、元の名前で出力される。
  - その他のエージェント名は既定で `"custom"` になり、`OTEL_LOG_TOOL_DETAILS=1` を設定すると元の名前になる。
- `final_model` と `model_swapped` を使うと、実行の途中でのモデルの切り替え（フォールバックなど）を検知できる（v2.1.212 以降）。
- サブエージェントの型ごとのツール使用数と実行時間は、このイベントから直接集計できる。
- **注意**: `total_tokens` は、そのサブエージェントの最後の API リクエスト1件分のトークン数であり、実行全体の合計ではない（S1' L86870）。
- ドキュメントは、トークンとコストの集計にはこのイベントではなく、トークンとコストのメトリクスを `query_source = "subagent"` で絞り込んで使うよう指示している（S1' L86856）。

**メトリクスとイベントの `query_source` の違い**
- メトリクス（`cost.usage` / `token.usage`）の `query_source` は、`main` / `subagent` / `auxiliary` の3種類のカテゴリである（S1' L86287、L86306）。
- イベント（`api_request`）の `query_source` は生の値で、`"repl_main_thread"`、`"compact"`、またはサブエージェント名が入る（S1' L86449）。
- 両者を同じ値の体系として扱うと、クエリが空振りする。【推測】
- メトリクスの `subagent` には、エージェント型の hook によるリクエストも含まれる。これらのリクエストについては `subagent_completed` イベントは出ない（S1' L86856）。

**イベントだけでは区別できないもの**
- `api_request` イベントには `agent_id` / `parent_agent_id` がない（S1' L86434〜L86451）。これらは `claude_code.llm_request` スパンの属性である（S1' L85908〜L85909）。
- そのため、同じ型のサブエージェントが並列に動いた場合の個体の区別や入れ子の階層は、イベントだけでは得られない。【推測】
- 個体の区別が必要な場合の選択肢は、トレースの `agent_id` と、トランスクリプトのサブエージェントごとのファイルである。【推測】
  - どちらも実機での確認を前提とする（§8 V-5）。

**その他の、v2 で扱っていなかったイベント**
- `claude_code.api_refusal`: API のリクエストが `stop_reason: "refusal"` で返ったときに出力される。拒否は HTTP のエラーではないので、`api_error` イベントは出ない（S1' L86477〜L86499）。
- `claude_code.retention_sweep`: トランスクリプトなどを保持期間に従って削除する処理の記録である（S1' L86896〜L86925）。`period_days` で、実際に適用された保持日数がわかる（R-13）。

---

## 5. 設定

### 5.1 環境変数（基本セット：プロンプト本文や会話内容は記録しない）

以下は bash の書き方である。`~/.claude/settings.json` の `env` ブロックに書けば、シェルの種類に依存しない（§6 R-2）。

```bash
# --- 基本 ---
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf   # Claude Code にはプロトコルの既定値がないので、必ず指定する
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318

# --- あると望ましい項目のため（§2.2）---
export OTEL_METRICS_INCLUDE_REPOSITORY=true     # リポジトリ名: vcs.* 属性（既定は false。v2.1.269 以降）

# --- 任意 ---
export OTEL_METRICS_INCLUDE_VERSION=true        # app.version（既定は false）。R1 は service.version で満たせるので補助（§2.4）
export OTEL_METRICS_INCLUDE_ENTRYPOINT=true     # app.entrypoint（既定は false）

# --- 送信間隔（既定値のままでよいが、値は把握しておく）---
# OTEL_METRIC_EXPORT_INTERVAL=60000   # メトリクスの送信間隔。既定は 60000ms。時系列の粒度はこの値で決まる
# OTEL_LOGS_EXPORT_INTERVAL=5000      # ログの送信間隔。既定は 5000ms
```

- **設定を書く場所**: テレメトリを有効にする変数、送信先を決める変数、内容を記録する変数は、シェル、`~/.claude/settings.json`、または managed settings に書く。リポジトリ内の `.claude/settings.json` に書いても無視される（§6 R-2）。
- **子プロセスへの継承**: Claude Code は、自分が起動する子プロセス（Bash ツール、hooks、MCP サーバ、language server）に `OTEL_*` 環境変数を渡さない。

### 5.2 環境変数（内容記録セット：§7.1 を読み、必要に応じて承認を得てから有効にする）

このセットを有効にすると分析の解像度は上がるが、会話の内容も記録される。

R5 は解釈 A（テレメトリの JSONL）を既定とする（§2.4）。そのため、`OTEL_LOG_RAW_API_BODIES` もこのセットの任意の項目として扱う。次のどちらかに当たる場合に有効にする。

- R5 を解釈 B で読むことを作業指示者に確認できた場合
- 思考トークンの内訳を生のボディで確かめる場合（§8 V-2b）

```bash
# --- 生データ（R5 の解釈 B、V-2b）。会話履歴の全体がディスクに残る ---
export OTEL_LOG_RAW_API_BODIES=file:/path/to/raw-bodies

# --- 分析の解像度を上げる ---
export OTEL_LOG_USER_PROMPTS=1          # プロンプト本文を記録する（§4.3 の作業内容の復元に使う）
export OTEL_LOG_ASSISTANT_RESPONSES=0   # 下の注意を参照。応答本文も残したい場合にだけ 1 にする
export OTEL_LOG_TOOL_DETAILS=1          # 墨消しを解除する（§4.4）。ツールの入力内容なども記録される
```

- **`OTEL_LOG_ASSISTANT_RESPONSES` の注意**: この変数を設定しない場合は、`OTEL_LOG_USER_PROMPTS` の値が代わりに使われる。プロンプトだけを記録して応答本文は伏せておきたい場合は、明示的に `0` を設定する必要がある。
- **承認の要否**: 所属する組織の規程で、これらのフラグを有効にする前に承認が必要かどうかを確認すること。【推測】
- **Windows のパス**: `file:<dir>` にドライブレター付きのパス（例: `C:\...`）をどう書けばよいかは、ドキュメントに記述がない（§8 V-13）。【要確認】

### 5.3 リポジトリ属性（v2.1.269 以降）

`OTEL_METRICS_INCLUDE_REPOSITORY=true` を設定すると、メトリクスとイベントの両方に次の属性が付く。

| 属性 | 値の例 |
|---|---|
| `vcs.repository.url.full` | `https://github.com/example-org/example-repo`（末尾に `.git` は付かない） |
| `vcs.owner.name` | `example-org`（リモートのパスが1段しかない場合は付かない） |
| `vcs.repository.name` | `example-repo` |
| `vcs.provider.name` | `github` / `gitlab` / `bitbucket` / `gitea`（どれにも当たらない場合は付かない） |

- 値は、セッションごとに1回、origin リモートから取り出される。
- 同じリポジトリであれば、HTTPS のリモートと SSH のリモートで同じ値になる。
- 値は小文字に変換される。認証情報、クエリ文字列、フラグメントは値に含まれない。
- これらの属性は、利用者自身が設定したエクスポータにだけ送られる。Anthropic 側のテレメトリでは、`vcs.*` のキーはすべて破棄される。
- 次の場合は属性が付かない。
  - origin リモートがない
  - リモートが URL の形式になっていない
  - 作業ディレクトリを含むリポジトリがホームディレクトリしかない
- `OTEL_RESOURCE_ATTRIBUTES` で `vcs.*` のキーを指定すると、自動で取り出された値より指定した値が優先される。`vcs.repository.url.full` を指定した場合、Claude Code はリモートを読みに行かず、指定されたキーだけを出力する。
- この機能があるので、`OTEL_RESOURCE_ATTRIBUTES` にリポジトリ名を手作業で入れる回避策は不要になった。【推測】

### 5.4 Collector の設定（探索期）

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:4318

exporters:
  file/metrics:
    path: /path/to/otel-metrics.jsonl
    format: json
    rotation:
      max_megabytes: 100
      max_backups: 1000    # 既定値は 100。この数を超えた古いファイルは保持されない
      # max_days は指定しない（既定は無制限）
    # compression は指定しない（§6 R-3）
  file/logs:
    path: /path/to/otel-logs.jsonl
    format: json
    rotation:
      max_megabytes: 100
      max_backups: 1000

service:
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [file/metrics]
    logs:
      receivers: [otlp]
      exporters: [file/logs]
```

根拠（S4）と注意点:

- **`rotation` は必ず設定する（§6 R-1）。**
  - `append` の既定値は `false` で、README には "defines whether append to the file (true) or truncate (false)" と書かれている。
  - つまり、`rotation` も `append` も指定しないと、Collector を起動するたびにファイルが切り詰められることになる。【要検証】
- **`rotation` と `append: true` は併用できない**（README に "currently not supported" とある）。
- **`rotation` を設定した状態で再起動したときの挙動は、README に書かれていない。** 既存のファイルに追記されるのか、新しいファイルが作られるのかがわからない。**Collector を再起動しても既存のデータが消えないことを、導入時に必ず実機で確認すること（§8 V-6）。**【要検証】
  - 代わりの方法として、`rotation` を使わずに `append: true` を設定し、ローテーションは logrotate などの外部ツールで行うやり方もある。【推測】
  - その場合、Collector は開いたファイルハンドルに書き続けるため、logrotate の `copytruncate` 方式が必要になる可能性が高い。ただし `copytruncate` では、コピーしている最中に書き込まれた行が失われる恐れがある。【推測】
  - logrotate は Linux 用のツールであり、WSL を使わない Windows ネイティブ環境では使えない（執筆モデルの一般知識）。【要確認】
  - そのため本活動の環境（Windows 11 ネイティブ）では、`rotation` の設定を主とする。
- **`rotation` を設定すると、`flush_interval` は無視され、書き込みはバッファされなくなる。**
- **metrics と logs は別のファイルに分ける。** スキーマが異なるため、1つのファイルに混ざると DuckDB で扱いにくくなる。【推測】
- **fileexporter の安定度はアルファである**（logs と metrics のどちらも）。
  - そのため、設定オプションはバージョンによって変わる可能性がある。【推測】
  - 導入するバージョンの README で、本節の設定が使えることを確認すること。
- `max_megabytes: 100` と `max_backups: 1000` の組み合わせでは、保存容量の上限はおよそ 100GB になる。1人で1ヶ月使う分には十分だと考えられる。【推測】
- ローテーションで作られるバックアップファイルの名前には、拡張子の直前にタイムスタンプが入る（README の File Rotation 節。例: `data.json` → `data-2022-09-14T05-02-14.173.json`）。【要検証】
  - fileexporter はアルファ段階なので、導入するバージョンで実際の名前を確かめる。§5.5 のグロブ指定がバックアップファイルにも一致するかも、あわせて確認すること（§8 V-6）。
- **パスの書き方（Windows）**: 設定例の `/path/to/...` は Unix 形式の仮置きである。Windows ではドライブレター付きのパスに置き換える。
  - 区切り文字と引用符の扱いは、導入時に確かめる（§8 V-13）。
  - YAML のダブルクォートで囲んだ文字列の中では、バックスラッシュがエスケープ文字として扱われる（YAML の一般知識）。【要確認】

### 5.5 DuckDB で読むときの注意

**出力の形式**
- fileexporter の既定の出力形式は json で、1行に1つの JSON オブジェクトが書かれる（S4）。
- 各行は OTLP の JSON エンコーディングになっており、1回のエクスポート要求の内容がまとめて1行に書かれる。そのため、1行の中に複数のログレコードが入れ子の形で含まれる。【要検証】
  - ログの場合の入れ子の構造: `resourceLogs[] → scopeLogs[] → logRecords[]`
  - 各レコードの属性は、`{key, value: {stringValue | intValue | doubleValue | boolValue}}` という形の配列で表される。【要検証】
- `service.version` などのリソース属性は、各レコードの属性（`logRecords[].attributes`）ではなく、`resourceLogs[].resource.attributes` に入る見込みである（OTel のリソースとレコードの区別に基づく）。【推測・要検証】
  - 実際の位置は V-4 で確かめる。

**数値の扱い**
- OTLP の JSON エンコーディングでは、64ビット整数（`intValue` や、タイムスタンプの `timeUnixNano` など）が文字列として出力されることがある（protobuf の JSON マッピングについての一般知識に基づく）。【要確認】
- そのため、集計の前に数値型へ CAST すること。
- Claude Code が `input_tokens` などを整数型で送っているのか、文字列型で送っているのかは確認していない（§8 V-4）。【要確認】

**スキーマの推定**
- `read_json_auto` は、サンプルとして読んだオブジェクトから列の型を推定する。サンプルの数は `sample_size` で指定し、既定は 20480、`-1` を指定するとファイル全体を走査する（S5）。【要検証】
  - サンプルをファイルの先頭から取るかどうかは、S5 で確認できていない。
- そのため、行によって属性値の型（`stringValue` か `intValue` か）が違うと、推定から漏れた型の値が読めない可能性がある。【推測】
- 対策として、`sample_size=-1` を指定する、`union_by_name=true` を指定する、属性を JSON 型のまま読み込む、といった方法を検討する。【推測】

**1行の大きさの上限**
- DuckDB の JSON 読み込みの `maximum_object_size` の既定値は 16777216 バイト（16MB）である（S5）。
- 1回のエクスポートでまとめて書き出されるレコードが多いと、1行がこの上限を超える可能性がある。その場合は引数で上限を引き上げる。【推測】

**読み込むファイルの指定**
- ローテーションで切り出されたファイルと、それを外部で圧縮したファイル（`.gz` / `.zst`）もまとめて読めるように、グロブは `otel-logs*.jsonl*` のように末尾まで含めて指定する。【推測】
- 圧縮したファイルと圧縮していないファイルを1回の読み込みで混在させられるかは確認していない。【要検証】
- 外部ツールで圧縮するのは、ローテーション済みで書き込みが終わったファイルだけにし、現在書き込み中のファイルには手を付けないこと。【推測】

**クエリのひな形**（構造を示すためのもの）【推測・要検証】

```sql
WITH rl AS (
  SELECT unnest(resourceLogs) AS rl FROM read_json_auto('/path/to/otel-logs*.jsonl*')
), sl AS (
  SELECT rl.resource AS res, unnest(rl.scopeLogs) AS sl FROM rl
), lr AS (
  SELECT res, unnest(sl.logRecords) AS r FROM sl
)
SELECT
  list_filter(res.attributes, a -> a.key = 'service.version')[1].value.stringValue AS service_version,
  list_filter(r.attributes, a -> a.key = 'event.name')[1].value.stringValue        AS event_name,
  list_filter(r.attributes, a -> a.key = 'model')[1].value.stringValue             AS model,
  list_filter(r.attributes, a -> a.key = 'query_source')[1].value.stringValue      AS query_source,
  r.attributes AS attrs
FROM lr;
```

### 5.6 動作確認
- **メトリクスが届いているか**: `claude_code.session.count` を確認する。このメトリクスはセッション開始時に出力される。
- **ログだけを送る構成の場合**: プロンプトを1回送り、`claude_code.user_prompt` を確認する。
- **何も届かない場合**: `claude --debug-file <path>` で起動し、指定したパスに書き出されたログを確認する。
  - 自分の設定が原因のエラーには、`[3P telemetry]` という接頭辞が付く。
  - `[Anthropic telemetry]` の行は Anthropic 側の別系統の運用テレメトリに関するもので、自分の設定に問題があることを意味しない。

---

## 6. リスク・落とし穴（実装の前に必ず読むこと）

### R-1 【重大】Collector を再起動するとデータが消えるおそれがある
- fileexporter の `append` の既定値は `false` で、この場合ファイルは切り詰められる（S4）。
- したがって、`rotation` も `append` も指定しない設定では、再起動のたびにそれまでのデータが失われる。【要検証】
- PC の再起動や Collector の更新でも、同じことが起きる。【推測】
- **対策**: §5.4 のとおり `rotation` を設定し、再起動しても既存のデータが残ることを実機で確認する（§8 V-6）。【要検証】

### R-2 【重大】プロジェクト設定では OTel を有効にできない
- リポジトリの `.claude/settings.json` と `.claude/settings.local.json` では、次の変数が無視される（S1' L94789〜L94807）。
  - テレメトリを有効にする変数（`CLAUDE_CODE_ENABLE_TELEMETRY` など）
  - 送信先を決める変数（エクスポータの選択と、`OTEL_EXPORTER_OTLP_*` のうち名前が `_ENDPOINT`・`_HEADERS`・`_PROTOCOL` などで終わるもの）
  - 内容を記録する変数（`OTEL_LOG_USER_PROMPTS`、`OTEL_LOG_ASSISTANT_RESPONSES`、`OTEL_LOG_TOOL_CONTENT`、`OTEL_LOG_TOOL_DETAILS`、`OTEL_LOG_RAW_API_BODIES`）
- これらはシェル、`~/.claude/settings.json`、または managed settings に書くこと。
- この無視の挙動は v2.1.282 以降のものである（S1' L94807）。
- 例外として、リポジトリ側からシグナルを**無効にすることだけ**はできる。使えるのは、3つのエクスポータ選択の変数の `none` と、`OTEL_LOG_USER_PROMPTS`・`OTEL_LOG_TOOL_CONTENT`・`OTEL_LOG_TOOL_DETAILS` の `0` などのオフの値である（S1' L94803）。
  - ただし、起動時の環境、`--settings`、managed settings で同じ変数を設定している場合は、この例外の値は効かない（S1' L94803）。
- `OTEL_RESOURCE_ATTRIBUTES` と、送信間隔・タイムアウト・圧縮の変数は、プロジェクト設定でも有効である（S1' L77414）。リポジトリ単位のラベル付けに使える（R-11）。
- `OTEL_METRICS_INCLUDE_*` は、無視される変数の一覧（S1' L94789〜L94807）に含まれていない。そのため、プロジェクト設定でも有効と考えられる。【推測】

### R-3 【重大】Collector 側で圧縮すると、DuckDB で直接読めない
- S4 には、`format` が json で `compression` が none の場合は、各行が1つの JSON オブジェクトになると書かれている。
- 一方で、それ以外の場合は、エンコードされた各オブジェクトの前にその長さを表す4バイトが付くとされている。
- Collector で `compression: zstd` を設定したファイルは「それ以外」に当たるので、行区切りの JSON にならず、DuckDB の `read_json` では読めない。【要検証】
- **対策**: Collector 側では圧縮しない。ローテーション済みのファイルを、外部ツールでファイル全体ごと gzip または zstd に圧縮する（拡張子は `.gz` / `.zst`）。DuckDB は拡張子から圧縮形式を自動で判別して読める（S5）。
- **Windows での注意**: Windows 11 には、単体の gzip や zstd のコマンドが標準では入っていない（執筆モデルの一般知識）。【要確認】
  - 標準で入っている `tar.exe` で作る `.tar.gz` は、tar 形式のアーカイブ全体を圧縮したものである。DuckDB がそのまま読める単体の `.gz` にはならない可能性が高い。【推測】
  - 圧縮の手段（zstd for Windows や 7-Zip などを追加で導入するか、Node.js などで `.gz` を書き出すか）は、実装方式を決める設計フェーズで選ぶ。

### R-4 【重大】`event.sequence` は並べ替えのキーに使えない
- `event.sequence` は0から始まり、**Claude Code のプロセスごとに**数えられる。セッションごとではない。
- `/clear` で `session.id` が変わっても、番号はリセットされずに続く。
- fork せずにセッションを再開すると、同じセッションの中で、後のイベントのほうが小さい番号になったり、番号が重複したりすることがある。
- **対策**: イベントは `event.timestamp` で並べ替える。`event.sequence` は、タイムスタンプが同じイベント同士の順番を決めるときにだけ使う。
- interaction スパンの `interaction.sequence` も同じく、プロセスごとに数えられる。

### R-5 delta temporality と時系列データベースの相性
- Claude Code のメトリクスの temporality は、既定で `delta` である。

**Prometheus の場合**
- OTLP で直接受け付けるには、`--web.enable-otlp-receiver` を付けて起動する。受信するパスは `/api/v1/otlp/v1/metrics` である（S6）。
- delta 形式のまま受け付けるには、実験的な機能 `--enable-feature=otlp-deltatocumulative` を有効にする（S6 の Feature flags）。【要検証】
  - 同じ目的の別の機能として、`--enable-feature=otlp-native-delta-ingestion`（cumulative に変換せず delta のまま保存する）がある。この2つは同時には有効にできない（S6）。【要検証】
  - `otlp-deltatocumulative` の説明によると、どちらも有効にしない場合、delta のメトリクスは破棄される（S6）。【要検証】
- もう1つの方法として、Claude Code 側で `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` を設定し、cumulative 形式で送ってもよい。
- データの保持期間は、既定で `15d` である（S6）。1ヶ月分を残すには `--storage.tsdb.retention.time=31d` 以上を指定する。

**VictoriaMetrics の場合**
- delta temporality のデータは、エラーも警告も出ないまま破棄される（S7 に基づく）。【要確認】
- PromQL のダッシュボードを使うには、`opentelemetry.usePrometheusNaming` フラグが必要になる。例えば `claude_code.token.usage` は `claude_code_token_usage_tokens_total` という名前に変わる（S7 に基づく）。【要確認】

### R-6 4種類のトークン数を単純に合計しない
- `type` の4つの値（`input` / `output` / `cacheRead` / `cacheCreation`）は、それぞれ単価が異なる（料金ページは本セッションでは確認していない）。【要確認】
- 4種類を1つの「送信トークン」として合計し、同じ単価を掛けると、コストの見積もりを誤る。4種類はそれぞれ別に集計すること。【推測】

### R-7 コストの値は推定値である
- `api_request` イベントの `cost_usd` は、説明に "Estimated cost in USD" とある推定値である。
- 正式な請求額は、利用しているプロバイダ（Claude Console、Amazon Bedrock、Google Cloud's Agent Platform）で確認すること（S1' L87003〜L87005）。
- トークン数そのものは API の usage に基づく値なので、コストの推定値よりも信頼できる。【推測】

### R-8 モデル別の commit 数は直接は取れない
- `commit.count` には `model` 属性がない（S1 の Commit counter の説明には、標準属性しか挙がっていない）。
- ドキュメントによると、近似的に求めるには、`session.id` をキーにして、トークンまたはコストのメトリクスと結合する（S1' L87019）。
- その際、トークン側を `query_source = "main"` に絞り込む。絞り込まないと、サブエージェントや補助的なリクエストで使われたモデルに、そのセッションの commit が割り当てられてしまう（S1' L87019）。
- **イベント側の代わりの経路**: `OTEL_LOG_TOOL_DETAILS=1`（§5.2）を設定すると、`git commit` が成功したときの `tool_result` イベントに、コミット SHA とブランチが載る（S1' L86417、L86419）。
  - このイベントの `prompt.id` を介せば、commit を、同じ作業の `api_request` のモデルに割り当てられる。【推測】

### R-9 セッション数を分母にするときは、`start_type` で一部を除外する
- `claude_code.session.count` には `start_type` 属性があり、値は `fresh` / `resume` / `continue` / `agents_view` のいずれかである。
- `agents_view` は `claude agents` ダッシュボード（利用者が起動するローカルの UI）を起動したことを表し、会話のセッションではない。
- セッション数を分母にする集計では `agents_view` を除外すること。`resume` と `continue` を数えるかどうかは、分析の目的に応じて決める。【推測】

### R-10 `mcp_server.name` の意味が v2.1.222 で変わった
- 以前は、MCP ツールを呼んだ後のすべてのリクエストにこの属性が付いていた。
- 現在は、MCP ツールの結果を受け取ったリクエストにだけ付く。
- そのため、古いバージョンのデータとつなげて集計すると、値に段差が出る（ドキュメントにも明記されている）。

### R-11 リソース属性では、セッションの途中で作業ラベルを変えられない
- `OTEL_RESOURCE_ATTRIBUTES` は、プロセスの起動時に読み込まれる環境変数である（OTel の一般的な仕組みに基づく。S1' にも明示の記述はない）。【要確認】
- そのため、リソース属性を使って、セッションの途中で「ここから作業X」というラベルに切り替えることはできない。【要確認】
- ただし、リソース属性以外にも作業ラベルとして使える手段がある。回避策の候補は次の5つである。
  1. 作業ごとにセッションを分け、起動時に `OTEL_RESOURCE_ATTRIBUTES` でラベルを渡す
  2. `prompt.id` とプロンプト本文をもとに、後から分類する（`OTEL_LOG_USER_PROMPTS=1` が必要。§5.2）
  3. `skill.name` / `command_name` / `workflow.name` を作業ラベルとして使う
  4. プロジェクト設定の `OTEL_RESOURCE_ATTRIBUTES` で、リポジトリ単位の固定ラベルを付ける（R-2）
  5. hook（`UserPromptSubmit` など）でラベルを別のファイルに記録し、hook の入力の `prompt_id` で突き合わせる
- 候補3の根拠: ユーザー定義の skill 名は、フラグなしでも `api_request` とトークン・コストのメトリクスに元の名前で付く（S1' L86291）。組み込みのコマンド名は、`user_prompt` の `command_name` にそのまま出力される（S1' L86372）。
  - 作業の種類ごとに skill を用意すれば、内容を記録しなくても、セッションの途中で変わる作業ラベルとして使える。【推測】
  - skill の終了後も `skill.name` が付き続けるか（skill の有効範囲）は、ドキュメントに記述がない（§8 V-12）。【要確認】
- 候補5の根拠: hook の入力の `prompt_id` は、OTel イベントの `prompt.id` と一致する（S1' L79108）。
  - `prompt_id` は、最初のユーザー入力より前には付かず、v2.1.196 以降が必要である（S1' L79108）。そのため、`SessionStart` など最初のプロンプトの前に発火する hook では使えない。
- どの候補を採るかは、精度、手間、プライバシーへの影響を比べて、後続のフェーズで決める。

### R-12 `OTEL_RESOURCE_ATTRIBUTES` の書式の制約
- **値に空白を含めることはできない**（例: `org.name=My Company` は無効）。
- 値を引用符で囲んでもエスケープにはならず、引用符も値の一部として扱われる。
- 使える文字は、US-ASCII から制御文字、空白、二重引用符、カンマ、セミコロン、バックスラッシュを除いたものである。
- 使えない文字は、パーセントエンコードで表す（例: `John%27s%20Organization`）。
- 指定したキーは、すべてのメトリクス系列のラベルになる。値の種類が多いと、保存コストが増える。リソースブロックにだけ載せて系列のラベルにはしたくない場合は、`OTEL_METRICS_INCLUDE_RESOURCE_ATTRIBUTES=false` を設定する。

### R-13 トランスクリプト（JSONL）との結合はバージョンに依存する
- `~/.claude/projects/*/*.jsonl` のエントリの形式は Claude Code の内部仕様であり、リリースごとに変わる可能性がある。
- `message.uuid`、`request_id`、`tool_use_id` での結合は、そのバージョンでだけ有効な実装として扱うこと。安定した仕様とはみなさない。
- 長期的な集計の主軸にはせず、OTel のデータを補う用途にとどめる。
  - 本資料で想定する用途は、思考トークンの内訳の取得（§2.4 経路 A）である。
- Claude Code には、トランスクリプトを一定期間後に削除する設定（`cleanupPeriodDays`、既定は30日）がある（S1' L12616、L86913）。1ヶ月を超えてトランスクリプトと結合する予定があるなら、この値を見直すこと。
- 実際に適用された保持日数は、`retention_sweep` イベントの `period_days` と `used_default` で確かめられる（S1' L86913〜L86914）。

### R-14 トレースを使う場合の追加の注意
- `claude_code.llm_request` スパンの `query_source` は、`ENABLE_BETA_TRACING_DETAILED` を有効にしないと出力されない。
- 常に出力される `query_source_safe` もあるが、ユーザーが定義したエージェントは `agent.custom` にまとめられてしまう（v2.1.268 以降）。
- スパンで元のエージェント名が必要な場合は、詳細なベータトレース（`ENABLE_BETA_TRACING_DETAILED=1` と `BETA_TRACING_ENDPOINT` の設定）が必要になる。対話型の CLI では、さらに組織が許可リストに登録されている必要がある。
- 詳細なベータトレースを有効にすると、logs と traces の送信先が、通常のエクスポータではなく `BETA_TRACING_ENDPOINT` に切り替わる。
  - **影響**: `BETA_TRACING_ENDPOINT` をローカルの Collector に向けないと、分析の主データである `api_request` などのイベントが、本構成の file exporter に届かなくなる。詳細なベータトレースを試す場合は、主データの収集を止めてしまわないよう注意すること。【推測】
- イベント側の `query_source` には、このような出力条件は書かれていない（§4.4）。
- そのため、イベントを主軸にするほうが安全である。【推測】

### R-15 `otelHeadersHelper` が失敗すると、その間はテレメトリが送られない
- ヘッダを生成するスクリプトが失敗すると、エクスポートが失敗し、**スクリプトが再び成功するまで**、そのセッションのテレメトリはバックエンドに届かない。
- 失敗したことは、対話セッションでは警告として通知される（1セッションにつき1回）。`/status` の出力とデバッグログにも記録される。
- ローカルの構成で認証が不要なら、この設定はそもそも使わないほうが安全である。【推測】

---

## 7. プライバシーと運用の留意事項

### 7.1 内容を記録するフラグとその影響範囲

| フラグ | 記録されるもの |
|---|---|
| `OTEL_LOG_USER_PROMPTS=1` | ユーザーのプロンプト本文 |
| `OTEL_LOG_ASSISTANT_RESPONSES=1` | アシスタントの応答テキスト（thinking ブロックと tool_use ブロックは含まない） |
| `OTEL_LOG_TOOL_DETAILS=1` | Bash のコマンド、MCP のサーバ名とツール名、skill 名、workflow 名、ツールへの入力 |
| `OTEL_LOG_TOOL_CONTENT=1` | ツールの入出力の内容（トレースを有効にする必要がある） |
| `OTEL_LOG_RAW_API_BODIES` | **会話履歴の全体**を含む、Messages API のリクエストとレスポンスの JSON |

- `OTEL_LOG_RAW_API_BODIES` を有効にすると、`OTEL_LOG_USER_PROMPTS`、`OTEL_LOG_TOOL_DETAILS`、`OTEL_LOG_TOOL_CONTENT` で記録される内容すべてに同意したものとみなされる（S1' L85805）。
  - ただし Security and privacy 節（S1' L87168）は、「ほかの `OTEL_LOG_*` の内容記録フラグで明らかになる内容すべて」と、より広く書いている。こちらに従えば、`OTEL_LOG_ASSISTANT_RESPONSES` の内容も含まれうる。
- ローカルで完結する構成でも、ファイルのアクセス権限と、バックアップの対象から外すかどうかは、設計の段階で決めておくこと。【推測】
- ツールの利用方針を管理する部門が組織にある場合は、これらのフラグを有効にする前に承認が必要かどうかを確認すること。【推測】

### 7.2 生の API ボディ（R5 を解釈 B で読む場合の手段）

`OTEL_LOG_RAW_API_BODIES=file:<dir>` を設定すると、Claude Code は Collector を経由せず、直接ディスクに書き込む。

- `<dir>/<uuid>.request.json` — 切り詰められていないリクエストボディ
- `<dir>/<request_id>.response.json` — 切り詰められていないレスポンスボディ
- `<dir>/index.jsonl` — 成功したレスポンス1件につき1行（v2.1.274 以降）

**`index.jsonl` の各行に含まれるフィールド**: `timestamp`, `session_id`, `query_source`, `model`, `request_id`, `message_id`, `message_uuid`, `request_file`, `response_file`

- テレメトリのバックエンドに問い合わせなくても、トランスクリプトのメッセージから、対応する生のリクエストとレスポンスをたどれる。
- R5 を解釈 B で読む場合、`index.jsonl` は DuckDB で直接読めるので、生データへの入口として最も手軽である。【推測】
- ドキュメントは、このディレクトリをテレメトリのストリームではなく、ログ収集ツールやサイドカーで運ぶよう推奨している（S1' L87170）。R5 の主な手段にする場合は、その運び方も設計に含めること。
- ファイルへの書き出しが、logs エクスポータの設定（`OTEL_LOGS_EXPORTER`）に依存するかどうかは確認していない（§8.5）。【要確認】
- 本構成では logs エクスポータを有効にしているので、実際には問題にならない見込みである。【推測】
- `api_request_body` イベントと `api_response_body` イベントには `request_body_id` がある。これを使うと、リトライを含めて、どの試行のリクエストがどのレスポンスを生んだのかを対応付けられる（v2.1.274 以降）。

**thinking の内容の扱い**
- リクエストボディでは、過去のアシスタントのターンに含まれる extended thinking の内容が伏せられる。レスポンスボディでも、extended thinking の内容は伏せられる。
- これは思考の**内容**についての扱いであり、トークンの**数**（usage）とは別の問題である。思考トークンの数がボディに残るかどうかは、§8 の V-2b で確認する。【推測】
- 思考トークンの数は、トランスクリプトからも取れる見込みである（§2.4 経路 A、§8 V-2a）。【要確認】

### 7.3 内容の切り詰め
- `CLAUDE_CODE_OTEL_CONTENT_MAX_LENGTH` の既定値は 61440（60KB。UTF-16 のコードユニットで数える）である。これは、属性値の上限を 64KB としているバックエンドに合わせた値である。
- ローカルのファイルに出力するだけなら、値を引き上げてもよい。ただし、SDK 側の上限（`OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` など）のほうが小さい場合は、そちらの値で切り詰められる。
- 値を引き上げる場合は、DuckDB 側の `maximum_object_size`（§5.5）との兼ね合いにも注意すること。【推測】

---

## 8. 未検証の事項と検証計画

### 8.1 進め方

v2.1.283 は手元にある。そのため、Collector を立てる前に、console エクスポータで実際の出力を確認するのが最も確実で速い。【推測】

**console の出力の記録方法**
- console エクスポータの出力先と、対話型の画面との関係は、ドキュメントに記述がない。【要確認】
- 対話型の画面と混ざるのを避けるため、次のどちらかで記録する。どちらも実機での確認を前提とする。
  1. `claude -p` で非対話実行し、出力をファイルにリダイレクトする。`/compact` などのスラッシュコマンドも、`-p --resume` で実行できる見込みである（S1' L4988 の changelog）。【推測】
  2. 対話型のセッションで確かめる項目は、Collector などの受信側を先に立てて受ける。
- 出力が標準出力と標準エラー出力のどちらに出るかは確認していないので、下の例では両方をファイルに送っている。【推測】

Git Bash の場合:

```bash
CLAUDE_CODE_ENABLE_TELEMETRY=1 OTEL_LOGS_EXPORTER=console OTEL_METRICS_EXPORTER=console claude -p "<プロンプト>" > console-out.txt 2>&1
```

PowerShell の場合（設定した環境変数は、そのシェルを閉じるまで残る）:

```powershell
$env:CLAUDE_CODE_ENABLE_TELEMETRY = "1"; $env:OTEL_LOGS_EXPORTER = "console"; $env:OTEL_METRICS_EXPORTER = "console"
claude -p "<プロンプト>" > console-out.txt 2>&1
```

項目によっては、§5.2 のフラグや Collector も必要になる。何が必要かは、次の表の「必要なもの」列を参照すること。

**スキーマとクエリは、以下の検証が済んでから設計すること。** 構成を固めた後で属性名の違いに気づくと、大きな手戻りになる。

### 8.2 検証項目

| ID | 確認すること | 方法 | 必要なもの | 影響する箇所 |
|---|---|---|---|---|
| V-1 | `claude_code.compaction` の属性に実際に入る値（属性の定義は S1' で確認済み） | `/compact` を実行し、出力を記録する | console | §4.5、問い1 |
| V-2a | **R3**: トランスクリプトの `thinking_tokens` を `api_request` と突き合わせられるか。`output_tokens` に思考トークンが含まれることと矛盾しないか | `requestId` と `request_id` の突合率を、メイン／サブエージェント／compact／リトライの別に測る。同じエントリで `thinking_tokens ≤ output_tokens` が成り立つかを確かめる。トランスクリプトと `api_request` の `output_tokens` が一致するかも比べる。判定は「含まれることと矛盾しない」までとし、確定は V-2b で行う | console（または Collector）、トランスクリプト。内容記録のフラグは不要 | §2.4、R3 |
| V-2b | **R3**: `output_tokens` に思考トークンが含まれることの確定 | effort を高くしてリクエストを送り、生のレスポンスの `usage.output_tokens` と `usage.output_tokens_details.thinking_tokens` を比べる。後者が存在するかどうかも確認する。承認が得られた時点で実施する | `OTEL_LOG_RAW_API_BODIES`（§5.2） | §2.4、R3 |
| V-3 | `app.version` の付き方と、`service.version` との一致（R1 は `service.version` で満たせるので、優先度は低い） | (1) `OTEL_METRICS_INCLUDE_VERSION` を設定した場合としない場合で、`api_request` とメトリクスの出力を比べ、イベントには既定で付くのか、メトリクスでは変数が必要なのかを確かめる。(2) `app.version` と `service.version` を `service.name` 別に比べる。`claude-code` では一致し、`claude-code-desktop` では一致しないのが、ドキュメントどおりの結果である（S1' L86184、L87141〜L87142） | console | §4.2、R1 |
| V-4 | トークン数などの属性の型（整数か文字列か）。`service.version` などのリソース属性が出力のどこに入るか | JSON ファイルの `intValue` / `stringValue` と、`resource.attributes` の位置を確認し、§5.5 のひな形を直す | Collector | §5.5、R1 |
| V-5 | カスタムサブエージェントのときに `query_source` に入る値。フラグありのときに `agent.name` が元の名前で出るか。同じ型のサブエージェントを並列に動かしたとき、イベントで個体を区別できるか | 実際に起動して出力を確認する | console、`OTEL_LOG_TOOL_DETAILS`（§5.2） | §4.4、§4.8、R2 |
| V-6 | **Collector を再起動しても既存のデータが消えないか**（`rotation` を設定した状態で）。ローテーションで作られるファイルの名前 | 停止と起動を行い、前後でファイルの内容とサイズを比べる。ローテーション後のファイル名が §5.5 のグロブに一致するかも確かめる | Collector | §5.4、R-1 |
| V-7 | Skill や workflow の実行時の `skill.name`、`workflow.run_id`、`workflow.name` の実際の値 | 実際に実行して出力を確認する | console | R2 |
| V-8 | `/clear` の実行時に `user_prompt` イベント（`command_name`）が出るか | `/clear` を実行する。出ない場合は、`SessionStart` hook の `source`（§4.5）で代わりに記録できるかを確かめる | console | §4.5 |
| V-9 | 自環境で実際に出力されるイベントと、S1' のイベント一覧（§8.3）との差分 | ひととおりの操作をして出力を集め、S1' の一覧と照合する。意図して発火させにくいイベント（`feedback_survey`、`hook_plugin_metrics` など）は対象外とする | console | §8.3 |
| V-10 | Bedrock 経由の場合（該当する場合のみ）: 標準属性の埋まり方、`client_request_id` が付かないこと、usage のフィールド構成、`x-amzn-requestid` が `request_id` に使われるか、トランスクリプトに `thinking_tokens` があるか | Bedrock 経由で実行する | console、トランスクリプト、`OTEL_LOG_RAW_API_BODIES` | §9 |
| V-11(a) | 本資料の記述と、完全版ドキュメント（S1'）や OSS・API のドキュメントとの照合 | 2026-09-27 のクロスレビューで実施済み。結果は v2.1 の本文に反映した | S1'、S3〜S6 | 本資料全体 |
| V-11(b) | 無印の項目と、ラベルが付いた項目の実機での確認（Phase 1 以降） | §8.5 の一覧に従い、関連する検証や手順と合わせて確認する | 項目ごとに異なる（§8.5） | 本資料全体 |
| V-12 | `skill.name` の有効範囲（skill の終了後も付き続けるか） | skill を実行し、その前後と、skill が起動したサブエージェントのリクエストで `skill.name` を確認する | console | R-11、R2 |
| V-13 | Windows でのパスの書き方 | `OTEL_LOG_RAW_API_BODIES=file:<dir>` にドライブレター付きのパスを指定して書き出されるか、fileexporter の `path` に Windows のパスを書けるか（区切り文字、YAML の引用符）を確かめる | Collector。`file:<dir>` の確認には §5.2 のフラグ | §5.2、§5.4 |

### 8.3 旧版から引き継いだイベントの確認状況

旧版（S2）に掲載されていた次の15イベントは、すべて S1' にも定義がある（S1' L86579〜L86894）。

`permission_mode_changed` / `auth` / `mcp_server_connection` / `internal_error` / `plugin_installed` / `plugin_loaded` / `skill_activated` / `at_mention` / `api_retries_exhausted` / `hook_registered` / `hook_execution_start` / `hook_execution_complete` / `hook_plugin_metrics` / `compaction` / `feedback_survey`

- 各イベントの属性も S1' で確認できる。
- 自環境で実際に発火するかは V-9 で確認する。
- S1' には、v2 で扱っていなかった次のイベントもある。`subagent_completed`、`api_refusal`、`retention_sweep`（§4.8）、`managed_settings_resolved`（§8.4）。

### 8.4 `managed_settings_resolved` イベント
- `managed_settings_resolved` イベントは、セッションが解決した managed settings を記録する（S1' L86927〜L86980）。v2.1.274 以降で出力される。
- `OTEL_LOG_MANAGED_SETTINGS=1` を設定すると、伏せ字処理を施した managed settings と、伏せ字処理の前の設定の SHA-256 ダイジェストが付加される（v2.1.274 以降）。
- この変数は、プロジェクト設定やローカル設定に書いても有効にならない。
- イベントの属性（`managed_settings.trigger`、`managed_settings.sources`、`managed_settings.helper.state` など）は、S1' に定義がある。
- managed settings を使わない個人の環境では、分析にはほぼ関係しない。【推測】

### 8.5 実機で確認する項目の一覧（V-11(b)）

V-11(b) の対象を、次の3つの区分で挙げる。「時期・方法」列に、合わせて行う検証や手順を示す。

**区分1: v2.1 でドキュメントの確認によりラベルを外した項目**（本文は無印のまま、実際の挙動との一致だけを確かめる）

| # | 確認すること | 箇所 | 時期・方法 |
|---|---|---|---|
| 1 | `compaction` イベントの属性 | §4.5 | V-1 で兼ねる |
| 2 | 旧版から引き継いだ15イベントの存在 | §8.3 | V-9 で兼ねる |
| 3 | `/clear` 専用のイベントがないこと | §4.5 | V-8 で兼ねる |
| 4 | `managed_settings_resolved` イベントの属性 | §8.4 | managed settings を使う場合のみ |
| 5 | Claude アカウントがない認証で、利用者を識別する属性が埋まらないこと | §9.1 | 該当する形態の場合のみ |
| 6 | `internal_error` イベントが送出されない条件 | §9.4 | 該当する形態の場合のみ |
| 7 | コストの推定値と、プロバイダの請求額の差 | R-7 | データを1ヶ月貯めた後（§10 手順 6 以降） |
| 8 | commit のモデル別の近似（`session.id` での結合と `query_source = "main"` での絞り込み） | R-8 | §10 手順 4 のクエリ作成時 |
| 9 | `cleanupPeriodDays` の既定値（30日） | R-13 | `retention_sweep` イベントの `period_days` と `used_default` で確かめる（§10 手順 6 の前） |
| 10 | Claude Code のバージョンが `service.version` として付くこと | §2.4、§4.2 | V-3・V-4 で兼ねる |

**区分2: ラベルが残る項目のうち、ほかの V-ID で扱わないもの**

| # | 確認すること | 箇所 | 時期・方法 |
|---|---|---|---|
| 11 | セッション名がテレメトリに載るか | §2.2 | セッションに名前を付けて出力を確認する（§10 手順 1） |
| 12 | DuckDB に保持期限の概念がないこと | §3.1 | §10 手順 4 |
| 13 | `OTEL_LOG_TOOL_DETAILS=1` のとき、メトリクスだけでカスタムサブエージェントごとに集計できるか | §4.4 | §10 手順 2 |
| 14 | `read_json_auto` のサンプリングの挙動と `sample_size=-1` の効果 | §5.5 | V-4 と合わせて確認する（§10 手順 3〜4） |
| 15 | 圧縮したファイルと圧縮していないファイルを混在させて読めるか | §5.5 | §10 手順 5 |
| 16 | クエリのひな形が実際の出力で動くか | §5.5 | §10 手順 4 |
| 17 | Collector 側で圧縮したファイルを DuckDB で読めないこと（任意） | R-3 | §10 手順 5 |
| 18 | Windows で gzip / zstd を使うための追加の導入と、`tar.exe` の出力を DuckDB で読めるか | R-3 | §10 手順 5 |
| 19 | VictoriaMetrics での delta の破棄と名前の変換 | R-5 | VictoriaMetrics を採る場合のみ |
| 20 | `OTEL_RESOURCE_ATTRIBUTES` が起動時にだけ読み込まれること | R-11 | 候補1・4を採る場合に確認する |
| 21 | file モードの書き出しが `OTEL_LOGS_EXPORTER` に依存するか | §7.2 | R5 を解釈 B で読む場合のみ（§10 手順 2） |
| 22 | console エクスポータの出力先と、`-p --resume` でのスラッシュコマンドの実行 | §8.1 | §10 手順 1 の最初に確かめる |
| 23 | `x-amzn-requestid` が `request_id` に使われること | §9.3 | V-10 で兼ねる |
| 24 | 4種類のトークンの単価 | R-6 | Anthropic の料金ページで確かめる（コストの集計を設計する前） |
| 25 | `OTEL_METRICS_INCLUDE_*` がプロジェクト設定でも有効か | R-2 | プロジェクト設定を使う場合のみ |
| 26 | logrotate が Windows ネイティブで使えないこと、YAML でのバックスラッシュの扱い | §5.4 | V-13 と合わせて確認する |

**区分3: 無印だが、確認しておくべきもの**（作業指示者の方針により、正確性に少しでも疑いがある記述を挙げる）

| # | 確認すること | 箇所 | 時期・方法 |
|---|---|---|---|
| 27 | fileexporter の各設定（`append` の既定値、`rotation` と `append` の併用不可、`flush_interval` の無視、`max_backups` の既定値）が、導入するバージョンでも README どおりか | §5.4 | §10 手順 3（V-6 と合わせて） |
| 28 | DuckDB の拡張子による圧縮形式の自動判別と、`maximum_object_size` の既定値 | §3.1、§5.5 | §10 手順 4〜5 |
| 29 | Prometheus の `--web.enable-otlp-receiver`、受信パス、delta を受け付ける機能フラグ（`otlp-deltatocumulative` など）、保持期間の既定値（15d） | R-5 | §10 手順 8 |
| 30 | `effort` 属性が付かない条件と、`speed` の値 | §4.2 | V-1〜V-3 の出力で合わせて確認する |
| 31 | `subagent_completed` の属性と、`agent_type` の墨消しの規則 | §4.8 | V-5 と合わせて確認する |
| 32 | `SessionStart` hook の `source` と、hook 入力の `prompt_id` | §4.5、R-11 | V-8、または R-11 の候補5を採る場合 |
| 33 | `index.jsonl` のフィールドと、ボディの中の thinking の内容が伏せられること | §7.2 | R5 を解釈 B で読む場合のみ（§10 手順 2） |

---

## 9. デプロイ形態による違い（該当する場合のみ）

各項目の冒頭に、どの形態に当てはまるかを書いている。当てはまらない項目は読み飛ばしてよい。

### 9.1 利用者を識別する属性が埋まらない
**対象**: 直接の API キー、Amazon Bedrock、Google Cloud's Agent Platform、Microsoft Foundry で認証している場合

- セッションに Claude アカウントがない場合、`user.id` と `session.id` にしか値が入らない。`organization.id`、`user.email`、`user.account_uuid`、`user.account_id` には値が入らない（S1' L87054）。
- **対策**: `OTEL_RESOURCE_ATTRIBUTES` を使い、利用者の識別子を自分で付ける。

```bash
export OTEL_RESOURCE_ATTRIBUTES="enduser.id=jdoe@example.com"
```

- 1人だけで分析するなら、実害は小さい。将来チームに展開する予定があるなら、最初から付けておくほうがよい。【推測】

### 9.2 `client_request_id` が出ない
**対象**: サードパーティのプロバイダ（Bedrock など）を経由している場合

- この場合、`client_request_id` は付かない。
- リクエストとレスポンスの対応付けには `request_id` を使うこと。

### 9.3 Bedrock の場合の `request_id` の取得元
**対象**: Bedrock など、レスポンスに `request-id` ヘッダが付かない場合

- `x-amzn-requestid` ヘッダの値が `request_id` として使われる（v2.1.282 以降）。【要確認】
  - S1' にはこの記述がない。S1' の `request_id` の説明は、`request-id` レスポンスヘッダに由来するものだけである（S1' L86446）。
- Bedrock 経由の実際の環境で、この挙動を確かめること（§8 V-10）。

### 9.4 `internal_error` イベントが出ない
**対象**: Amazon Bedrock、Google Cloud's Agent Platform、Microsoft Foundry を使っている場合

- これらのプロバイダを使っている場合、`claude_code.internal_error` イベントは送出されない（S1' L86638）。
- `DISABLE_ERROR_REPORTING` を設定した場合も、このイベントは送出されない（S1' L86638）。
- エラーの監視を設計するときは、この点に注意すること。

### 9.5 トレースのコンテキストが伝わらない
**対象**: サードパーティのプロバイダを経由している場合

- `traceparent` ヘッダは、サードパーティのプロバイダには送られない。
- `ANTHROPIC_BASE_URL` を独自のプロキシに向けていて、そこにトレースのコンテキストを伝えたい場合は、`CLAUDE_CODE_PROPAGATE_TRACEPARENT=1` を設定する。

### 9.6 思考トークンの内訳が取れない可能性
**対象**: Bedrock を経由している場合

- レスポンスの usage とトランスクリプトに `output_tokens_details.thinking_tokens` が含まれるかどうかは確認していない（§8 V-10）。【要確認】

### 9.7 MCP を使わない環境
**対象**: MCP サーバを使わない場合

- `mcp_server.name`、`mcp_tool.name`、`mcp_server_scope`、および MCP サーバの接続に関するイベントは無視してよい。§4.4 の墨消しの表からも、該当する行を削除してよい。

---

## 10. 実装の順序

1. **console エクスポータとトランスクリプトで検証する**: V-1、V-2a、V-3、V-7、V-8、V-9、V-12 を行い、実際の属性名と値を記録する（記録の方法は §8.1）。該当する場合は V-10 も行う。この手順では、内容記録のフラグ（§5.2）は必要ない。
2. **内容記録のフラグが必要な項目を検証する**: §5.2 のフラグについて必要な承認を得たうえで、V-5 と V-2b を行う。R5 の解釈（§2.4）の確認も、この段階でまとめて行う。承認を待つ間は、この手順だけを後回しにしてよい。
3. **Collector を導入する**: otelcol-contrib を導入し、file exporter で JSONL に出力する（§5.4）。**導入した直後に V-6（再起動してもデータが消えないか、ローテーション後のファイル名）、V-4（属性の型、リソース属性の位置）、V-13（Windows でのパスの書き方）を確認する。** V-13 のうち `file:<dir>` の部分は、手順 2 と合わせて行う。
4. **クエリのひな形を書く**: 検証の結果をもとに、DuckDB のクエリのひな形を書く。まず `model` × `effort` × `query_source` の `GROUP BY` から始める。`service.version` は、V-4 で確かめた位置から取り出す（§5.5）。
5. **圧縮の仕組みを入れる**: ローテーション済みのファイルを外部ツールで圧縮する仕組みを入れる（§6 R-3、§5.5）。Windows で使う圧縮の手段は、この時点で選ぶ（§6 R-3）。
6. **データを貯める**: 1〜2週間データを貯め、`query_source` の値の分布を確認する。これが最初の分析材料になる。【推測】
   - 貯め始める前に、トランスクリプトを使う場合は `cleanupPeriodDays` を分析期間より長い値に見直す（R-13、§2.4 経路 A）。
7. **比較実験を設計する**: 仮説 H-1〜H-3（§4.5）を検証するための比較実験を設計する。
8. **可視化を追加する**: 見るべき指標が固まったら、Prometheus と Grafana を追加する（temporality を `cumulative` に切り替える。Prometheus の機能フラグは §6 R-5）。

V-11(b) の各項目は、§8.5 の「時期・方法」列に従い、上の手順の中で確認する。

---

## 変更履歴

改訂内容の詳細は `【別紙】改訂履歴.md` に記録する。

| 日付 | 版数 | 概要 |
|---|---|---|
| 2026-09-26 | v1 | 初版（Chat 版 Claude、Opus 5） |
| 2026-09-26 | v2 | 反復セルフレビューによる改訂（Chat 版 Claude、Opus 5.5） |
| 2026-09-27 | v2.1 | 第三者クロスレビュー（論理整合性・実用性）の確定指摘を反映（Claude Code、Opus） |
