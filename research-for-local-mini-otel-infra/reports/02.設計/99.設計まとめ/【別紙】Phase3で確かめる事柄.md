# 【別紙】Phase 3 で確かめる事柄（run ごとの一覧）

| 項目 | 内容 |
|---|---|
| 位置付け | [統合の設計書](設計書.md)の【別紙】。設計書 5 本の「未確認・【推定】に依った決めごと」の表の行と、本文で Phase 3 で確かめるとした事柄を、run（何をどう動かすか）ごとに並べた索引である。決めごと・依った事柄・崩れたときの直しの正本は元の行にあり、本書には写さない |
| 状態 | v0.5（2026-10-30）。統合の設計書 v0.7 と組 A v0.6・組 B v0.8・組 C v0.7・組 D v0.7 の行番号による |
| 想定読者 | Phase 3 の担当（PoC の計画を立て、PoC 報告書で確かめた事柄の抜けを数える）、作業指示者（Phase 3 で何を確かめるかを見る）。どちらも本活動の文脈を持つ前提である |
| 前提 | 元の表は、[統合 §8](設計書.md#sec-8)、[組 A §9](../01.全体構成/設計書.md#sec-9)、[組 B §7](../02.データモデルと集計/設計書.md#sec-7)、[組 C §5](../03.作業分類タグ/設計書.md#sec-5)、[組 D §6](../04.有効化とデータ保全/設計書.md#sec-6) である。Phase 1 から引き継いだ確認項目（判定の目安・測り方・標本数）の正本は [V-ID 別紙 §2](../../01.基礎調査/99.基礎調査まとめ/【別紙】V-ID別状況とPhase3実測項目.md#sec-2) の本環境の表で、本書は同じ事柄の行の名前を「見るもの」の列に書くだけにする |

**読み方**: [§0](#sec-0) で run を選び、その節の表を上から読む。「元の行」は元の表の番号（例「組 D §6 の 11」）か、本文の節である。「見るもの」は、観測の置き場所（取込の記録の項目、S1 の表、受信サーバの動作の記録（`run\receiver\`）の項目、debug log）である。崩れたときの直しは元の行にある。PoC 報告書は、本書の行ごとに、確かめた・未観測で閉じた・確かめられなかったのどれかを書く。全体で約 13〜18 分（約 10,800 字。600〜800 字/分）。

<a id="sec-0"></a>
## 0. run の一覧

| 節 | run | 中身 |
|---|---|---|
| [1](#sec-1) | 実装 | PoC のコードを書き、DuckDB を探索に使えるようにする（受信サーバを作ったときの試験と、計測用のセッションから送らせる要求を含む） |
| [2](#sec-2) | 版の再確認 | Phase 3 の着手前の版の再確認の計測。計測用のセッションの起動の形に切り替えた最初の計測で、前の起動の仕方の run と並べる（[組 D §1.4](../04.有効化とデータ保全/設計書.md#sec-1-4)） |
| [3](#sec-3) | 設定の前の確かめ | ユーザ settings を変える前に、送り先を受信していない番号にした計測用のセッションで、受信サーバが止まっているときの cc を見る（[組 D §1.7](../04.有効化とデータ保全/設計書.md#sec-1-7) の順序の 1） |
| [4](#sec-4) | 取込の試作 | 既存の transcript（受信を始めた後は S2 も）を読む取込の試作。日常の初回の取込を含む |
| [5](#sec-5) | 日常 | 受信サーバを手で起動し、ユーザ settings の `env`（基準の後に `hooks`）で動く日常のセッション |
| [6](#sec-6) | 比較実験 | 計測用のセッションの比較実験（`-p` と対話。L1 あり・なし、command hook と Mod） |
| [7](#sec-7) | ランチャ | ランチャで起動したセッション（T1 と T2 を比べる） |
| [8](#sec-8) | Mod | L1 の Mod 版と、`plan_usage_snapshot` を記録する別の Mod |
| [9](#sec-9) | PowerShell 版 | PowerShell で L1 を作る場合だけ |

[§10](#sec-10) は、元の表の行のうち Phase 3 で確かめない行である。

動作の記録の毎時の行（`kind` が `hourly`）の数値を使う run は、見たい区間の正時の行が書かれた後に止める（lmo-ctl の `stop` で止めた区間の行は書かれない。[組 A §2.9](../01.全体構成/設計書.md#sec-2-9)）。

<a id="sec-1"></a>
## 1. 実装

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 A §9 の 4 | 受信を npm パッケージに依らず書けるか | 実装で要った npm パッケージ（[組 A §3.3](../01.全体構成/設計書.md#sec-3-3) の依存の一覧） |
| 組 A §9 の 5 | DuckDB の拡張（JSON は CLI に入り、SQLite は初回に取得する） | DuckDB CLI で S2 と S1 を読めるか。V-ID 別紙 §2 の「`node:sqlite` の動作」の行 |
| 組 D §2.4 | 取込の間隔の設定を、環境変数・設定のファイル・既定の順に読み、範囲の外と整数でない値を既定に戻す | 範囲の外の値で起動した受信サーバの動作の記録の `start` の行（`ingest_interval_min`・`ingest_interval_source`・`ingest_interval_rejected`・`ingest_interval_reason`。[組 A §2.9](../01.全体構成/設計書.md#sec-2-9)）と、lmo-ctl の `start` の表示 |
| 統合 §2.1 | lmo-ctl の `stop` の止め方（強制終了のままか、止まる要求を送る形か）を決める | cc が送っている最中に `stop` で止めたとき、止める直前の要求が S2 に入ったか、後で起動した受信サーバに送り直されたか（§3 の組 D §6 の 3 と同じ debug log の行）。止めた区間の毎時の行が欠けることが、毎時の行の数値を使う run の妨げになるか |
| 組 D §6 の 15 | 受信サーバが、識別属性と本文を S2 に書く前に替え、ライブ表示に許可リストの外の項目を出さない。配り口と `/v1/*` の守り（`Host` の確かめ、CORS のヘッダを付けないこと、購読の上限、送りの溜まりで切ること）が働く（作った要求の試験）。cc の要求は `/v1/*` の `Host` の確かめを通る（計測用のセッションの要求） | [組 D §2.3](../04.有効化とデータ保全/設計書.md#sec-2-3) の「確かめ方」の、受信サーバを作ったときの試験の結果。見るのは、S2 の行の識別属性と本文と `prompt_length`、動作の記録の `hourly` の行の `id_attr_dropped` と `key_unreadable` の行、ライブの購読で配られた項目。配り口の守りの 4 つ（別の `Host` の購読の 403、`Origin` のヘッダを付けた購読の応答に `Access-Control-Allow-Origin` が無いこと、5 つ目の購読の 503、1 MB を超えた購読を切ること）と、その `hourly` の `live_bad_host`・`live_full`・`live_dropped`。`Origin` のヘッダを付けるのは、要求の origin を写して返す誤りも拾うためである。別の `Host` で `/v1/*` に送った要求の 403 と、S2 に行が無いことと、`hourly` の `bad_host`。計測用のセッションから送らせた cc の要求の S2 の行と、`bad_host` が 0 であること |
| 組 B §7 の 20 | cc の `event.timestamp` が時差か `Z` の付いた ISO 8601 で届き、ライブの `event_ts` が `null` にならない | 上の行の、計測用のセッションから送らせた要求を、試しの購読で受けたときに配られた行の `event_ts`（`null` の数） |
| 組 A §4 | `LMO_OTLP_HOST` がループバックのアドレスでない値（名前を含む）なら、受信サーバが待ち受けを始めずに起動をやめる | ループバックの外のアドレスと名前をそれぞれ変数に入れて lmo-ctl の `start` を打ったときの、動作の記録の `host_not_loopback` の行（`host`）と、`kind` が `start` の行が無いこと。lmo-ctl の `start` の表示と終了コード（[統合 §2.1](設計書.md#sec-2-1) の起動できなかったときの表） |

<a id="sec-2"></a>
## 2. 版の再確認

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 D §6 の 1 | `--setting-sources` から `user` を外すと、ユーザ settings の `enabledPlugins` などが読まれない（cc 2.1.314 以降で確かめる。2.1.313 以前は、外したユーザ settings から auto mode の規則と保存した承認などが入りえた） | 前の起動の仕方の run と、属性集合・`plugin_loaded`・`hook_registered`・`effort` を並べる |
| 組 D §6 の 11 | 変数を有効にすれば、Claude Code が起こす対話のセッションも transcript を残す。Phase 1 の i3・i4 は入れ子の扱いによる | 変数を有効にした対話の計測用のセッション（正常に終えたものと、強制終了したもの）と、有効にしないものの、transcript のファイルの有無 |
| 組 D §6 の 13 | 起こすプロセスの環境変数の `LMO_DATA_DIR` を、cc が起こす hook も受け継ぐ | L1 の hook を足した計測用のセッションの、計測のデータの根と日常のデータの根の `labels\l1\` にあるそのセッションのファイル（この run に L1 の条件が無ければ、[§6](#sec-6) の比較実験で見る） |

<a id="sec-3"></a>
## 3. 設定の前の確かめ

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 D §6 の 2 | 受信サーバが止まっていても cc の操作は止まらない | cc の操作と終了の様子。V-ID 別紙 §2 の「受信サーバ停止中の cc の挙動」の行 |
| 組 D §6 の 3・組 A §9 の 2 | cc が接続の失敗や 503 の後に送り直すか | debug log の `[3P telemetry]` の行。送り直すなら、後で起動した受信サーバに同じ記録が届くか |

<a id="sec-4"></a>
## 4. 取込の試作

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 統合 §8 の 3・組 A §9 の 9 | transcript に `prompt_id` に当たるキーがあるか（縮退運用で作業分類を結べるか） | `schema_observation` の信号 `transcript` の、`user` レコードのキーの集合 |
| 統合 §8 の 4 | S2 を長く残す利点が小さい（J-35 の推奨の前提） | 取込の記録の `trigger` が `rebuild`（作り直し。[組 A §2.8](../01.全体構成/設計書.md#sec-2-8)）の回の数・所要（`started_at`・`ended_at`）と、作り直した理由、S1 のファイルを戻した回数（Phase 6 まで続けて数える） |
| 組 A §9 の 12 | 1 回の取込を 1 つのトランザクションにしても、初回の取込でメモリと WAL のファイルの大きさに困らない。ロックを待つ上限を置くかの材料 | 日常の初回の取込とふだんの取込の、取込の記録の `started_at`・`ended_at`、WAL のファイルの大きさの最大、lmo-ingest のメモリの最大 |
| 組 A §9 の 13 | 本活動の間の S2 の全体を読む作り直しを 1 つのトランザクションにしても、メモリと WAL のファイルの大きさに困らない | Phase 3 の終わりに、Phase 3 の間に溜まった S2 で打つ作り直しの、取込の記録（`trigger` が `rebuild` の回）の `started_at`・`ended_at` と、WAL のファイルの大きさの最大（Phase 6 までの量に延ばす） |
| 組 B §7 の 13 | `stop_reason` の null で、未確定の usage を見分けられる | ランチャのセッションの `transcript_usage` の、`final` の行の思考トークンと経路 (ii) の値（`raw_body_usage`）の一致と、`thinking_status` ごとの件数 |
| 組 B §7 の 16 | OTel の記録の無いセッションを transcript の usage だけで数える（`is_sidechain` の分け方を含む） | `usage_record` の `transcript_only` の行と、取込の記録の `otel_gaps`。OTel と transcript の両方があるセッションの、`is_sidechain` から引いた区分と `query_source_class`、トークン 4 種の合計 |
| 組 B §7 の 17 | 2.1.310 以前の `-p`・Agent SDK の transcript でも、`request_id` ごとの最後の行が確定値で、取り消された message の行が無い | 過去の `-p`・SDK の transcript の、`parentUuid` が後ろの行を指す行（順の崩れ）の数と、同じ `request_id` の最後の行の `stop_reason` |
| 組 B §7 の 21 | 2.1.311 以前の、端末で resume を 2 回以上したセッションの transcript に、resume の後の最初の応答の行の欠けがあるか | resume を 2 回以上した過去のセッションの transcript で、resume の後の最初の `user` の行に応える `assistant` の行があるか（OTel の記録もあるセッションでは、OTel にあって transcript に無い要求の数も） |
| 組 B §1.9 | 2.1.300 以降の `api_request` に、TTL 別の内訳が 2 つとも 0 なのに `cache_creation_tokens` が正の行があるか（あれば内訳の無い行として計算する） | 受信を始めた後の `usage_record` のうち、`cc_version_num` が 2.1.300 以降で、2 つの内訳が 0 で `cache_creation_tokens` が正の行の数 |
| 組 D §6 の 5 | transcript の usage の取込は、規則の誤りの余地が小さい | 取込の記録の `transcript` の行数と読めない行の数、取り込んだ usage と OTel の値の差 |
| 組 D §6 の 6 | 更新から 30 分で、書きかけの末尾と壊れた行を分けられる | 取込の記録の `transcript` の、書いている途中として次に回したファイルの数と、`unreadable` |
| 組 D §6 の 7 | 種類 2 の行に usage が入らない | `unreadable` の種類 2 の行（数え方は [1-9 §5](../../01.基礎調査/09.cc2.1.304差分の確認/調査報告書.md#sec-5)） |
| 組 D §6 の 9 | transcript に識別属性が入らない | 取込が読む値（usage と鍵）に、識別属性に当たる値があるか |
| 組 D §6 の 12 | 記録より前の計測（Phase 1・Phase 2 の probe）の transcript が、日常の初回の取込に入る | probe の作業フォルダの `projects` の下の transcript の数 |
| 組 D §2.4 | 読めない transcript の行を数え、飛ばして取込を止めない | 取込の記録の `unreadable` と、取込の `status` |
| 組 D §2.4 | 未知の記録型（2.1.311 の `tools-used` など）を読まず、型ごとの行数を書く | 取込の記録の `transcript` の未知の型ごとの行数（長いセッションでの `tools-used` の件数） |

<a id="sec-5"></a>
## 5. 日常

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 統合 §8 の 1 | lmo-ctl で起こした受信サーバが、起こしたシェルが終わった後も動き、`stop` の後にプロセス番号のファイルが残らない。`stop` が強制終了になる | `start` と `stop` を繰り返し、Claude Code のツールから起こした後にシェルを閉じる。`run\lmo-receiver.pid` と、`stop` の後の動作の記録（`stop` の行が無いこと。[組 A §2.9](../01.全体構成/設計書.md#sec-2-9)） |
| 統合 §8 の 5・組 A §9 の 7 | 1 回の送信が 64 MB に届かず、16 MB を超える行は少ない | 動作の記録（`run\receiver\`）の `hourly` の行の `signals.*.body_bytes_max` と `signals.*.over_16mb_lines` |
| 統合 §8 の 6 | セッションの途中で止まった分の欠けの大きさ | 取込の記録の `otel_gaps` と、途中で止めたセッションの S2 と transcript の件数の差 |
| 統合 §8 の 7 | lmo-ctl の `start` が、10 秒の上限の内に起動を確かめる | 統合 §8 の 1 の run の `start` の所要（打ってから表示まで）と、上限を過ぎた回の数 |
| 組 A §9 の 1 | `127.0.0.1` で受ける | 動作の記録の `hourly` の行の `signals.*.requests` と `signals.*.ok`（日常のセッションの送信が届くか） |
| 組 A §9 の 3 | 追記中の当日の S2 を、別のプロセスの DuckDB で読める | V-ID 別紙 §2 の「書き込み中の JSONL を別プロセスの DuckDB で読めるか」の行 |
| 組 A §9 の 10 | 書き手の列の上限（件数 1,000、合計 128 MB）に、ふだんは当たらない | 動作の記録の `hourly` の行の `queue_len_max`・`queue_bytes_max` と、上限で断った件数 `signals.*.queue_full` |
| 組 A §9 の 11 | ライブの配り口の負荷（購読 1 つで、受信の 1 要求あたりの処理の増えが 1 ms に届かない） | 試しの購読のスクリプトで購読する run と、購読しない run の、動作の記録の `hourly` の行の `proc_ms_p50`・`proc_ms_max`（購読の数は `live_subscribers_max`） |
| 組 A §9 の 14 | 購読が上限（4）を超えず、送りの溜まり（1 MB）を超えるのは読み手が止まったときだけで、注釈の行（15 秒ごと）で購読の繋がりが保たれる | 同じ試しの購読の run の、`hourly` の行の `live_full`・`live_dropped`・`live_subscribers_max` と、購読のスクリプトの繋がりが切れた回数 |
| 組 D §6 の 14 | ふだんの取込の所要の最大が 30 秒に収まる（取込の間隔の下限 5 分の前提） | 取込の記録の `started_at`・`ended_at`（日常の初回の取込を除く回の所要の最大。`trigger` ごとにも分ける） |
| 組 B §7 の 2 | `query_source_map` の写し方 | 日常の 1 日分以上の、metrics の `query_source` の値ごとのトークン数と、`usage_record` の `query_source_class` ごとのトークン数、`unknown` の行の数 |
| 組 B §7 の 5 | アイドル時の compaction を空いた時間で見分ける | `compaction` の `compact_kind`（V-ID 別紙 §2 の「アイドル時の compaction」の行） |
| 組 B §1.10 | 2.1.314 以降、VS Code の telemetry の設定が off の拡張のセッションでも、アイドル時の compaction が動くか（docs と changelog のどちらが合うか） | VS Code の拡張のセッションの `compaction` の `trigger=auto` の行と `compact_kind`、そのときの VS Code の telemetry の設定（Phase 3 で VS Code を使うときだけ。使わなければ未観測で閉じる） |
| 組 B §2.1 | 1 回の compaction に compact の要求が 2 件になる頻度（2.1.311 の要約の再要求） | 同じセッションの `compaction` 1 件ごとの、`query_source=compact` の `usage_record` の数と、`compaction` の `duration_ms` |
| 組 B §2.6 | 2.1.311 以降の span の `model` に `[1m]` が付くか | `llm_span` の `query_source_safe=auto_mode` の `model` と `model_key`、`cost_status` が `unpriced_model` の件数 |
| 組 B §7 の 7 | `/clear` の前後を hook と時刻で結ぶ | 日常の 2 週間の、`session_start_record` の `source` が `clear` の行と `session_link`（結べなかった数と、結んだ組の `gap_sec`）。結んだ組から選んだ 5 組を作業指示者が見る |
| 組 B §7 の 8 | data residency と 1 回ごとの料金の当て方 | `api_request` の `inference_geo`、transcript の usage の `server_tool_use`、見なし費用の検算のずれ |
| 組 B §7 の 10・組 B §7 の 15 | 検算の合格の幅と、単価の未確認 5 件 | V-ID 別紙 §2 の「見なし費用の検算」の行（Opus 5.5 は要求が出たとき） |
| 組 B §7 の 11 | traces を含めれば `quota_check` 以外は漏れない | V-ID 別紙 §2 の「OTel の logs（`api_request`）と metrics に出ない API 呼び出しの件数」の行 |
| 組 B §7 の 12 | 同じ記録の重複が届く | 取込の記録の `s2` の、重複として除いた行の数 |
| 組 B §7 の 14 | tool のイベントの `request_id` が付かない呼び出しの範囲 | `tool_event` の `request_id` が NULL の行の、ツールの名前ごとの件数 |
| 組 C §5 の 3 | 自動開始のターンに `prompt_id` が付き、`prompt.id` と一致する（TG-09） | `l1_hook_record` と `user_prompt` の `prompt_id`。V-ID 別紙 §2 の「自動開始ターン」の行 |
| 組 C §5 の 4 | skill・slash command のターンの `prompt_id` が一致し、打ったままの行から名前が取れる | `l1_hook_record` の `cmd` と `user_prompt` の `command_name`。V-ID 別紙 §2 の「skill・カスタム slash command」の行 |
| 組 C §5 の 9 | 作業指示者のセッションで、貼り付けに印の行が付く | 貼り付けを含むプロンプトの `l1_hook_record` の `rule_id` と、L2 の区分 |
| 組 C §5 の 10 | 短い返事のプロンプトは直前の作業の続きである | `category` が `cont` のプロンプトの L2 の区分（V-ID 別紙 §2 の「タグ案 L2」の行） |
| 組 C §5 の 12 | 日常の構成で、command hook の待ち時間が J-12 の基準に収まる | `l1_hook_record` の `hook_ms` を実装手段と permission mode の組ごとに。V-ID 別紙 §2 の hook の行 |
| 組 C §5 の 14 | 同じセッションの hook が重なっても、1 行ずつ書かれる | 取込の記録の `labels` の `unparsable` と、`unreadable` の `source` が `labels` の行 |
| 組 D §6 の 10 | 系列数は、モデルと `effort` の組の数だけ掛けて増える | `metric_point` の系列の数と、集計の時間 |
| 組 D §6 の 15 | 日常の初回の受信で、識別属性が平文で S2 に入らず、L2 を有効にした本文が残る | その日の S2 のすべての行の識別属性 5 つの値と本文（組 D §2.3 の「確かめ方」の日常の初回） |
| 組 D §6 の 16 | ライブ表示の区分の値に、識別子を含む値が入るか（入っても、一覧と形の外の値は決めた値に替わる） | 本環境の区分の値を組 B §1.12 の一覧と形に当て、決めた値に替わった値の数 |
| 組 D §2.5 | 保存量の見積もり（PV-07） | 取込の記録の `store_bytes` を 1 日ごとに 2 週間 |

<a id="sec-6"></a>
## 6. 比較実験

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 A §9 の 8 | 書き手 1 つの列の非同期の追記で、2 セッション同時の受信の行が混ざらず欠けない（200 を返した要求がすべて S2 にある） | V-ID 別紙 §2 の「対話モードでの 2 セッション同時受信」の行と、動作の記録の `hourly` の行の `signals.*.ok` の合計と S2 の行の数 |
| 組 B §7 の 1 | `subagent_key` が一意である（入れ子・fork・span の `agent_id` の `acompact-` の形の値・対話モード） | S1 の `session_id` ごとの `agent_id` の重複の数 |
| 組 B §7 の 4 | `--resume` と compact の前後の `session.id` | `--resume` と compact の run の、前後の `session_id` |
| 組 B §7 の 18 | `quota_check` の量（トークン数か `max_tokens`）が debug log に出るか | debug log を取る計測用のセッションの `quota_check` の行の数と、その行のトークン数・`max_tokens` |
| 組 B §1.6 | 2.1.311 以降の対話で、`ultrathink` のターンの `effort` が `xhigh` になり、同じ `prompt_id` の中で effort が変わる。2.1.312 以降、動いている途中の `/effort` の後の要求の `effort` が当たっている level で、キューに入れたメッセージが同じ `prompt_id` に入るか | 対話の計測用のセッションで、`ultrathink` を打ったターン（途中で打つ場合を含む）と、動いている途中に `/effort` で level を選び直してメッセージをキューに入れたターンの、`api_request` の `effort` と `prompt_id`、サブエージェントの要求の `effort` |
| 組 C §5 の 5 | `performance.now()` の起点が process の起動である | debug log の hook ごとの行と `hook_ms` の差 |
| 組 C §5 の 6 | Esc で送り直したプロンプトの `prompt_id` が前と同じか | 対話で Esc の後に送り直したプロンプトの、`l1_hook_record` の行の数と `prompt_id`（[1-10 §5.3](../../01.基礎調査/10.cc2.1.310差分の確認/調査報告書.md#sec-5-3)） |
| 組 C §5 の 15 | `OTEL_LOG_USER_PROMPTS` を無効にしたセッションの `user_prompt` の本文が `<REDACTED>` の値になる | 変数を無効にした条件の計測用のセッションの、S2 の `user_prompt` の本文の値（その条件が無ければ未観測で閉じる） |

<a id="sec-7"></a>
## 7. ランチャ

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 D §1.3 | Phase 3 の初回: 変数がランチャのセッションに届き、transcript が残る | S1 の `launch_check` の表（そのセッションの行の `result`・`missing_parts`）と、取込の記録の `launch_checks` |
| 組 D §6 の 17 | raw body の `index.jsonl` の項目（取込が使う `session_id`・`request_id`・`request_file`・`response_file`・`timestamp`）と本文のファイルの名前の形が、docs のとおりである | 組 D §1.3 の初回の確かめと同じ run の、`api-bodies\` の `index.jsonl` の行のキーとファイルの名前、取込の記録の `api_bodies` の `unparsable`・`deferred_body_files` と、`unreadable` の `source` が `api_body_file` の行 |
| 組 D §6 の 11 | Claude Code が起こしたランチャの対話のセッションにも、transcript が残る | 同上（Claude Code のツールからランチャを起こした run） |
| 組 B §7 の 19 | 変数が未設定の期間の `system_prompt_variant` を、モデルから引ける | ランチャで起動したセッションの raw body の system prompt の長さと、モデルごとの版（[定義の別紙 §9](../02.データモデルと集計/【別紙】スキーマと指標の定義.md#sec-9)） |

<a id="sec-8"></a>
## 8. Mod

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 B §7 の 6 | `$.session.usage()` の中身（`cost` の中身、`startedAt` の単位） | 別の Mod の記録。V-ID 別紙 §2 の「Mod の日常の長いセッション」の行 |
| 組 C §5 の 1 | worker が止まると Mod がすべて unload され、ラベルが黙って欠ける | Mod の worker の再起動の記録と、L1 の Mod 版のラベルの欠け |
| 組 C §5 の 13 | plugin の hook の受け渡しの失敗による拒否は、settings の command hook には及ばない | V-ID 別紙 §2 の「plugin の hook が受け渡しに失敗したときの拒否」の行 |

<a id="sec-9"></a>
## 9. PowerShell 版

| 元の行 | 確かめる事柄 | 見るもの |
|---|---|---|
| 組 C §5 の 2・組 C §5 の 11 | PowerShell の起動の速さと、cc が起動したときの標準入力の文字コード | V-ID 別紙 §2 の「PowerShell で動く L1 の試作の command hook」の行 |
| 組 C §5 の 8 | 引用符の文字列だけの command の出力が、Claude の文脈に加わるか | 同上の run の入力トークン（[1-10 §5.3](../../01.基礎調査/10.cc2.1.310差分の確認/調査報告書.md#sec-5-3)） |

<a id="sec-10"></a>
## 10. Phase 3 で確かめない行

| 元の行 | 確かめる時 |
|---|---|
| 統合 §8 の 2 | Phase 4 の日常の運用（取込の記録の最後の取込の時刻） |
| 組 A §9 の 6 | J-34 の条件で実装方針を見直すとき |
| 組 B §7 の 3・組 B §7 の 9 | Phase 7 |
| 組 C §5 の 7 | 確かめなくてよい（避けたので結果に依らない） |
| 組 D §6 の 4 | V-2b の結果 |
| 組 D §6 の 8 | 確かめなくてよい（読まない） |
| 組 D §6 の 16 の LLM ゲートウェイ環境の値 | Phase 7 の着手時 |
| 組 A §9 の 14 の UI の繋ぎ方 | Phase 5 の UI を作るとき |

## 変更履歴

詳しい中身と、変わった経緯は [【別紙】改訂履歴](【別紙】改訂履歴.md) にある。

| 日付 | 版数 | 概要 |
|---|---|---|
| 2026-10-27 | v0.1 | 新規作成（クロスレビュー（2026-10-27）の実用性 I6 を受けて） |
| 2026-10-27 | v0.2 | cc 2.1.311 の差分の確認（1-11）で設計書に足した行を入れた |
| 2026-10-29〜2026-10-30 | v0.3 | 承認前の再設計と全体点検の直しで設計書に足した行を入れた。改訂の経緯を別紙に分けた |
| 2026-10-30 | v0.4 | クロスレビュー（2026-10-30）の指摘の反映で設計書に足した行と、変わった見るものを入れた。続けて、配り口の CORS の試験の `Origin` のヘッダと、`LMO_OTLP_HOST` の行を足した |
| 2026-10-30 | v0.5 | cc 2.1.312〜2.1.314 の差分の確認（1-12）で設計書に足した行と、変わった確かめる事柄を入れた |
