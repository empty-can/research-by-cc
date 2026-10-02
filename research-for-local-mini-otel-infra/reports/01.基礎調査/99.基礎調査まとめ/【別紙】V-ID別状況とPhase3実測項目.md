# 【別紙】V-ID 別状況と Phase 3 実測項目

| 項目 | 内容 |
|---|---|
| 位置付け | [まとめ報告書](報告書.md)の別紙。v0.3 の §6.1（V-ID 別の状況）と §6.3（Phase 3 で実測する項目）を、判断に直接使わない参照情報として本別紙に移した（クロスレビュー U-S5） |
| 想定読者 | Phase 2 の設計担当 Claude、Phase 3 の PoC 担当と職場環境確認手順書の作成担当。作業指示者は判断時に読まなくてよい |
| 関連 | [まとめ報告書 §6.2 Phase 1 の残作業](報告書.md#sec-6-2)、[【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) |

<a id="sec-1"></a>
## 1. V-ID 別の状況

計画書 Phase 1 の表が各調査に割り当てた V-ID の状況。V-11(b) の 33 項目は [【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) を参照。

| V-ID | 担当 | 状況 | 残り |
|---|---|---|---|
| V-1 | 1-1 | 済 | — |
| V-2a | 1-2 | 一部 | リトライ別の突合率（リトライが発生しなかった） |
| V-2b | 1-2 | 未 | まとめ報告書 Q2 の判断後 |
| V-3・V-4 | 1-1 | 済 | — |
| V-5 | 1-3 | 一部 | ユーザ定義の agent 名（まとめ報告書 Q3 の判断後。docs ではフラグ有効時に metrics を含めて実名と明記。[1-8 §2.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-2-2)）。個体の区別は trace・transcript で可能と確認済み |
| V-6 | 1-4 | 対象外にした | (B) を外したため不要 |
| V-7 | 1-3 | 未 | workflow を 1 回実行する（判断不要） |
| V-8 | 1-1 | 済 | — |
| V-9 | 1-1 | 一部 | 15 イベント中 7 件は発火条件を満たさず未観測（Phase 3 以降の日常利用で観測） |
| V-12 | 1-3 | 一部 | skill 終了後に同じプロセス内で `skill.name` が付かないこと |
| V-13 | 1-4 | 一部 | `OTEL_LOG_RAW_API_BODIES=file:<dir>` の Windows パス（まとめ報告書 Q2 で file モードを使う場合）。fileexporter 側は (B) を外したため不要 |

<a id="sec-2"></a>
## 2. Phase 3 で実測する項目

個別報告書と V-11(b) の別紙から集約した。v0.2 で [1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) の未確認事項を加えた。計画書 Phase 3 の確認観点（受信サーバが止まっていても cc の操作に影響しないか、2 セッション同時で欠落しないか等）に加えて行う。

- Phase 3 の測定は cc 2.1.287 以降で行う。Phase 1 の 1-1〜1-6 は 2.1.283 の実測で、2.1.287 での再確認の結果は [1-8 §3](../08.cc2.1.287差分の確認/調査報告書.md#sec-3) にある
- 「判定の目安」は、手順書の作成担当が基準を独自に決めずに済むよう、Claude が置いた案である（v0.4。クロスレビュー 実用 I3）。Phase 2 の設計で変わり得る。合否を置かず値を記録するだけの項目は「記録のみ」と書いた
- hook の待ち時間の基準（タグ案 L1 から L2、または ① だけへの切替の基準）は作業指示者の判断事項で、暫定値を [作業指示者裁定待ち事項](../作業指示者裁定待ち事項.md) J-12 に記録した

**本環境（Claude Code が実施）**

| 項目 | 条件 | 判定の目安（案） | 測り方・標本数 | 典拠 |
|---|---|---|---|---|
| 受信サーバ停止中の cc の挙動 | 常に | cc の操作が止まらず、エラーで終了しない（計画書 Phase 3 の確認観点） | 受信サーバを止めた状態で、`-p` と対話モードで各 3 プロンプト以上を実行する。debug log の送信エラーと、応答が返るかを記録する | 計画書 Phase 3、[1-4](../04.受信・保存コンポーネント/調査報告書.md) §4.3 |
| 対話モードでの 2 セッション同時受信（`-p` の 4 セッション同時は確認済み）。`http/json` の送信が非圧縮のままか（2.1.287 で未確認の R11） | 常に | 両セッションとも、受信した `api_request` の件数が transcript のリクエスト件数と一致する（欠落 0）。受信したリクエストに `Content-Encoding` ヘッダが無い | 2 つのウィンドウで同時に、各 5 プロンプト以上を 2 回行う。受信データを `session.id` 別に数える | [1-1 §1](../01.実データ確認/調査報告書.md#sec-1)、1-4 §4.4、[1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) |
| 対話モードでの transcript の突合率、異常終了時の transcript の欠落。長い対話セッションでの transcript の基本フィールド（2.1.287 では `-p` だけ確認） | 常に | 突合率: compact を除く全件が突合できる（1-2 と 1-8 の `-p` の結果と同じ）。異常終了時の欠落: 記録のみ（扱いは Phase 2 の設計で決める）。基本フィールド: `-p` と同じ項目がそろう | 対話モードで 3 セッション以上。そのうち 1 つ以上は compact を含む長いセッションにする。強制終了を 1 回行う | [1-2 §3.1](../02.思考トークン取得経路/調査報告書.md#sec-3-1)、[1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) |
| 対話モードの既定の auto mode（cc 2.1.284 以降）。検証では permission mode を明示して固定し、auto mode による挙動・コストの差を確かめる。hook 入力の `permission_mode` の値（R7） | 常に | 固定した mode が、`permission_mode_changed` で変わらない。hook 入力の `permission_mode` が固定した値と一致する。auto mode との差: 記録のみ | 検証は `default` に固定する（案）。auto mode との比較は、同じプロンプトを `default` と `auto` で各 3 回実行し、`api_request` の件数・`query_source` の値・`cost_usd` の合計を比べる。auto mode に対応したモデルで行う（Haiku 4.5 は非対応。1-8 §3.4） | [1-8 §3.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-3-4)・§6、計画書 Phase 3 |
| 分類器（auto mode）が実際にモデルを呼ぶ操作（作業フォルダ外への書き込み等）で、`api_request` や metrics にどう現れるか（`query_source` の新しい値。R6） | 日常利用の中で | 記録のみ（`query_source` の値と、分類器のリクエストの件数） | auto mode で作業フォルダ外への書き込みを含む操作を 1 回以上行い、`api_request` と metrics を記録する | [1-8 §3.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-3-4)・§6 |
| `event.timestamp` での並べ替えが実用上問題ないか | 常に | プロンプト単位・セッション単位の集計値が、受信順で並べた場合と同じになる | PoC の受信データ全件で、受信順と `event.timestamp` 順の逆転の件数と、集計値の差を記録する | 1-4 §6（v2.1 R-4） |
| 書き込み中の JSONL を別プロセスの DuckDB で読めるか。V-11(b) #14・#15・#28 | 保存案 S2 を採る場合 | 読み込みがエラーにならず、書きかけの末尾の行を除いて件数が一致する | 受信中のファイルを別プロセスの DuckDB で 10 回以上読み、件数とエラーを記録する | 1-4 §3.3・§6、[【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) |
| `node:sqlite` の動作（experimental の警告を含む）、DuckDB の SQLite 拡張で SQLite を読めるか | 保存案 S1 を採る場合 | 警告以外のエラーなく書き込み・読み出しができる。DuckDB の SQLite 拡張で同じ件数が読める | PoC の受信データ全件で行う | 1-4 §3.4、[まとめ報告書 §3.2](報告書.md#sec-3-2) |
| hook の待ち時間を、日常のセッションで測る（command hook と Mod。llm_request の開始までの上乗せと、hook 単体の所要時間の両方）。Phase 1 では各 n=3 の短い実行だけを測った。上乗せは `-p` で command hook 約 150 ms・Mod 約 30 ms、対話モードで command hook 約 440 ms・Mod 約 300 ms。command hook 単体の所要時間は、`-p` では 130〜370 ms、対話モードは 6 回中 2 回（2.1.283 の i3・i4）が 2.1〜2.8 秒で、原因は未特定 | タグ案 L1 を採る場合 | 暫定値（J-12）: 対話モードで、上乗せ（測定点 A。hook なしとの差）の中央値が 1 秒以下で、かつ 2 秒を超えるプロンプトが全体の 1 割以下。command hook と Mod を別に判定する | 対話モードの日常のセッションで、実装手段ごとに 20 プロンプト以上（3 セッション以上）、hook なしの基準を 10 プロンプト以上測る。測定点 A は trace の interaction span と最初の llm_request span の開始時刻の差、測定点 B は command hook が `hook_execution_complete` の `total_duration_ms`、Mod が debug log の所要時間。新しいウィンドウの最初のプロンプトは判定に含め、別にも集計する | [1-3 §4](../03.作業分類タグ方式/調査報告書.md#sec-4)、[1-8 §4.3](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-3)・[§4.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-4) |
| Mod の日常の長いセッション、Desktop・VS Code での読み込み・`prompt_id` の一致（`-p` と対話モードの短い実行では各 3 回確認済み） | タグ案 L1 を Mod で実装する場合 | 全プロンプトで、Mod が書いた `prompt_id` が OTel の `prompt.id` と一致する。Desktop・VS Code で Mod が読み込まれる | 日常のセッション 3 つ以上（hook の待ち時間の測定と同じセッションでよい）。Desktop と VS Code で各 3 プロンプト。読み込みは debug log で確かめる | [1-8 §4.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-2)・§6 |
| `OTEL_LOG_TOOL_CONTENT` の記録対象の拡大（R12） | 内容記録のフラグを有効にする検証の時 | 記録のみ（MCP・WebFetch・WebSearch の結果が `tool.output` に入るか） | MCP・WebFetch・WebSearch を各 1 回以上呼ぶ | [1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) |
| 選んだ画面案の動作（D2 は Node の版による DuckDB 接続を含む） | 画面案を選んだ後 | Phase 2 で決めた画面の集計が、PoC のデータで表示できる | PoC の受信データで、画面ごとに 1 回確かめる | 1-5 §7 |
| `retention_sweep` イベント（V-11(b) #9）、未観測のイベント（#2） | 日常利用の中で | 記録のみ（観測できたら、属性を docs と照合する） | 日常利用の期間中に受信したデータを検索する | [【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) |

**職場環境（作業指示者が実施）**

記録の様式は、項目ごとに「確認日 / cc の版 / 結果（可・不可・不明）/ 記録する値 / 備考」の 1 行とする。手順書（Phase 3）でこの様式の表を用意する。

| 項目 | 確認する場所・方法 | 記録する値 | 典拠 |
|---|---|---|---|
| ループバック宛ての OTLP 送信が届くか（`localhost`・`127.0.0.1`。最初に確認） | 職場の PC で PoC の受信サーバを起動し、OTLP の送信先を `localhost` と `127.0.0.1` にして cc で 1 プロンプトずつ実行する | 送信先ごとに、受信した件数（logs・metrics・traces）と、debug log の送信エラーの有無 | [まとめ報告書 §4.2](報告書.md#sec-4-2) |
| Node.js の版（[まとめ報告書 §5.2](報告書.md#sec-5-2) で先に分かれば不要） | `node --version` | 版 | [まとめ報告書 §4.2](報告書.md#sec-4-2) |
| Bedrock 経由の transcript に `requestId` が残るか。OTel 側の `request_id` は v2.1.282 以降 `x-amzn-requestid` から取るが、transcript 側の欠落はこれでは解消しないため、両方を確認する | transcript（`~/.claude/projects/` 配下。1-6）と、受信した `api_request` の `request_id` | transcript の `requestId` がある行と無い行の件数、`api_request` の `request_id` の有無 | [1-6](../06.ローカルファイル棚卸し/調査報告書.md) §3.7、[1-2 §5](../02.思考トークン取得経路/調査報告書.md#sec-5)、[1-8 §2.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-2-2) D7 |
| 思考トークンの内訳が返るか、社内プロキシが usage を改変しないか、V-10 | transcript の usage と、受信した `api_request` | transcript の `thinking_tokens` の有無。同じ `request_id` で、transcript と `api_request` のトークン 4 種が一致するか | 計画書 §2.2・Phase 3 |
| PowerShell の版（候補 ③ を採る場合だけ） | `$PSVersionTable.PSVersion` | 版 | [1-1 §7](../01.実データ確認/調査報告書.md#sec-7) |
| auto mode の既定化（third-party provider では対話型も `-p` も auto mode で起動する）。検証時は permission mode を明示して固定し、auto mode による挙動・コストの差を確かめる | permission mode を指定せずに起動した直後の `permission_mode_changed` イベント。固定は `--permission-mode` か `permissions.defaultMode` | 指定しない場合の起動時の mode、固定した後の mode | [1-8 §2.1](../08.cc2.1.287差分の確認/調査報告書.md#sec-2-1) D8、計画書 Phase 3 |
| Claude Mods と command hook が managed settings で止められていないか。`allowManagedModsOnly` は Mod だけを、`allowManagedHooksOnly` は利用者の settings hook も、`disableAllHooks` は両方を止める。`disableSideloadFlags` は `--plugin-dir` を拒否する。両方が止められていれば、タグ案 L1 は成り立たない | (1) managed settings のファイル（Windows では `C:\Program Files\ClaudeCode\managed-settings.json`。1-6 #4）。受信した `managed_settings_resolved` イベントの `managed_settings.sources` で、managed settings があるかも分かる（1-1 §4.2）。(2) 最小の Mod と command hook を 1 つずつ入れて 1 プロンプト実行し、debug log で動いたかを確かめる | 次のキーの値（無ければ「なし」）: `pluginConfigs."cc-plugin-sec-default@builtin".options.allowManagedModsOnly`、`allowManagedHooksOnly`、`disableAllHooks`、`disableSideloadFlags`、マーケットプレイスの制限（plugin のインストール元を制限する設定。docs が例に挙げるのは `strictKnownMarketplaces`）。Mod と command hook のそれぞれが動いたか。debug log に「hooks modules are turned off in this process」（Anthropic 側の無効化）が出ていないか | [1-8 §4.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-4)・§6、cc の Mods docs（管理者向けのページ。2026-10-03 取得） |
| Mod の `$.http.fetch` で、ローカル宛先（localhost）への送信が拒否されないか（web fetch を無効にしている組織で。docs に記載が無い）。Mods で HTTP 送信する場合だけ | Mod から PoC の受信サーバ（localhost）へ 1 回送信する | 受信できたか、拒否された場合のエラー文 | [1-8 §4.1](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-1)・§6 |

## 変更履歴

| 日付 | 版数 | 概要 |
|---|---|---|
| 2026-09-28 | v0.1 | まとめ報告書 v0.3 の §6.1・§6.3 を移して作成（クロスレビュー U-S5） |
| 2026-10-03 | v0.2 | 1-8 を受けて、hook の待ち時間の項目を訂正し（通常 130〜370 ms。2 秒超は 2 回だけ）、Mod の遅延と対話モードでの確認を加えた。1-8 §6 の未確認事項（auto mode と permission mode の固定、分類器の見え方、長い対話セッションの transcript、Mods の可否、`$.http.fetch` の localhost、R7・R11・R12）を Phase 3 の実測項目に加え、測定を 2.1.287 以降で行うことを記した。V-5 と Bedrock の `requestId` の行に docs の記載を追記 |
| 2026-10-03 | v0.3 | クロスレビュー（論理 I3、人間読み手 U-I3、実用 I2）の反映。hook の待ち時間の行を、測定点とモードを分けて書き直した（「通常 130〜370 ms」を改めた）。Mod の行を、対話モードで確認済みの範囲に合わせて改めた。職場環境の Mods の行に、command hook も managed settings で止められうることを加えた。項目数は変わらない |
| 2026-10-03 | v0.4 | クロスレビュー（実用 I3）の反映。本環境の表に「判定の目安（案）」「測り方・標本数」、職場環境の表に「確認する場所・方法」「記録する値」の列と記録の様式を加えた。hook の待ち時間の判定に、作業指示者の判断待ちの暫定値（裁定待ち事項 J-12）を置いた。managed settings で確かめるキーを列挙した。項目数は変わらない |
