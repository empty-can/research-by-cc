# Claude Code トークン/コスト計測基盤 — 設計引き継ぎ資料（v2）

- **作成日**: 2026-09-26
- **対象バージョン**: Claude Code v2.1.283（利用者がローカル環境で確認済み）
- **執筆**: v1 は Claude Opus 5 が執筆した。v2 の改訂と反復セルフレビューは Claude Opus 5.5 が行った。どちらも同一セッション・同一コンテキストの中での作業である。
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

**無印の扱い**: 本資料では、ドキュメントの記述がソースコードや実際の挙動と一致するかを網羅的には確認していない。したがって無印の記述にも、厳密には動作確認の余地が残る。【要検証】は、確認すべき具体的な理由がある項目と、設計への影響が特に大きい項目に限って付けた。それ以外の無印項目は、§8 の検証計画の中でまとめて確認する前提である。

### 0.2 情報源

| ID | 情報源 | 状態 |
|---|---|---|
| S1 | Claude Code Monitoring https://code.claude.com/docs/en/monitoring-usage （2026-09-26 取得） | **冒頭から「Tool decision event」節の途中までしか取得できていない。** 取得ツールが長いページを途中で切り詰めるためと考えられる。【推測】 |
| S2 | 同じページの旧版（約2ヶ月前、本セッション前半で取得） | ほぼ全文を取得した。末尾の「Audit security events」節の最後の表だけが欠けている。v2.1.283 時点の内容と同じかどうかは確認していない。 |
| S3 | Claude API Extended thinking https://platform.claude.com/docs/en/build-with-claude/extended-thinking | 必要な記述を取得した。 |
| S4 | OTel Collector contrib fileexporter README https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/exporter/fileexporter/README.md | 設定オプションの記述を取得した（main ブランチ）。 |
| S5 | DuckDB Loading JSON https://duckdb.org/docs/lts/data/json/loading_json | 必要な記述を取得した。 |
| S6 | Prometheus Storage https://prometheus.io/docs/prometheus/latest/storage/ 、OpenTelemetry ガイド https://prometheus.io/docs/guides/opentelemetry/ | Storage は取得した。OTel ガイドは検索結果の抜粋でのみ確認した。 |
| S7 | 非公式の技術ブログ（VictoriaMetrics の運用記事など） | 公式情報ではない。 |

**S1 の取得が途中で切れたことの影響**: S1 の後半にある次の部分は、v2.1.283 版では確認できていない。

- Tool decision event より後に定義されているイベント（compaction など）
- 「Interpret metrics and events data」節
- 「Audit security events」節

これらに依拠する記述には【要確認】を付けている。

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

### 2.4 要件充足の見通し

**R1（モデルとバージョン）**
- 「バージョン」には2つの意味がありうるので、両方に対応する。【推測】
  - **モデルのバージョン**: `model` 属性に入るモデル識別子の文字列（例: `claude-sonnet-5`）で区別できる。
  - **Claude Code のバージョン**: `app.version` 属性で区別できる。ただし既定では付かない（§4.2）。
- `app.version` がイベントに付かなかった場合でも、`session.id` をキーにしてメトリクス側の `app.version` と結合すれば補える。【推測】

**R2（メインとサブエージェントの区別）**
- `query_source`、`agent.name`、`skill.name`、`workflow.run_id` で区別できる（§4.2〜§4.4）。
- `skill.name` については、S1 に「Skill ツールや `/` コマンドで設定されるほか、起動されたサブエージェントにも引き継がれる」と記載がある。したがって、Skill の中で起動したサブエージェントのリクエストにも同じ skill 名が付く。
- 実際にどの値が入るかは §8 の V-5 と V-7 で確かめる。【要検証】

**R3（思考トークンを含む送受信トークン数）**
- S3 によると、API レスポンスの `usage.output_tokens_details.thinking_tokens` は「課金される出力トークンのうち、内部推論に当たるものが何トークンか」を示す。つまり思考トークンは、課金される出力トークンの一部として数えられている。
- Claude Code の `api_request` イベントの `output_tokens`（説明は "Number of output tokens"）は、API の usage の出力トークン数をそのまま反映した値と考えられる。【推測】
  - 根拠: 同じ S1 のスパン属性では `input_tokens` が "from the API usage block" と説明されている。
- 以上から、`output_tokens` には思考トークンが含まれると判断した。【推測・要検証】
  - なお S3 は、`usage.output_tokens` フィールドそのものに思考分が含まれるとまでは明記していない。
- statusline に思考トークンが表示されないのは表示側の都合であり、テレメトリの値には影響しない。【推測】

**R3 に関連して新たに見つかった論点（思考トークンの内訳）**
- `claude_code.api_request` イベントの属性一覧（S1）には、思考トークンの内訳を示す属性がない。
- そのため、effort を変えたときに思考トークンが単独でどれだけ増減したかは、OTel のイベントやメトリクスからは直接わからない。【推測】
- 内訳が必要なら、生のレスポンスボディ（§7.2）にある `usage.output_tokens_details.thinking_tokens` を読むことになる。【推測】
  - Claude Code が記録するレスポンスボディに、このフィールドが含まれる。【要確認】
  - Amazon Bedrock 経由でも、このフィールドが返る。【要確認】
- 参考として、S3 によるとストリーミング時にはこの内訳は最後の `message_delta` イベントにだけ載る。

**R4（時系列）・R5（生データ）**
- 満たせる見通しである（§3、§7.2）。【推測】
- ただし R4 を満たすには、§6 R-1（Collector を再起動するとデータが消える問題）への対策が済んでいることが前提になる。【推測】

**2.2 の「セッション名」**
- S1 の標準属性の一覧には、人が付けたセッション名に当たる属性がない。取れるのは `session.id`（UUID）である。
- Claude Code でセッションに名前を付けた場合に、その名前がテレメトリに載るかは確認していない。【要確認】
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

  └─ OTEL_LOG_RAW_API_BODIES=file:<dir>（Collector を経由せず、Claude Code が直接ディスクに書き込む）
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
- **注意**: DuckDB がそのまま読めるのは、外部ツールでファイル全体を gzip または zstd で圧縮したファイルに限られる見込みである。Collector の `compression` 設定で圧縮したファイルは、直接読めない可能性が高い（§6 R-3）。【推測・要検証】

**Prometheus を後から追加する理由**
- トークンの分析には Prometheus は必要ない（§4.1）。【推測】
- 一方で、産出量（変更行数など）の指標はメトリクスとしてしか出力されない（§4.1）。これはコスト対効果を計算するときの分母になる。そのため、見るべき指標が固まった段階で Prometheus を追加する。【推測】

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
| 産出量（変更行数、commit 数、PR 数、アクティブ時間） | **メトリクスのみ** | イベントからは復元できない【推測】 |

**結論**: トークンとコストの分析では、イベントのデータが主になる。Prometheus は、トークンのためではなく、コスト対効果の分母を得るために置く。【推測】

### 4.2 要件と属性の対応（`app.version` を除き、`claude_code.api_request` イベントだけで揃う）

| 要件 | 属性 |
|---|---|
| R1 モデル | `model`（モデル識別子。モデルのバージョンもこの値で区別できる） |
| R1 Claude Code のバージョン | `app.version`。既定では付かないので `OTEL_METRICS_INCLUDE_VERSION=true` が必要。この変数がイベントにも効くかは、ドキュメントの書き方が曖昧で確定できていない（§8 V-3）。【要検証】 |
| effort | `effort`（`low` / `medium` / `high` / `xhigh` / `max`）。Claude Code が effort を送らないリクエストでは、この属性自体が付かない（例: effort に対応していないモデル）。集計では、値がない行を別のグループとして扱う必要がある。 |
| R2 メイン/サブエージェント | `query_source`、`agent.name` |
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
| 実行主体 | `query_source` / `skill.name` / `workflow.run_id` | イベントとスパン（スパンでは一部の属性に出力条件がある。§6 R-14） |

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
| `skill.name` | サードパーティ製プラグインの skill は `"third-party"` に置き換わる | 元の名前 |
| `plugin.name` | サードパーティ製プラグインは `"third-party"` に置き換わる | 元の名前 |
| `mcp_server.name` / `mcp_tool.name` | ユーザーが設定したサーバは `"custom"` に置き換わる | 元の名前 |
| `workflow.name` | ユーザーが作成した workflow は `"custom"` に置き換わる | 元の名前 |
| `command_name`（user_prompt イベント） | カスタム・プラグイン・MCP のコマンドは `custom` / `mcp` にまとめられる | 元の名前 |

- 組み込みのエージェント名は、フラグがなくても元の名前で出力される。
- 組み込み、同梱（bundled）、ユーザー定義、公式マーケットプレイス由来の skill 名も、フラグがなくても元の名前で出力される。

**設計上の含意**
- `OTEL_LOG_TOOL_DETAILS=1` を設定すれば、メトリクスだけでもカスタムサブエージェントごとのトークン集計ができる。ただし時系列の数（カーディナリティ）が増える。【推測・要検証】
- イベントの `query_source` については、S1 の説明に出力条件が書かれていない。値は `"repl_main_thread"`、`"compact"`、またはサブエージェント名そのものである。
- したがって、フラグなしでもサブエージェントを識別できると判断した。【推測・要検証】
- ただし、スパン側では、生の `query_source` に出力条件が付いている（§6 R-14）。
- このことから、イベント側でも将来同じような制限が加わる可能性は否定できない。【推測】
- このフラグを有効にすると、ツールの入力内容なども記録される（§7.1）。

### 4.5 `/compact` と `/clear` の分析材料

- `claude_code.compaction` イベントの v2.1.283 での属性は確認できていない（§8 V-1）。【要確認】
  - 参考までに、旧版（S2）には次の属性があった。
  - `trigger`（`auto` / `manual`）
  - `pre_tokens`（圧縮前のおおよそのトークン数）
  - `post_tokens`（圧縮後のおおよそのトークン数）
  - `duration_ms`
  - `success`
  - `error`
  - `precompute_reuse`（`manual` のときだけ付く。値は `hit` / `miss_custom_instructions` / `miss_hook` / `miss_not_ready`）
- 圧縮処理そのものの API 呼び出しは、`api_request` イベントに `query_source: "compact"` として記録される（S1 に値の例として `"compact"` が挙がっている）。
  - これを使えば、「圧縮で減ったコンテキストの量」と「圧縮のために払ったトークン代」を突き合わせられる。【推測】
- `/clear` を実行すると、新しい `session.id` が割り当てられる（S1 の `event.sequence` の説明にある）。
- したがって、`/clear` の区切りは `session.id` が切り替わった地点として取得できる。【推測】
- `/clear` には専用のイベントがないと考えられる。旧版（S2）のイベント一覧に該当するものがなかったことからの推論であり、v2.1.283 では確認していない（§8 V-8）。【推測】

**分析のための仮説**

**H-1**: effort が高いセッションほど、`/compact` による input トークンの削減効果が大きい。【仮説】
- S3 によると、Claude Opus 4.5 と、バージョン番号が 4.6 以上のモデルは、過去のターンの thinking ブロックをコンテキストに残し、input として課金する。
- 利用中の Opus 5 や Sonnet 5 がこの「4.6 以上」に当たるというのは、執筆モデルの判断である。【推測】
- もし当たるなら、effort が高い（思考量が多い）セッションほど、後のターンの input トークンが蓄積した思考の分だけ膨らむ。そのため、`/compact` や `/clear` による削減効果も大きく出るはずである。【仮説】

**H-2**: 同じ作業でも、`/clear` をして必要な文脈だけを渡し直すほうが、`/compact` よりも総トークン数が少なくなる場合がある。ただし、作業品質への影響は作業の種類によって異なる。【仮説】

**H-3**: effort がコストに与える影響は、そのリクエストの `output_tokens` だけでは測りきれない。【仮説】
- H-1 の仕組みがはたらくなら、影響は後のターンの `input_tokens` や `cache_read_tokens` にも及ぶ。【仮説】
- したがって effort の影響は、リクエスト単位ではなく、セッション単位または作業（`prompt.id`）単位の合計で比べる必要がある。【推測】

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

---

## 5. 設定

### 5.1 環境変数（基本セット：プロンプト本文や会話内容は記録しない）

```bash
# --- 基本 ---
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf   # Claude Code にはプロトコルの既定値がないので、必ず指定する
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318

# --- 必須要件のため ---
export OTEL_METRICS_INCLUDE_VERSION=true        # R1: app.version（既定は false）

# --- あると望ましい項目のため（§2.2）---
export OTEL_METRICS_INCLUDE_REPOSITORY=true     # リポジトリ名: vcs.* 属性（既定は false。v2.1.269 以降）

# --- 任意 ---
export OTEL_METRICS_INCLUDE_ENTRYPOINT=true     # app.entrypoint（既定は false）

# --- 送信間隔（既定値のままでよいが、値は把握しておく）---
# OTEL_METRIC_EXPORT_INTERVAL=60000   # メトリクスの送信間隔。既定は 60000ms。時系列の粒度はこの値で決まる
# OTEL_LOGS_EXPORT_INTERVAL=5000      # ログの送信間隔。既定は 5000ms
```

- **設定を書く場所**: シェル、`~/.claude/settings.json`、または managed settings に書く。リポジトリ内の `.claude/settings.json` に書いても無視される（§6 R-2）。
- **子プロセスへの継承**: Claude Code は、自分が起動する子プロセス（Bash ツール、hooks、MCP サーバ、language server）に `OTEL_*` 環境変数を渡さない。

### 5.2 環境変数（内容記録セット：§7.1 を読み、必要に応じて承認を得てから有効にする）

このセットを有効にすると分析の解像度は上がるが、会話の内容も記録される。

本構成では、R5（生データの取得）を `OTEL_LOG_RAW_API_BODIES` で満たす設計にしている。したがって R5 のためには、このセットのうち少なくとも `OTEL_LOG_RAW_API_BODIES` を有効にする必要がある。【推測】

```bash
# --- 生データ（R5）。会話履歴の全体がディスクに残る ---
export OTEL_LOG_RAW_API_BODIES=file:/path/to/raw-bodies

# --- 分析の解像度を上げる ---
export OTEL_LOG_USER_PROMPTS=1          # プロンプト本文を記録する（§4.3 の作業内容の復元に使う）
export OTEL_LOG_ASSISTANT_RESPONSES=0   # 下の注意を参照。応答本文も残したい場合にだけ 1 にする
export OTEL_LOG_TOOL_DETAILS=1          # 墨消しを解除する（§4.4）。ツールの入力内容なども記録される
```

- **`OTEL_LOG_ASSISTANT_RESPONSES` の注意**: この変数を設定しない場合は、`OTEL_LOG_USER_PROMPTS` の値が代わりに使われる。プロンプトだけを記録して応答本文は伏せておきたい場合は、明示的に `0` を設定する必要がある。
- **承認の要否**: 所属する組織の規程で、これらのフラグを有効にする前に承認が必要かどうかを確認すること。【推測】

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
- **`rotation` を設定すると、`flush_interval` は無視され、書き込みはバッファされなくなる。**
- **metrics と logs は別のファイルに分ける。** スキーマが異なるため、1つのファイルに混ざると DuckDB で扱いにくくなる。【推測】
- **fileexporter の安定度はアルファである**（logs と metrics のどちらも）。
  - そのため、設定オプションはバージョンによって変わる可能性がある。【推測】
  - 導入するバージョンの README で、本節の設定が使えることを確認すること。
- `max_megabytes: 100` と `max_backups: 1000` の組み合わせでは、保存容量の上限はおよそ 100GB になる。1人で1ヶ月使う分には十分だと考えられる。【推測】
- ローテーションで作られるバックアップファイルの名前には、タイムスタンプが含まれる（README の `max_days` の説明に "timestamp encoded in their filename" とある）。
  - ただし、正確な命名規則は確認していない。§5.5 のグロブ指定がバックアップファイルにも一致するかは、導入時に確認すること。【要確認】

### 5.5 DuckDB で読むときの注意

**出力の形式**
- fileexporter の既定の出力形式は json で、1行に1つの JSON オブジェクトが書かれる（S4）。
- 各行は OTLP の JSON エンコーディングになっており、1回のエクスポート要求の内容がまとめて1行に書かれる。そのため、1行の中に複数のログレコードが入れ子の形で含まれる。【要検証】
  - ログの場合の入れ子の構造: `resourceLogs[] → scopeLogs[] → logRecords[]`
  - 各レコードの属性は、`{key, value: {stringValue | intValue | doubleValue | boolValue}}` という形の配列で表される。【要検証】

**数値の扱い**
- OTLP の JSON エンコーディングでは、64ビット整数（`intValue` や、タイムスタンプの `timeUnixNano` など）が文字列として出力されることがある（protobuf の JSON マッピングについての一般知識に基づく）。【要確認】
- そのため、集計の前に数値型へ CAST すること。
- Claude Code が `input_tokens` などを整数型で送っているのか、文字列型で送っているのかは確認していない（§8 V-4）。【要確認】

**スキーマの推定**
- `read_json_auto` は、ファイルの先頭部分のサンプルから列の型を推定する（DuckDB の一般的な挙動についての知識に基づく）。【要確認】
- そのため、行によって属性値の型（`stringValue` か `intValue` か）が違うと、推定から漏れた型の値が読めない可能性がある。【推測】
- 対策として、`sample_size` を大きくする、`union_by_name=true` を指定する、属性を JSON 型のまま読み込む、といった方法を検討する。【推測】

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
  SELECT unnest(rl.scopeLogs) AS sl FROM rl
), lr AS (
  SELECT unnest(sl.logRecords) AS r FROM sl
)
SELECT
  list_filter(r.attributes, a -> a.key = 'event.name')[1].value.stringValue   AS event_name,
  list_filter(r.attributes, a -> a.key = 'model')[1].value.stringValue        AS model,
  list_filter(r.attributes, a -> a.key = 'query_source')[1].value.stringValue AS query_source,
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
- リポジトリの `.claude/settings.json` と `.claude/settings.local.json` に書いた OTel 関連の変数は、無視される。
- シェル、`~/.claude/settings.json`、または managed settings に書くこと。
- 例外として、リポジトリ側から `OTEL_LOGS_EXPORTER=none` のように指定して、シグナルを**無効にすることだけ**はできる。

### R-3 【重大】Collector 側で圧縮すると、DuckDB で直接読めない可能性がある
- S4 には、`format` が json で `compression` が none の場合は、各行が1つの JSON オブジェクトになると書かれている。
- 一方で、proto 形式や、エンコードされたデータの場合は、各オブジェクトの前にその長さを表す4バイトが付くとされている。
- このことから、Collector で `compression: zstd` を設定したファイルは行区切りの JSON にならず、DuckDB の `read_json` では読めないと考えられる。【推測・要検証】
- **対策**: Collector 側では圧縮しない。ローテーション済みのファイルを、外部ツールでファイル全体ごと gzip または zstd に圧縮する（拡張子は `.gz` / `.zst`）。DuckDB は拡張子から圧縮形式を自動で判別して読める（S5）。

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
- delta 形式のまま受け付けるには、実験的な機能フラグ `--feature-flag=otlp-deltatocumulative` が必要になる（S6 の抜粋に基づく。機能フラグは実験的な扱い）。【要検証】
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
- 正式な請求額は、利用しているプロバイダ（Claude Console、Amazon Bedrock、Google Cloud）で確認すること（この案内は旧版 S2 の記述）。【要確認】
- トークン数そのものは API の usage に基づく値なので、コストの推定値よりも信頼できる。【推測】

### R-8 モデル別の commit 数は直接は取れない
- `commit.count` には `model` 属性がない（S1 の Commit counter の説明には、標準属性しか挙がっていない）。
- 近似的に求めるには、`session.id` をキーにして、トークンまたはコストのメトリクスと結合する（旧版 S2 の記述）。【要確認】
- その際、トークン側を `query_source = "main"` に絞り込む必要がある。絞り込まないと、サブエージェントや補助的なリクエストで使われたモデルに、そのセッションの commit が割り当てられてしまう（この近似方法は旧版 S2 の記述であり、考え方として妥当だという判断は執筆モデルによる）。【要確認・推測】

### R-9 セッション数を分母にするときは、`start_type` で一部を除外する
- `claude_code.session.count` には `start_type` 属性があり、値は `fresh` / `resume` / `continue` / `agents_view` のいずれかである。
- `agents_view` は `claude agents` ダッシュボード（利用者が起動するローカルの UI）を起動したことを表し、会話のセッションではない。
- セッション数を分母にする集計では `agents_view` を除外すること。`resume` と `continue` を数えるかどうかは、分析の目的に応じて決める。【推測】

### R-10 `mcp_server.name` の意味が v2.1.222 で変わった
- 以前は、MCP ツールを呼んだ後のすべてのリクエストにこの属性が付いていた。
- 現在は、MCP ツールの結果を受け取ったリクエストにだけ付く。
- そのため、古いバージョンのデータとつなげて集計すると、値に段差が出る（ドキュメントにも明記されている）。

### R-11 セッションの途中で作業ラベルを付ける手段はない
- `OTEL_RESOURCE_ATTRIBUTES` は、プロセスの起動時に読み込まれる環境変数である（OTel の一般的な仕組みに基づく）。【要確認】
- そのため、セッションの途中で「ここから作業X」というタグを付けることはできない。【推測】
- 回避策は次の2つがある。後者を推奨する。【推測】
  1. 作業ごとにセッションを分け、起動時にラベルを渡す
  2. `prompt.id` とプロンプト本文をもとに、後から分類する（今の運用を変えずに済む）

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
- Claude Code には、トランスクリプトを一定期間後に削除する設定（`cleanupPeriodDays`、既定は30日）がある。1ヶ月を超えてトランスクリプトと結合する予定があるなら、この値を見直すこと。【要確認】

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

- `OTEL_LOG_RAW_API_BODIES` を有効にすると、上の3つのフラグで記録される内容すべてに同意したものとみなされる（ドキュメントに明記されている）。
- ローカルで完結する構成でも、ファイルのアクセス権限と、バックアップの対象から外すかどうかは、設計の段階で決めておくこと。【推測】
- ツールの利用方針を管理する部門が組織にある場合は、これらのフラグを有効にする前に承認が必要かどうかを確認すること。【推測】

### 7.2 生データの実体（R5 を満たす主な手段）

`OTEL_LOG_RAW_API_BODIES=file:<dir>` を設定すると、Claude Code は Collector を経由せず、直接ディスクに書き込む。

- `<dir>/<uuid>.request.json` — 切り詰められていないリクエストボディ
- `<dir>/<request_id>.response.json` — 切り詰められていないレスポンスボディ
- `<dir>/index.jsonl` — 成功したレスポンス1件につき1行（v2.1.274 以降）

**`index.jsonl` の各行に含まれるフィールド**: `timestamp`, `session_id`, `query_source`, `model`, `request_id`, `message_id`, `message_uuid`, `request_file`, `response_file`

- テレメトリのバックエンドに問い合わせなくても、トランスクリプトのメッセージから、対応する生のリクエストとレスポンスをたどれる。
- `index.jsonl` は DuckDB で直接読めるので、R5 を満たす最も手軽な方法になる。【推測】
- ファイルへの書き出しが、logs エクスポータの設定（`OTEL_LOGS_EXPORTER`）に依存するかどうかは確認していない。【要確認】
- 本構成では logs エクスポータを有効にしているので、実際には問題にならない見込みである。【推測】
- `api_request_body` イベントと `api_response_body` イベントには `request_body_id` がある。これを使うと、リトライを含めて、どの試行のリクエストがどのレスポンスを生んだのかを対応付けられる（v2.1.274 以降）。

**thinking の内容の扱い**
- リクエストボディでは、過去のアシスタントのターンに含まれる extended thinking の内容が伏せられる。レスポンスボディでも、extended thinking の内容は伏せられる。
- これは思考の**内容**についての扱いであり、トークンの**数**（usage）とは別の問題である。思考トークンの数がボディに残るかどうかは、§8 の V-2 で確認する。【推測】

### 7.3 内容の切り詰め
- `CLAUDE_CODE_OTEL_CONTENT_MAX_LENGTH` の既定値は 61440（60KB。UTF-16 のコードユニットで数える）である。これは、属性値の上限を 64KB としているバックエンドに合わせた値である。
- ローカルのファイルに出力するだけなら、値を引き上げてもよい。ただし、SDK 側の上限（`OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` など）のほうが小さい場合は、そちらの値で切り詰められる。
- 値を引き上げる場合は、DuckDB 側の `maximum_object_size`（§5.5）との兼ね合いにも注意すること。【推測】

---

## 8. 未検証の事項と検証計画

### 8.1 進め方

v2.1.283 は手元にある。そのため、Collector を立てる前に、console エクスポータで実際の出力を確認するのが最も確実で速い。【推測】

```bash
CLAUDE_CODE_ENABLE_TELEMETRY=1 OTEL_LOGS_EXPORTER=console OTEL_METRICS_EXPORTER=console claude
```

項目によっては、§5.2 のフラグや Collector も必要になる。何が必要かは、次の表の「必要なもの」列を参照すること。

**スキーマとクエリは、以下の検証が済んでから設計すること。** 構成を固めた後で属性名の違いに気づくと、大きな手戻りになる。

### 8.2 検証項目

| ID | 確認すること | 方法 | 必要なもの | 影響する箇所 |
|---|---|---|---|---|
| V-1 | `claude_code.compaction` の v2.1.283 での実際の属性 | `/compact` を実行し、console への出力を記録する | console | §4.5、問い1 |
| V-2 | **R3**: `output_tokens` に思考トークンが含まれるか。思考トークンの内訳が取れるか | effort を高くしてリクエストを送り、生のレスポンスの `usage.output_tokens` と `usage.output_tokens_details.thinking_tokens` を比べる。後者が存在するかどうかも確認する | `OTEL_LOG_RAW_API_BODIES`（§5.2） | §2.4、R3 |
| V-3 | `OTEL_METRICS_INCLUDE_VERSION=true` のとき、`app.version` がイベントにも付くか | 変数を設定した場合としない場合で、`api_request` の出力を比べる | console | §4.2、R1 |
| V-4 | トークン数などの属性の型（整数か文字列か） | JSON ファイルの `intValue` / `stringValue` を確認する | Collector | §5.5 |
| V-5 | カスタムサブエージェントのときに `query_source` に入る値。フラグありのときに `agent.name` が元の名前で出るか | 実際に起動して出力を確認する | console、`OTEL_LOG_TOOL_DETAILS`（§5.2） | §4.4、R2 |
| V-6 | **Collector を再起動しても既存のデータが消えないか**（`rotation` を設定した状態で） | 停止と起動を行い、前後でファイルの内容とサイズを比べる | Collector | §5.4、R-1 |
| V-7 | Skill や workflow の実行時の `skill.name`、`workflow.run_id`、`workflow.name` の実際の値 | 実際に実行して出力を確認する | console | R2 |
| V-8 | `/clear` の実行時に専用のイベントが出るか | `/clear` を実行する | console | §4.5 |
| V-9 | 実際に出力されるイベント名の全体（§8.3 を確定させる） | ひととおりの操作をして出力を集める | console | §8.3 |
| V-10 | Bedrock 経由の場合（該当する場合のみ）: 標準属性の埋まり方、`client_request_id` が付かないこと、usage のフィールド構成 | Bedrock 経由で実行する | console、`OTEL_LOG_RAW_API_BODIES` | §9 |

### 8.3 v2.1.283 版で確認できていないイベント【節全体：要確認】

旧版（S2）には、次のイベントが掲載されていた。v2.1.283 でもあるかどうか、また属性がどうなっているかは確認していない。

`permission_mode_changed` / `auth` / `mcp_server_connection` / `internal_error` / `plugin_installed` / `plugin_loaded` / `skill_activated` / `at_mention` / `api_retries_exhausted` / `hook_registered` / `hook_execution_start` / `hook_execution_complete` / `hook_plugin_metrics` / `compaction` / `feedback_survey`

### 8.4 間接的に存在を確認した新しいイベント
- `managed_settings_resolved` イベントは、S1 の設定変数の表からリンクされていることで、存在を確認した。
- `OTEL_LOG_MANAGED_SETTINGS=1` を設定すると、伏せ字処理を施した managed settings と、伏せ字処理の前の設定の SHA-256 ダイジェストが付加される（v2.1.274 以降）。
- この変数は、プロジェクト設定やローカル設定に書いても有効にならない。
- イベント自体の属性の定義は確認していない。【要確認】

---

## 9. デプロイ形態による違い（該当する場合のみ）

各項目の冒頭に、どの形態に当てはまるかを書いている。当てはまらない項目は読み飛ばしてよい。

### 9.1 利用者を識別する属性が埋まらない
**対象**: 直接の API キー、Amazon Bedrock、Google Cloud's Agent Platform、Microsoft Foundry で認証している場合（旧版 S2 の記述による）【要確認】

- セッションに Claude アカウントがない場合、`user.id` と `session.id` にしか値が入らない。`organization.id`、`user.email`、`user.account_uuid`、`user.account_id` には値が入らない。【要確認】
  - この記述は、旧版 S2 の「Audit security events」節に基づく。v2.1.283 版の同じ節は取得できていない。
- ただし、S1 の標準属性の表でも、これらの属性には「(when authenticated)」などの条件が付いている。
- そのため、現在も同じ挙動である可能性が高い。【推測】
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

- `x-amzn-requestid` ヘッダの値が `request_id` として使われる（v2.1.282 以降）。
- v2.1.283 でも機能するはずだが、Bedrock 経由の実際の環境では確認していない。【要検証】

### 9.4 `internal_error` イベントが出ない
**対象**: Amazon Bedrock、Google Cloud's Agent Platform、Microsoft Foundry を使っている場合

- これらのプロバイダを使っている場合、`claude_code.internal_error` イベントは送出されない（旧版 S2 の記述）。【要確認】
- エラーの監視を設計するときは、この点に注意すること。

### 9.5 トレースのコンテキストが伝わらない
**対象**: サードパーティのプロバイダを経由している場合

- `traceparent` ヘッダは、サードパーティのプロバイダには送られない。
- `ANTHROPIC_BASE_URL` を独自のプロキシに向けていて、そこにトレースのコンテキストを伝えたい場合は、`CLAUDE_CODE_PROPAGATE_TRACEPARENT=1` を設定する。

### 9.6 思考トークンの内訳が取れない可能性
**対象**: Bedrock を経由している場合

- レスポンスの usage に `output_tokens_details.thinking_tokens` が含まれるかどうかは確認していない（§8 V-10）。【要確認】

### 9.7 MCP を使わない環境
**対象**: MCP サーバを使わない場合

- `mcp_server.name`、`mcp_tool.name`、`mcp_server_scope`、および MCP サーバの接続に関するイベントは無視してよい。§4.4 の墨消しの表からも、該当する行を削除してよい。

---

## 10. 実装の順序

1. **console エクスポータで検証する**: V-1、V-3、V-5、V-7、V-8、V-9 を行い、実際の属性名を記録する。該当する場合は V-10 も行う。
2. **生データ関連を検証する**: §5.2 のフラグについて必要な承認を得たうえで、V-2（R3 の確認）を行う。承認を待つ間は、この手順だけを後回しにしてよい。
3. **Collector を導入する**: otelcol-contrib を導入し、file exporter で JSONL に出力する（§5.4）。**導入した直後に V-6（再起動してもデータが消えないか）と V-4（属性の型）を確認する。**
4. **クエリのひな形を書く**: 検証の結果をもとに、DuckDB のクエリのひな形を書く。まず `model` × `effort` × `query_source` の `GROUP BY` から始める。
5. **圧縮の仕組みを入れる**: ローテーション済みのファイルを外部ツールで圧縮する仕組みを入れる（§6 R-3、§5.5）。
6. **データを貯める**: 1〜2週間データを貯め、`query_source` の値の分布を確認する。これが最初の分析材料になる。【推測】
7. **比較実験を設計する**: 仮説 H-1〜H-3（§4.5）を検証するための比較実験を設計する。
8. **可視化を追加する**: 見るべき指標が固まったら、Prometheus と Grafana を追加する（temporality を `cumulative` に切り替える）。

---

## 付録 A: v1 からの主な変更点

| 区分 | 変更点 |
|---|---|
| 追加 | 確度ラベルと情報源の一覧を追加した（§0） |
| 重大な修正 | Collector の設定例に `rotation` を追加した。v1 の設定例は、再起動のたびにファイルが切り詰められる設定になっていた（R-1） |
| 重大な追加 | Collector 側で圧縮すると DuckDB で読めない可能性を追記した（R-3） |
| 修正 | R3 の根拠を、API ドキュメント（S3）で補強した。思考トークンの内訳が OTel からは取れないという論点を追加した（§2.4） |
| 修正 | 旧版ドキュメントに由来する記述（§9.1、§9.4、R-7、R-8）に【要確認】を付けた。これにより、§8.3 の未確認リストとの矛盾を解消した |
| 修正 | 会話の内容を記録するフラグを、基本セットから内容記録セットに移した（§5.1 / §5.2） |
| 修正 | R-15（`otelHeadersHelper`）の記述を「スクリプトが再び成功するまで届かない」に訂正した |
| 追加 | `start_type` による除外（R-9）、送信間隔、`OTEL_*` が子プロセスに引き継がれないこと、DuckDB での読み込みの注意（§5.5）、仮説 H-1〜H-3、検証計画の表（§8.2）、R1 の「バージョン」の2つの解釈、セッション名の扱い、トランスクリプトの保持期間（R-13） |
| 追加 | 詳細ベータトレースを有効にすると主データのイベントが file exporter に届かなくなるという含意（R-14）、`vcs.*` 属性は Anthropic 側のテレメトリには送られないこと（§5.3）、effort 属性が付かない条件の正確な記述と集計上の扱い（§4.2） |
| 修正 | 確度ラベルの適用規則を明確にした（§0.1）。複数の文から成る項目の扱いと、手順を示す文を対象外とすることを追記し、確度の異なる文が混在していた約15箇所を分割した |
