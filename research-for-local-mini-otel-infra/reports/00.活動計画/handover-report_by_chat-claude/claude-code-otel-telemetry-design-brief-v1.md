# Claude Code トークン/コスト計測基盤 — 設計引き継ぎ資料

**作成日**: 2026-09-26
**対象バージョン**: Claude Code v2.1.283（ローカル確認済み）
**一次情報源**: https://code.claude.com/docs/en/monitoring-usage
**本資料の位置づけ**: 設計・構築を担当する Claude Code セッションへの引き継ぎ。仕様は原則として上記ドキュメントの v2.1.283 時点の記述に基づく。未検証事項は §8 に分離して明示した。

---

## 1. 目的とゴール

### 1.1 一次目的
利用モデルの種類と effort レベルが、実際のトークン消費・コストにどの程度影響しているかを定量測定する。

### 1.2 測定結果を使って答えたい問い
1. `/compact` と `/clear` をどう使い分けるとコストを抑えられるか（利用者向けテクニックの開発）
2. Skill / workflow / カスタムサブエージェントによるオーケストレーションは、出力品質を維持しつつどこまでコストを下げられるか
3. どの作業・どのエージェント・どのツールがコスト的ボトルネックになっているか

### 1.3 背景
Opus をオーケストレータ、Sonnet をサブエージェントとする multi-agent 構成を運用しており、Sonnet への移譲によって Opus 依存をどれだけ減らせたかを、説得力のあるデータで示したい。

---

## 2. 確定要件

### 2.1 必須要件
| # | 要件 |
|---|---|
| R1 | モデル種別とバージョンが識別できること |
| R2 | メインセッション / サブエージェント（Skill・workflow 内で実行されるものを含む）が区別できること |
| R3 | 送信トークン数と受信トークン数が取得できること。**モデルの思考中に発生するトークンを含む値**であること |
| R4 | 1ヶ月程度の範囲で時系列データとして出力できること |
| R5 | 集積された生データが取得できること |

### 2.2 あると望ましい
- 実行中のセッション識別子
- リポジトリ名
- そのトークン消費が「どのセッションの、どんな作業のために」使われたかの紐付け

### 2.3 非機能
- Claude Code を実行している端末上で起動できる軽量な OSS 構成であること
- テレメトリ製品自体に GUI は不要。描画・集計に必要なデータが取れればよい
- 送信先は localhost / 127.0.0.1

### 2.4 要件充足の見通し
R1〜R5 はすべて充足可能。R3 について、extended thinking の出力トークンは API の usage 上 `output_tokens` に含まれて課金されるため、`output_tokens` をそのまま使えばよい。statusline に表示されないのは表示側の都合であり、テレメトリの値は元から思考分を含む。

---

## 3. 採用構成

```
Claude Code
  └─ OTLP (http/protobuf) → 127.0.0.1:4318
       └─ otelcol-contrib
            ├─ logs    → file exporter → otel-logs.jsonl     ← 分析の主軸
            └─ metrics → file exporter → otel-metrics.jsonl  ← 産出量指標
                 └─（指標確定後に Prometheus + Grafana を追加）

  └─ OTEL_LOG_RAW_API_BODIES=file:<dir>（Collector を経由せず直接ディスク出力）
       └─ 生データ（Messages API の request/response JSON 全体）+ index.jsonl
```

### 3.1 なぜこの構成か
- **DuckDB を主軸にする理由**: 探索段階では「何を見るべき指標か」がまだ確定していない。Grafana のダッシュボード定義は試行錯誤のコストが高く、この段階では足枷になる。DuckDB なら `read_json_auto()` で JSONL を直接クエリでき、`GROUP BY` の書き換えで即座に切り口を変えられる。また DuckDB 側に保持期限の概念がないため、1ヶ月以上の蓄積も自然に扱える。
- **JSONL をアーカイブ実体にする理由**: DuckDB に取り込まなくても `read_json_auto('/path/otel-logs*.jsonl')` で直接クエリできる。ローテーション済みの圧縮ファイルもそのまま読める。保存とクエリを分離しておく。
- **Prometheus を後段に置く理由**: トークン分析に Prometheus は不要（§4.1 参照）。ただし後述の「産出量メトリクス」はメトリクスにしか存在せず、コスト対効果の分母として必要になるため、指標が固まった段階で追加する。

### 3.2 段階
1. **探索期**: otelcol-contrib + file exporter（logs/metrics 両方）+ DuckDB。ストアは JSONL 1系統で済む。temporality は既定の `delta` のまま（増分がそのまま取れて差分集計しやすい）。
2. **定常期**: 指標確定後に Prometheus + Grafana を追加。この時点で `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` に切り替える。

---

## 4. データモデル：どの値がどこにあるか

### 4.1 【最重要】メトリクスとイベントの役割分担

| 取りたいもの | ある場所 | 理由 |
|---|---|---|
| リクエスト単位のトークン内訳 | **イベント** `claude_code.api_request` | メトリクスは集計済みカウンタ |
| `prompt.id`（作業単位の紐付け） | **イベントのみ** | メトリクスには意図的に含まれない（プロンプトごとに一意でカーディナリティが無限増殖するため） |
| 生のサブエージェント名 | **イベント** の `query_source` | メトリクスの `agent.name` は墨消し対象（ただし §4.4 参照） |
| 産出量（LOC / commit / PR / active time） | **メトリクスのみ** | イベントからは復元できない |

**結論**: トークン・コスト分析の主データはイベント側。Prometheus はトークンのためではなく、コスト対効果の「分母」を取るために置く。

### 4.2 要件マッピング（すべて `claude_code.api_request` イベント1本で揃う）

| 要件 | 属性 |
|---|---|
| R1 モデル | `model` |
| R1 バージョン | `app.version` ※既定 false。`OTEL_METRICS_INCLUDE_VERSION=true` が必要 |
| effort | `effort`（`low` / `medium` / `high` / `xhigh` / `max`。モデルが effort 非対応の場合は不在） |
| R2 main/subagent | `query_source`、`agent.name` |
| R2 Skill / workflow 内 | `skill.name`、`workflow.run_id`、`workflow.name` |
| R3 送信 | `input_tokens`、`cache_read_tokens`、`cache_creation_tokens` |
| R3 受信 | `output_tokens` |
| コスト | `cost_usd`、`cost_usd_micros`（整数、100万分の1ドル単位） |
| 付随 | `duration_ms`、`speed`（`fast`/`normal`）、`request_id`、`client_request_id` |

### 4.3 紐付けの3階層

| 粒度 | キー | 所在 |
|---|---|---|
| セッション | `session.id` | メトリクス・イベント両方 |
| 作業（1プロンプト） | `prompt.id` | イベントのみ |
| 実行主体 | `query_source` / `skill.name` / `workflow.run_id` | イベント・スパン |

- `prompt.id` は UUID v4。1回のユーザープロンプトから派生した全イベントを束ねる。「この指示のために合計何トークン使ったか」はこれで確定する。
- `OTEL_LOG_USER_PROMPTS=1` を併用すると `claude_code.user_prompt` イベントにプロンプト本文が載る。`prompt.id` で結合すれば「どんな作業だったか」を人間が読める形で復元できる。**ボトルネック分析の実質的な主キーはここ。**
- `workflow.run_id` でイベントを絞ると、その run の API リクエストとツール実行が再構成できる。**workflow スクリプトが起動したエージェント、およびそれらがさらに起動したエージェント（skill 呼び出しを含む）まで再帰的にカバーされる**とドキュメントに明記がある。「この workflow 全体でいくら使ったか」は単純な GROUP BY で出る。

### 4.4 墨消し（redaction）規則 — v2.1.283 時点

`OTEL_LOG_TOOL_DETAILS=1` を設定すると、以下がすべて逐語で出力される。**設定しない場合の既定値と併記する。**

| 属性 | 既定（フラグなし） | `OTEL_LOG_TOOL_DETAILS=1` |
|---|---|---|
| `agent.name` | ユーザー定義エージェント名 → `"custom"` | 逐語 |
| `skill.name` | third-party プラグインの skill → `"third-party"` | 逐語 |
| `plugin.name` | third-party プラグイン → `"third-party"` | 逐語 |
| `mcp_server.name` / `mcp_tool.name` | ユーザー設定サーバ → `"custom"` | 逐語 |
| `workflow.name` | ユーザー作成 workflow → `"custom"` | 逐語 |
| `command_name`（user_prompt） | custom/plugin/MCP → `custom` / `mcp` | 逐語 |

**注意**: 組み込みエージェント名、bundled / user-defined / 公式マーケットプレイス由来の skill 名は、フラグなしでも既定で逐語。

**設計上の含意**: `OTEL_LOG_TOOL_DETAILS=1` を設定すればメトリクス側だけでもカスタムサブエージェント別のトークン集計が可能。ただしカーディナリティが増えるため、Prometheus 段階では注意。一方 **イベントの `query_source` は無ゲート**で `"repl_main_thread"` / `"compact"` / サブエージェント名がそのまま入るため、イベント主軸ならフラグなしでも識別できる。

### 4.5 `/compact` vs `/clear` の分析材料
- `claude_code.compaction` イベント（**属性は §8 の未検証事項**）
- 圧縮処理そのものの API 呼び出しは `query_source: "compact"` で `api_request` に現れる → **「圧縮で削れたコンテキスト量」と「圧縮に払ったトークン代」を突き合わせられる**
- `/clear` 側は専用イベントを出さないが、`session.id` が切り替わるので境界は取れる

### 4.6 ボトルネック特定に効く付加指標
- `claude_code.tool_result` イベントの `tool_result_size_bytes` / `tool_input_size_bytes`
- `claude_code.tool` スパンの `result_tokens`（ツール結果の概算トークンサイズ）

「どのツール出力がコンテキストを膨らませ、後続リクエストの `input_tokens` を押し上げているか」が分かる。`/compact` の要否判断に直結する。

### 4.7 メトリクス一覧（8種）
| メトリクス名 | 説明 | 単位 |
|---|---|---|
| `claude_code.session.count` | 開始セッション数 | none |
| `claude_code.lines_of_code.count` | 変更行数（`type`: added/removed、`model` 付き） | none |
| `claude_code.pull_request.count` | PR 作成数 | none |
| `claude_code.commit.count` | commit 作成数 | none |
| `claude_code.cost.usage` | コスト | USD |
| `claude_code.token.usage` | トークン数（`type`: input/output/cacheRead/cacheCreation） | tokens |
| `claude_code.code_edit_tool.decision` | 編集系ツールの許可判断数 | none |
| `claude_code.active_time.total` | アクティブ時間（`type`: user/cli） | s |

うち `lines_of_code.count` / `commit.count` / `pull_request.count` / `active_time.total` が §1.2 の問い2に対する「分母」。

---

## 5. 設定

### 5.1 環境変数（推奨セット）

```bash
# --- 基本 ---
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:4318

# --- 要件充足に必須 ---
export OTEL_METRICS_INCLUDE_VERSION=true        # app.version（既定 false）
export OTEL_METRICS_INCLUDE_REPOSITORY=true     # vcs.*（既定 false、v2.1.269+）
export OTEL_METRICS_INCLUDE_ENTRYPOINT=true     # app.entrypoint（既定 false、任意）

# --- 分析解像度を上げる（プライバシー影響あり、§7 参照）---
export OTEL_LOG_USER_PROMPTS=1                  # プロンプト本文
export OTEL_LOG_TOOL_DETAILS=1                  # 墨消し解除（§4.4）

# --- 生データ（R5）---
export OTEL_LOG_RAW_API_BODIES=file:/path/to/raw-bodies

# --- 探索期の設定 ---
# temporality は既定の delta のまま。Prometheus 導入時に cumulative へ。
```

**`OTEL_LOG_ASSISTANT_RESPONSES` の挙動に注意**: 未設定の場合、`OTEL_LOG_USER_PROMPTS` の値にフォールバックする。プロンプトだけ記録しレスポンスは伏せたい場合は、明示的に `OTEL_LOG_ASSISTANT_RESPONSES=0` を設定すること。

### 5.2 リポジトリ属性（v2.1.269+）

`OTEL_METRICS_INCLUDE_REPOSITORY=true` で以下がメトリクス・イベント双方に付与される。

| 属性 | 値の例 |
|---|---|
| `vcs.repository.url.full` | `https://github.com/example-org/example-repo`（`.git` なし） |
| `vcs.owner.name` | `example-org`（リモートパスが単一セグメントの場合は省略） |
| `vcs.repository.name` | `example-repo` |
| `vcs.provider.name` | `github` / `gitlab` / `bitbucket` / `gitea`（認識できない場合は省略） |

- origin remote から**セッションごとに1回**導出される
- 同一リポジトリの HTTPS リモートと SSH リモートは同一値になる
- 値は小文字化され、認証情報・クエリ文字列・フラグメントは含まれない
- origin remote がない場合、リモートが URL 形状でない場合、囲むリポジトリがホームディレクトリだけの場合は省略される
- `OTEL_RESOURCE_ATTRIBUTES` で `vcs.*` キーを宣言すると導出値を上書きする（`vcs.repository.url.full` を宣言した場合、Claude Code はリモートを読まず宣言されたキーのみを報告する）

**これにより、`OTEL_RESOURCE_ATTRIBUTES` にリポジトリ名を手で詰める旧来の回避策は不要。**

### 5.3 Collector 設定（探索期）

```yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 127.0.0.1:4318

exporters:
  file/metrics:
    path: /path/to/otel-metrics.jsonl
  file/logs:
    path: /path/to/otel-logs.jsonl

service:
  pipelines:
    metrics:
      receivers: [otlp]
      exporters: [file/metrics]
    logs:
      receivers: [otlp]
      exporters: [file/logs]
```

**metrics と logs は必ず別ファイルに分ける。** スキーマが異なるため、混在すると DuckDB で読む際に扱いづらい。

### 5.4 ローテーション
1ヶ月分を無停止で蓄積するため、Collector の `rotation` 設定か外部の logrotate を**最初に**入れること。後から切り出すのは面倒になる。

### 5.5 動作確認
- メトリクス到達確認: `claude_code.session.count`（セッション開始時に必ず出る）
- ログのみの確認: `claude_code.user_prompt`
- 何も届かない場合: `claude --debug-file <path>` で起動し、書き出されたログを確認する。自分の設定に起因するエラーは `[3P telemetry]` プレフィックス。`[Anthropic telemetry]` は Anthropic 側の別系統の運用テレメトリであり、こちらの設定の問題を示すものではない。

---

## 6. リスク・落とし穴（実装前に必読）

### R-1 【重大】`event.sequence` はソートキーに使えない
v2.1.283 時点の仕様:
- 0始まりで、**Claude Code プロセスごと**にカウントされる（セッションごとではない）
- `/clear` を跨いでもカウントが続く（`session.id` は変わるのに）
- fork なしで resume すると、**同一セッション内で後のイベントが小さい値を持つ、または値が重複する**

**対処**: `event.timestamp` でソートし、`event.sequence` は同一タイムスタンプ内の順序付けにのみ使う。`interaction.sequence`（interaction スパン）も同じくプロセス単位。

### R-2 【重大】プロジェクト設定では OTel を有効化できない
リポジトリの `.claude/settings.json` および `.claude/settings.local.json` にある OTel エクスポータ変数は**無視される**。シェル、`~/.claude/settings.json`、または managed settings に置くこと。
- 例外: リポジトリ側から `OTEL_LOGS_EXPORTER=none` 等で**シグナルを無効化することだけ**は可能。

### R-3 delta temporality と時系列 DB の相性
Claude Code のメトリクス temporality は既定 `delta`。
- Prometheus に直接入れる場合、`--web.enable-otlp-receiver` に加えて `--feature-flag=otlp-deltatocumulative`、または `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative` の設定が必要。
- **VictoriaMetrics は delta を無言で捨てる**。エラーも警告も出ずデータだけ消えるため、原因特定が困難になる。
- Prometheus の保持期間は既定15日。1ヶ月要件を満たすには `--storage.tsdb.retention.time=31d` 以上が必要。
- VictoriaMetrics を使う場合、PromQL ダッシュボードとの互換のため `opentelemetry.usePrometheusNaming` フラグが必要（`claude_code.token.usage` → `claude_code_token_usage_tokens_total`）。

### R-4 input と cacheRead の単純合算は過大評価
`type` の4値（`input` / `output` / `cacheRead` / `cacheCreation`）は課金構造が異なる。「送信トークン」として単純合算すると実態を過大評価する。4種を別集計すること。

### R-5 コストは概算値
`claude_code.cost.usage` および `cost_usd` は概算。正式な請求データはプロバイダ（Claude Console / Amazon Bedrock / Google Cloud）を参照すること。**トークン数自体は API 由来なので正確。**

### R-6 モデル別のコミット数は直接取れない
`commit.count` に `model` 属性はない。`session.id` でトークン/コストメトリクスと結合した近似になる。その際、**トークン側を `query_source = "main"` で絞らないと**、サブエージェントや補助リクエストが使っていないモデルにセッションのコミットを帰属させてしまう。

### R-7 `mcp_server.name` の意味が v2.1.222 で変わった
以前は MCP ツール呼び出し後の**全**リクエストに付いていたが、現在は**ツール結果を消費したリクエストのみ**に付く。旧バージョンからのデータと連結する場合、集計値に段差が出る（ドキュメントに明記あり）。

### R-8 実行中に任意の「作業ラベル」を注入する手段はない
`OTEL_RESOURCE_ATTRIBUTES` はプロセス起動時の環境変数。セッション途中で「今から作業Xです」とタグ付けすることはできない。

**回避策**（後者を推奨）:
1. 作業単位でセッションを分け、起動時にラベルを渡す
2. `prompt.id` + プロンプト本文から後付けで分類する（既存の運用を変えずに済む）

### R-9 `OTEL_RESOURCE_ATTRIBUTES` の書式制約
- **値に空白を含められない**（`org.name=My Company` は無効）
- クォートで囲んでもエスケープされず、引用符ごとリテラル値になる
- 許容文字は US-ASCII から制御文字・空白・二重引用符・カンマ・セミコロン・バックスラッシュを除いたもの
- 範囲外の文字はパーセントエンコードが必要（`John%27s%20Organization`）
- 各カスタムキーは全メトリクス系列のラベルになるため、高カーディナリティ値はストレージコストを押し上げる。リソースブロックのみに送りたい場合は `OTEL_METRICS_INCLUDE_RESOURCE_ATTRIBUTES=false`

### R-10 トランスクリプト（JSONL）との join はバージョン依存
`~/.claude/projects/*/*.jsonl` のエントリ形式は Claude Code の内部仕様であり、リリース間で変わる。`message.uuid` / `request_id` / `tool_use_id` での join は「バージョン固有の実装」として扱い、安定契約とみなさないこと。恒久集計の主軸にはせず、OTel の補完に留める。

### R-11 Collector 経由のトレースを使う場合の追加注意
`claude_code.llm_request` スパンの `query_source` は `ENABLE_BETA_TRACING_DETAILED` でゲートされる。無ゲートの `query_source_safe` は用意されているが、ユーザー定義エージェントが `agent.custom` に丸められる（v2.1.268+）。
- スパンで生のエージェント名が必要なら detailed beta tracing（`ENABLE_BETA_TRACING_DETAILED=1` + `BETA_TRACING_ENDPOINT`、対話 CLI では組織の allowlist が必要）が要る
- **イベント側の `query_source` は無ゲート**なので、イベント主軸のほうが安全
- detailed beta tracing を有効にすると、logs と traces の出力先が `BETA_TRACING_ENDPOINT` に切り替わる点にも注意

### R-12 `otelHeadersHelper` の失敗はエクスポート全停止
ヘッダ生成スクリプトが失敗すると、そのセッションのテレメトリは以後一切バックエンドに届かない。ローカル構成で認証が不要なら、そもそも設定しないのが安全。

---

## 7. プライバシー・運用上の留意事項

### 7.1 内容ログ系フラグの影響範囲
| フラグ | 記録されるもの |
|---|---|
| `OTEL_LOG_USER_PROMPTS=1` | ユーザープロンプト本文 |
| `OTEL_LOG_ASSISTANT_RESPONSES=1` | アシスタント応答テキスト（thinking / tool_use ブロックは除外） |
| `OTEL_LOG_TOOL_DETAILS=1` | Bash コマンド、MCP サーバ/ツール名、skill 名、workflow 名、ツール入力 |
| `OTEL_LOG_TOOL_CONTENT=1` | ツール入出力の内容（トレース必須） |
| `OTEL_LOG_RAW_API_BODIES` | **会話履歴全体**を含む Messages API の request/response JSON |

`OTEL_LOG_RAW_API_BODIES` を有効にすることは、上3つが露出させるものすべてへの同意を含意する（ドキュメント明記）。ローカル完結構成であっても、ディスク上のファイル権限とバックアップ対象からの除外は設計時に決めておくこと。

### 7.2 生データの実体（R5 の主手段）
`OTEL_LOG_RAW_API_BODIES=file:<dir>` は Collector を経由せず Claude Code が直接ディスクに書く。
- `<dir>/<uuid>.request.json` — 切り詰めなしのリクエストボディ
- `<dir>/<request_id>.response.json` — 切り詰めなしのレスポンスボディ
- `<dir>/index.jsonl` — 成功レスポンスごとに1行（v2.1.274+）

**`index.jsonl` の各行のフィールド**: `timestamp`, `session_id`, `query_source`, `model`, `request_id`, `message_id`, `message_uuid`, `request_file`, `response_file`

テレメトリバックエンドに問い合わせることなく、トランスクリプトのメッセージから生ボディを引ける。DuckDB で直接読めるため、R5 に対してはこれが最短経路。

加えて `api_request_body` / `api_response_body` イベントには `request_body_id` があり、リトライを含めて**どの試行のリクエストがどのレスポンスを生んだか**をペアリングできる（v2.1.274+）。

**注意**: 直前のアシスタントターンの extended thinking 内容は request body 側で redact される。response body 側でも extended thinking 内容は redact される。

### 7.3 コンテンツ切り詰め
`CLAUDE_CODE_OTEL_CONTENT_MAX_LENGTH` の既定は 61440（60KB、UTF-16 コードユニット）。バックエンドの属性値上限64KBに合わせた値。ローカルのファイル出力なら引き上げてよいが、`OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT` 等の SDK 側制限がより小さい場合はそちらに合わせて切り詰められる。

---

## 8. 未検証事項（実装前に要確認）

ドキュメントページが長大で、「Tool decision event」以降の末尾部分を取得できなかった。以下は**このセッションでは未検証**であり、憶測で埋めていない。

### 8.1 要確認：`claude_code.compaction` イベントの現在の属性
§1.2 の問い1（`/compact` vs `/clear`）の中核データ。以前のバージョンでは以下の属性が確認されていたが、v2.1.283 での維持は未確認:
- `trigger`（`auto` / `manual`）
- `pre_tokens`（圧縮前の概算トークン数）
- `post_tokens`（圧縮後の概算トークン数）
- `duration_ms`
- `success`、`error`
- `precompute_reuse`（`manual` 時のみ。`hit` / `miss_custom_instructions` / `miss_hook` / `miss_not_ready`）

### 8.2 要確認：末尾のその他イベント群
`hook_registered` / `hook_execution_start` / `hook_execution_complete` / `hook_plugin_metrics` / `plugin_installed` / `plugin_loaded` / `skill_activated` / `at_mention` / `api_retries_exhausted` / `permission_mode_changed` / `auth` / `mcp_server_connection` / `internal_error` / `feedback_survey` の現在の属性。

### 8.3 判明している新規イベント（間接確認）
設定変数表からの参照により、`managed_settings_resolved` イベントの存在は確認済み。`OTEL_LOG_MANAGED_SETTINGS=1` で redact 済み managed settings と redact 前の SHA-256 ダイジェストが付加される（v2.1.274+）。プロジェクト設定やローカル設定に書いても有効にならない。

### 8.4 【推奨】ドキュメントを待たずに確定させる手順
v2.1.283 が手元にあるため、Collector を立てる前に console exporter で実物を確認するのが最も確実かつ高速。

```bash
CLAUDE_CODE_ENABLE_TELEMETRY=1 OTEL_LOGS_EXPORTER=console claude
```

この状態で確認すべき項目:
1. `/compact` を実行 → `claude_code.compaction` の実際の属性名を標準出力から採取
2. カスタムサブエージェントを起動 → `query_source` に実際に何が入るか
3. `OTEL_LOG_TOOL_DETAILS=1` を追加 → `agent.name` が本当に逐語になるか
4. Skill / workflow を実行 → `skill.name` / `workflow.run_id` / `workflow.name` の実値
5. 出現するイベント名の全量（§8.2 の確定）

**この検証を先に済ませてからスキーマとクエリを設計すること。** 構成を固めてから属性名の相違に気づくと手戻りが大きい。

---

## 9. デプロイ形態による差分（該当する場合のみ）

Anthropic API 直結ではなく **Amazon Bedrock / Google Cloud / Microsoft Foundry 経由**、または直接 API キーで実行している場合、以下が変わる。該当しなければ本章は無視してよい。

### 9.1 識別属性が埋まらない
セッションに Claude アカウントが存在しないため、**`user.id` と `session.id` しか埋まらない**。`organization.id`、`user.email`、`user.account_uuid`、`user.account_id` は不在。

**対処**: `OTEL_RESOURCE_ATTRIBUTES` で利用者識別子を自分で付与する。

```bash
export OTEL_RESOURCE_ATTRIBUTES="enduser.id=jdoe@example.com"
```

単独ユーザーでの分析なら実害は小さいが、将来チーム展開する場合は最初から入れておくほうがよい。

### 9.2 `client_request_id` が出ない
サードパーティプロバイダのバックエンドでは `client_request_id` は**不在**。リクエストとレスポンスのペアリングにはこれを使わず、`request_id` を使うこと。

### 9.3 `request_id` の取得元（Bedrock）
`request-id` ヘッダを返さないレスポンス（Bedrock 等）では、`x-amzn-requestid` ヘッダから値が取られる（v2.1.282+）。v2.1.283 なので問題なく機能する。

### 9.4 `internal_error` イベントが出ない
Amazon Bedrock / Google Cloud's Agent Platform / Microsoft Foundry に対して実行している場合、`claude_code.internal_error` イベントは emit されない。エラー監視の設計時に留意。

### 9.5 トレースコンテキストの伝播
`traceparent` ヘッダはサードパーティプロバイダには**送信されない**。`ANTHROPIC_BASE_URL` がカスタムプロキシを指す場合に伝播させたいときは `CLAUDE_CODE_PROPAGATE_TRACEPARENT=1`。

### 9.6 MCP を使用しない環境の場合
`mcp_server.name` / `mcp_tool.name` / `mcp_server_scope` / `mcp_server_connection` 関連は無視してよい。§4.4 の墨消し表からも該当行を落とせる。

---

## 10. 最初の一歩（実装順）

1. **§8.4 の console exporter 検証を実施**し、属性名の実物を採取する
2. 採取結果をもとに DuckDB のクエリ雛形を書く（`model` × `effort` × `query_source` の GROUP BY から）
3. otelcol-contrib を導入し、file exporter で JSONL 出力（§5.3）
4. ローテーションを設定（§5.4）
5. 1〜2週間データを貯め、`query_source` の値の分布を確認する — ここが最初の分析材料になる
6. 見るべき指標が固まったら Prometheus + Grafana を追加（temporality を `cumulative` に切り替え）

---

## 付録: 参照

- Claude Code Monitoring（一次情報源）: https://code.claude.com/docs/en/monitoring-usage
- Prometheus OpenTelemetry ガイド: https://prometheus.io/docs/guides/opentelemetry/
