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

個別報告書と V-11(b) の別紙から集約した。v0.2 で [1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) の未確認事項を、v0.6 で cc 2.1.296 の追補の未確認事項（[1-8 §7.5](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-5)）を加えた。計画書 Phase 3 の確認観点（受信サーバが止まっていても cc の操作に影響しないか、2 セッション同時で欠落しないか等）に加えて行う。

- Phase 3 の測定は cc 2.1.293 以降で行うことを提案する（v0.5 までは 2.1.287 以降としていた。[裁定待ち事項](../作業指示者裁定待ち事項.md#sec-2) J-18 で報告）。理由は、2.1.288 の OTel の値の修正（`-p` の `claude_code.tool.blocked_on_user` の source・decision が `unknown` になる不具合と、未回答の permission ask で `tool_decision` が出ない不具合）、2.1.288〜2.1.290 の transcript の回帰（終了時に最後のメッセージが失われうる。2.1.291 で修正）、2.1.287〜2.1.292 の Mod の不具合（worker の再起動中に `classic.*` hook が飛ばされる。2.1.293 で修正）である。hook と Mod の上乗せは版で動く（2.1.296 の `-p` では Mod の方が大きくなった）ので、測定では `service.version` を必ず記録し、hook と Mod の比較は同じ版の値どうしで行う
- Phase 1 の 1-1〜1-6 は 2.1.283 の実測で、2.1.287 での再確認の結果は [1-8 §3](../08.cc2.1.287差分の確認/調査報告書.md#sec-3)、2.1.296 での再確認の結果は [1-8 §7.3](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3) にある
- モデルは完全な ID で指定し、エイリアス（`haiku` 等）では指定しない。2.1.293 から、Anthropic API の `haiku` は Haiku 5.5（`claude-haiku-5-5`）に解決し、過去の実測の Haiku 4.5（`claude-haiku-4-5-20251001`）とは違う。基準モデルは、版をまたぐ継続比較（属性集合・遅延・突合）は Haiku 4.5、auto mode の比較と日常利用に近い基準は Haiku 5.5、と用途で分ける案である（[裁定待ち事項](../作業指示者裁定待ち事項.md#sec-1) J-14 で裁定待ち）
- 測定の注意（[1-8 §7.1](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-1)・[§7.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-2)）
  - permission mode は `--permission-mode` で明示して固定する。本環境はユーザ settings の `permissions.defaultMode: "auto"` により、対話モードも `-p` も auto で起動する（組み込みの既定ではない）
  - `-p` は 2.1.292 から、main が起動した background コマンドと `/loop` の wakeup を待ち、結果を受けてもう 1 ターン走る。計測用の `-p` では background コマンドを使わない（ターン数と `api_request` の件数が増えうる）
  - Git Bash から `-p "/compact"` などのスラッシュコマンドを渡すときは `MSYS_NO_PATHCONV=1` を付ける（付けないとパスに変換される）
  - 対話モードの計測は Remote Control を切って行い（`--settings` で `remoteControlAtStartup: false` を渡す。2026-10-10 の作業指示者の指示）、各 run の Remote Control の有無を記録する（[1-8 §7.3.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3-4)）
- 「判定の目安」は、手順書の作成担当が基準を独自に決めずに済むよう、Claude が置いた案である（v0.4。クロスレビュー 実用 I3）。Phase 2 の設計で変わり得る。合否を置かず値を記録するだけの項目は「記録のみ」と書いた
- hook の待ち時間の基準（タグ案 L1 から L2、または ① だけへの切替の基準）は作業指示者の判断事項で、暫定値を [作業指示者裁定待ち事項](../作業指示者裁定待ち事項.md) J-12 に記録した

**本環境（Claude Code が実施）**

| 項目 | 条件 | 判定の目安（案） | 測り方・標本数 | 典拠 |
|---|---|---|---|---|
| 受信サーバ停止中の cc の挙動 | 常に | cc の操作が止まらず、エラーで終了しない（計画書 Phase 3 の確認観点） | 受信サーバを止めた状態で、`-p` と対話モードで各 3 プロンプト以上を実行する。debug log の送信エラーと、応答が返るかを記録する | 計画書 Phase 3、[1-4](../04.受信・保存コンポーネント/調査報告書.md) §4.3 |
| 対話モードでの 2 セッション同時受信（`-p` の 4 セッション同時は確認済み）。`http/json` の送信が非圧縮のままか（2.1.287 で未確認の R11） | 常に | 両セッションとも、受信した `api_request` の件数が transcript のリクエスト件数と一致する（欠落 0）。受信したリクエストに `Content-Encoding` ヘッダが無い | 2 つのウィンドウで同時に、各 5 プロンプト以上を 2 回行う。受信データを `session.id` 別に数える | [1-1 §1](../01.実データ確認/調査報告書.md#sec-1)、1-4 §4.4、[1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) |
| 対話モードでの transcript の突合率、異常終了時の transcript の欠落。長い対話セッションでの transcript の基本フィールド（2.1.287 では `-p` だけ確認） | 常に | 突合率: compact を除く全件が突合できる（1-2 と 1-8 の `-p` の結果と同じ）。異常終了時の欠落: 記録のみ（扱いは Phase 2 の設計で決める）。基本フィールド: `-p` と同じ項目がそろう | 対話モードで 3 セッション以上。そのうち 1 つ以上は compact を含む長いセッションにする。強制終了を 1 回行う | [1-2 §3.1](../02.思考トークン取得経路/調査報告書.md#sec-3-1)、[1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) |
| 対話モードの既定の auto mode（cc 2.1.284 以降）。本環境では、ユーザ settings の `permissions.defaultMode: "auto"` により `-p` も auto で起動する。検証では permission mode を明示して固定し、auto mode による挙動・コスト・待ち時間の差を確かめる。hook 入力の `permission_mode` の値（R7） | 常に | 固定した mode が、`permission_mode_changed` で変わらない。hook 入力の `permission_mode` が固定した値と一致する。auto mode との差: 記録のみ | 検証は `default` に固定する（案）。auto mode との比較は、同じプロンプトを `default` と `auto` で各 3 回実行し、`api_request` の件数・`query_source` の値・`cost_usd` の合計と、`tool_decision` の `permissionDecisionMs`（許可判定の時間。2.1.296 で、auto mode では約 300 ms、default の Haiku 4.5 では十数 ms だった。n=1）を比べる。auto mode に対応したモデルを完全な ID で指定して行う。Haiku 4.5（`claude-haiku-4-5-20251001`）は非対応、Haiku 5.5（`claude-haiku-5-5`）は 2.1.293 以降で対応する。Haiku 5.5 を使う案は J-14 で裁定待ち（§2 冒頭） | [1-8 §3.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-3-4)・§6・[§7.3.3](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3-3)、計画書 Phase 3 |
| 分類器（auto mode）が実際にモデルを呼ぶ操作（作業フォルダ外への書き込み等）で、`api_request` や metrics にどう現れるか（`query_source` の新しい値。R6）。分類器は 2.1.288 から Sonnet 5 に固定され（`ANTHROPIC_DEFAULT_SONNET_MODEL` で Sonnet 5.5・Opus 5.5 を固定しても無視される）、会話が長すぎて分類器が読めないと、確認・失敗の代わりに compaction する（changelog。docs 未反映）。2.1.296 では `--model haiku`（Haiku 5.5）の対話も auto のまま動くので、分類器が働く場面が増える | 日常利用の中で | 記録のみ（`query_source` の値と、分類器のリクエストの件数・`model`。長い会話での `compaction` の `trigger` の値） | auto mode で作業フォルダ外への書き込みを含む操作を 1 回以上行い、`api_request` と metrics を記録する。分類器のリクエストの `model` が Sonnet 5 か、長い会話で予期しない `compaction`（`query_source=compact`）が出るかを見る | [1-8 §3.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-3-4)・§6・[§7.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-2) |
| `event.timestamp` での並べ替えが実用上問題ないか | 常に | プロンプト単位・セッション単位の集計値が、受信順で並べた場合と同じになる | PoC の受信データ全件で、受信順と `event.timestamp` 順の逆転の件数と、集計値の差を記録する | 1-4 §6（v2.1 R-4） |
| 書き込み中の JSONL を別プロセスの DuckDB で読めるか。V-11(b) #14・#15・#28 | 保存案 S2 を採る場合 | 読み込みがエラーにならず、書きかけの末尾の行を除いて件数が一致する | 受信中のファイルを別プロセスの DuckDB で 10 回以上読み、件数とエラーを記録する | 1-4 §3.3・§6、[【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) |
| `node:sqlite` の動作（experimental の警告を含む）、DuckDB の SQLite 拡張で SQLite を読めるか | 保存案 S1 を採る場合 | 警告以外のエラーなく書き込み・読み出しができる。DuckDB の SQLite 拡張で同じ件数が読める | PoC の受信データ全件で行う | 1-4 §3.4、[まとめ報告書 §3.2](報告書.md#sec-3-2) |
| hook の待ち時間を、日常のセッションで測る（command hook と Mod。llm_request の開始までの上乗せと、hook 単体の所要時間の両方）。Phase 1 では各 n=3 の短い実行だけを測った。上乗せは、2.1.287 で `-p` command hook 約 150 ms・Mod 約 30 ms、対話モード command hook 約 440 ms・Mod 約 300 ms。2.1.296 で `-p` command hook 約 155 ms・Mod 約 200 ms（Mod の方が大きい）、対話モード command hook 約 235 ms・Mod 約 160 ms（Remote Control あり）／約 211 ms・約 110 ms（Remote Control なし）。command hook 単体の所要時間は、`-p` では 130〜370 ms（2.1.296 は 130〜191 ms）、対話モードは 2.1.287 で 383〜495 ms、2.1.296 で 204〜249 ms（Remote Control あり）・183〜224 ms（なし）。2.1.283 の i3・i4 の 2 回だけが 2.1〜2.8 秒で、原因は未特定。2 秒超は 2.1.287・2.1.296 では出ていない（[1-3 §2 の版・モード別の表](../03.作業分類タグ方式/調査報告書.md#sec-2-1)） | タグ案 L1 を採る場合 | 暫定値（J-12）: 対話モードで、上乗せ（測定点 A。hook なしとの差）の中央値が 1 秒以下で、かつ、上乗せが 2 秒を超えるプロンプト（プロンプトごとに、測定点 A の値から hook なしの中央値を引いて求める）が全体の 1 割以下。command hook と Mod を別に判定する。判定は Phase 3 で使う版の値で行い、別の版の値と混ぜない | 対話モードの日常のセッションで、実装手段ごとに 20 プロンプト以上（3 セッション以上）、hook なしの基準を 10 プロンプト以上測る。測定点 A は trace の interaction span と最初の llm_request span の開始時刻の差、測定点 B は command hook が `hook_execution_complete` の `total_duration_ms`、Mod が debug log の所要時間。新しいウィンドウの最初のプロンプトは判定に含め、別にも集計する。測り方の注記: (1) `/model` でモデルを切り替えた直後のプロンプトは別に扱う（2.1.288 から、新しい環境の最初のリクエストとモデル切替直後のリクエストは最大 1.5 秒待つ。新しいウィンドウの最初のプロンプトでは出なかった）。(2) 測定点 B の `total_duration_ms` は、同じ event でマッチした全 hook の合算である（docs 2.1.295）。他の `UserPromptSubmit` hook があれば、`hook_registered` で数を記録し、L1 の hook 単体の時間として扱わない。(3) Remote Control の接続の有無を run ごとに記録する。本環境の日常のセッションは接続した状態で動く（ユーザ設定 `remoteControlAtStartup: true`）ので、判定の根拠には接続あり・なしの両方の値を並べる | [1-3 §4](../03.作業分類タグ方式/調査報告書.md#sec-4)、[1-8 §4.3](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-3)・[§4.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-4)・[§7.3.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3-2) |
| Mod の日常の長いセッション、Desktop・VS Code での読み込み・`prompt_id` の一致（`-p` と対話モードの短い実行では、2.1.287・2.1.296 とも各 3 回確認済み）。Mods は端末の cc では 2.1.287 以降、Desktop 同梱の cc では 2.1.286 以降で既定で有効。Mod を採るなら 2.1.293 以降が前提（2.1.287〜2.1.292 は、worker の再起動中に `classic.*` hook が飛ばされ、ラベルが黙って欠けた）。`-p` の Mod の上乗せが 2.1.296 で増えた原因の手がかり（組み込み Mod `cc-plugin-agents-md` の `prompt.context` がプロンプト受付後の待ち経路に入る【推測、debug n=1】）も確かめる | タグ案 L1 を Mod で実装する場合 | 全プロンプトで、Mod が書いた `prompt_id` が OTel の `prompt.id` と一致する。Desktop・VS Code で Mod が読み込まれる。worker の再起動の前後でラベルが欠けない。`prompt.context` の位置と所要時間: 記録のみ | 日常のセッション 3 つ以上（hook の待ち時間の測定と同じセッションでよい）。Desktop と VS Code で各 3 プロンプト。読み込みは debug log で確かめる。日常のセッションでの worker の再起動の回数を debug log で数え、その前後のラベルの欠けを調べる。debug log で、組み込み Mod の `prompt.context` の位置と所要時間を `-p`・対話モードで見る。組み込みの AGENTS.md 対応を切った場合の測定点 A も測る（必要なら） | [1-8 §4.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-2)・§6・[§7.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-2)・[§7.3.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3-2) |
| 自動開始ターン（scheduled task・`/loop` の 1 回、background subagent の起動元への報告）で、`UserPromptSubmit` hook の入力に `prompt_id` が入るか、OTel の `user_prompt` の `prompt.id` と一致するか。docs 2.1.295 は、自動開始ターンでも hook と `user_prompt` が発火すると明記したが、区別するフィールドと `prompt_id` の有無は書いていない（v0.6 で追加） | タグ案 L1 を採る場合 | 記録のみ（hook 入力の `prompt_id` の有無、`prompt` の形（本文は記録しない。長さと、定型の通知の形かどうかだけ）、Mod の `source`、`user_prompt` の `prompt.id`・`command_name` の有無と、両者の一致）。L1 での扱い（[裁定待ち事項](../作業指示者裁定待ち事項.md#sec-1) J-15）と判定規則は、この記録を見て決める | `/loop` の 1 回と background subagent の報告を、各 1 回以上起こす。command hook と Mod で hook 入力のキー名と `prompt_id` を記録し、OTel の `user_prompt` と突き合わせる | [1-3 §2](../03.作業分類タグ方式/調査報告書.md#sec-2)・[§4](../03.作業分類タグ方式/調査報告書.md#sec-4)、[1-8 §7.5](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-5) |
| `OTEL_LOG_TOOL_CONTENT` の記録対象の拡大（R12） | 内容記録のフラグを有効にする検証の時 | 記録のみ（MCP・WebFetch・WebSearch の結果が `tool.output` に入るか） | MCP・WebFetch・WebSearch を各 1 回以上呼ぶ | [1-8 §6](../08.cc2.1.287差分の確認/調査報告書.md#sec-6) |
| 選んだ画面案の動作（D2 は Node の版による DuckDB 接続を含む） | 画面案を選んだ後 | Phase 2 で決めた画面の集計が、PoC のデータで表示できる | PoC の受信データで、画面ごとに 1 回確かめる | 1-5 §7 |
| `retention_sweep` イベント（V-11(b) #9）、未観測のイベント（#2） | 日常利用の中で | 記録のみ（観測できたら、属性を docs と照合する） | 日常利用の期間中に受信したデータを検索する | [【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) |
| `cost_usd`・`claude_code.cost.usage` が、Haiku 5.5 の段階単価（changelog 2.1.293: $0.10/$0.50 per Mtok、100K 超のプロンプトは $0.50/$2.50）を反映するか（v0.6 で追加。V-11(b) #24） | Haiku 5.5 を集計・比較の対象にする場合（コスト集計の設計の前） | 単価表から計算した値と `cost_usd` が、100K 以下・100K 超の両方で一致する | 入力が 100K トークン以下のプロンプトと、100K トークンを超えるプロンプトを、Haiku 5.5（`claude-haiku-5-5`）で各 1 回以上実行し、`api_request` のトークン 4 種から計算した値と `cost_usd` を比べる。単価は料金ページで出典を確かめてから使う（[裁定待ち事項](../作業指示者裁定待ち事項.md#sec-2) J-17） | [【別紙】V-11(b)確認結果](【別紙】V-11(b)確認結果.md) #24、[1-8 §7.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-2) |
| OTel の `api_request` に出ない API 呼び出しの件数（起動時の `quota_check`、ターン終了後の `side_query` 等。2.1.287・2.1.296 の debug log で確認）。課金・トークン量は未確認（v0.6 で追加） | 常に（コスト集計の設計の前） | 記録のみ（セッションあたりの、debug log の API 呼び出しの件数と `api_request` の件数の差、`source` 別の内訳） | 日常のセッション 3 つ以上で debug log を取り、API 呼び出しの件数を `source` 別に数えて、同じセッションの `api_request` の件数と比べる | [1-8 §7.3.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3-4) |
| 版上げ（install・upgrade）直後の最初のセッションの扱い。permission mode は feature flag の取得前に決まるので、表と違う mode で始まりうる（docs）。2.1.289 で直った「アップグレード後の最初のセッションで Mod が読み込まれない」不具合とも重なる（v0.6 で追加） | cc の版を上げたとき | 版上げ直後の 1 回目は測定に使わない。使う場合は、`permission_mode_changed` と Mod の読み込みで条件がそろっていることを確かめる | 版上げ直後の最初のセッションで、`permission_mode_changed` の有無と、debug log の Mod の読み込みを記録する | [1-8 §7.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-2) |

**職場環境（作業指示者が実施）**

記録の様式は、項目ごとに「確認日 / cc の版 / 結果（可・不可・不明）/ 記録する値 / 備考」の 1 行とする。手順書（Phase 3）でこの様式の表を用意する。

| 項目 | 確認する場所・方法 | 記録する値 | 典拠 |
|---|---|---|---|
| ループバック宛ての OTLP 送信が届くか（`localhost`・`127.0.0.1`。最初に確認） | 職場の PC で PoC の受信サーバを起動し、OTLP の送信先を `localhost` と `127.0.0.1` にして cc で 1 プロンプトずつ実行する | 送信先ごとに、受信した件数（logs・metrics・traces）と、debug log の送信エラーの有無 | [まとめ報告書 §4.2](報告書.md#sec-4-2) |
| Node.js の版（[まとめ報告書 §5.2](報告書.md#sec-5-2) で先に分かれば不要） | `node --version` | 版 | [まとめ報告書 §4.2](報告書.md#sec-4-2) |
| Bedrock 経由の transcript に `requestId` が残るか。OTel 側の `request_id` は v2.1.282 以降 `x-amzn-requestid` から取るが、transcript 側の欠落はこれでは解消しないため、両方を確認する | transcript（`~/.claude/projects/` 配下。1-6）と、受信した `api_request` の `request_id` | transcript の `requestId` がある行と無い行の件数、`api_request` の `request_id` の有無 | [1-6](../06.ローカルファイル棚卸し/調査報告書.md) §3.7、[1-2 §5](../02.思考トークン取得経路/調査報告書.md#sec-5)、[1-8 §2.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-2-2) D7 |
| 思考トークンの内訳が返るか、社内プロキシが usage を改変しないか、V-10 | transcript の usage と、受信した `api_request` | transcript の `thinking_tokens` の有無。同じ `request_id` で、transcript と `api_request` のトークン 4 種が一致するか | 計画書 §2.2・Phase 3 |
| PowerShell の版（候補 ③ を採る場合だけ） | `$PSVersionTable.PSVersion` | 版 | [1-1 §7](../01.実データ確認/調査報告書.md#sec-7) |
| auto mode の既定化（third-party provider では対話型も `-p` も auto mode で起動する）。検証時は permission mode を明示して固定し、auto mode による挙動・コストの差を確かめる。auto mode に入れるのは対応モデルだけで（Sonnet 5 以降・Opus 4.7 以降・Haiku 5.5（2.1.293 以降）・Fable）、それ以外は Manual で起動する。Bedrock ではエイリアスの解決先が本環境と違う（`haiku` は Haiku 4.5、`sonnet` は Sonnet 4.5、`opus` は Opus 5.5）ので、手順書ではモデルを完全な ID で指定する（v0.6 で追加） | permission mode を指定せずに起動した直後の `permission_mode_changed` イベント。固定は `--permission-mode` か `permissions.defaultMode`。managed settings とユーザ settings の `permissions.defaultMode` の値も確かめる。指定したモデル ID と、`api_request` の `model` | 指定しない場合の起動時の mode、固定した後の mode、managed settings・ユーザ settings の `defaultMode` の値（無ければ「なし」）、指定したモデル ID と実際の `model` | [1-8 §2.1](../08.cc2.1.287差分の確認/調査報告書.md#sec-2-1) D8・[§7.3.3](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-3-3)、計画書 Phase 3 |
| Claude Mods と command hook が managed settings で止められていないか。`pluginConfigs."cc-plugin-sec-default@builtin".options.allowManagedModsOnly`（組み込み plugin の option。トップレベルのキーではない）は、利用者の Mod を読み込むが拒否し、hook を動かさない。settings hook と、plugin の `hooks/hooks.json` の command hook は動き続ける。`allowManagedHooksOnly` は組織が配布していない hook（利用者の settings hook を含む）を、`disableAllHooks` は Mod と command hook の両方を止める。`disableSideloadFlags` は `--plugin-dir` を拒否する。タグ案 L1 が成り立たないのは、`allowManagedHooksOnly` か `disableAllHooks` が効いている場合である。職場の cc が 2.1.287〜2.1.292 なら、Mod の `classic.*` hook が飛ばされる不具合の範囲にある（2.1.293 で修正） | (1) managed settings のファイル（Windows では `C:\Program Files\ClaudeCode\managed-settings.json`。1-6 #4）。受信した `managed_settings_resolved` イベントの `managed_settings.sources` で、managed settings があるかも分かる（1-1 §4.2）。(2) 最小の Mod と command hook を 1 つずつ入れて 1 プロンプト実行し、debug log で動いたかを確かめる。Mod が動いたかは、hooks module の「loaded」の行ではなく、その後に拒否の行（「refused by cc-plugin-sec-default」で始まり「(allowManagedModsOnly)」で終わる）が出ていないかで判定する | 次のキーの値（無ければ「なし」）: `pluginConfigs."cc-plugin-sec-default@builtin".options.allowManagedModsOnly`、`allowManagedHooksOnly`、`disableAllHooks`、`disableSideloadFlags`、マーケットプレイスの制限（plugin のインストール元を制限する設定。docs が例に挙げるのは `strictKnownMarketplaces`）。cc の版。Mod と command hook のそれぞれが動いたか。debug log に `allowManagedModsOnly` の拒否の行が出ていないか。debug log に「hooks modules are turned off in this process」が出ていないか。docs 2.1.295 でこの文言は 2 種に分かれた。「: the rollout switch served off」は Anthropic 側の無効化で、判定に使うのはこちらだけ。「: the rollout switch was saved off by an earlier session」は以前のセッションが保存した古い値で、cc を一度起動し直してから確かめ直す | [1-8 §4.4](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-4)・§6・[§7.2](../08.cc2.1.287差分の確認/調査報告書.md#sec-7-2)、cc の Mods docs（管理者向けのページ・トラブルシューティングのページ。2026-10-03 取得、2026-10-10 に 2.1.295 時点の版で再確認） |
| Mod の `$.http.fetch` で、ローカル宛先（localhost）への送信が拒否されないか（web fetch を無効にしている組織で。docs に記載が無い）。Mods で HTTP 送信する場合だけ | Mod から PoC の受信サーバ（localhost）へ 1 回送信する | 受信できたか、拒否された場合のエラー文 | [1-8 §4.1](../08.cc2.1.287差分の確認/調査報告書.md#sec-4-1)・§6 |

## 変更履歴

| 日付 | 版数 | 概要 |
|---|---|---|
| 2026-09-28 | v0.1 | まとめ報告書 v0.3 の §6.1・§6.3 を移して作成（クロスレビュー U-S5） |
| 2026-10-03 | v0.2 | 1-8 を受けて、hook の待ち時間の項目を訂正し（通常 130〜370 ms。2 秒超は 2 回だけ）、Mod の遅延と対話モードでの確認を加えた。1-8 §6 の未確認事項（auto mode と permission mode の固定、分類器の見え方、長い対話セッションの transcript、Mods の可否、`$.http.fetch` の localhost、R7・R11・R12）を Phase 3 の実測項目に加え、測定を 2.1.287 以降で行うことを記した。V-5 と Bedrock の `requestId` の行に docs の記載を追記 |
| 2026-10-03 | v0.3 | クロスレビュー（論理 I3、人間読み手 U-I3、実用 I2）の反映。hook の待ち時間の行を、測定点とモードを分けて書き直した（「通常 130〜370 ms」を改めた）。Mod の行を、対話モードで確認済みの範囲に合わせて改めた。職場環境の Mods の行に、command hook も managed settings で止められうることを加えた。項目数は変わらない |
| 2026-10-03 | v0.4 | クロスレビュー（実用 I3）の反映。本環境の表に「判定の目安（案）」「測り方・標本数」、職場環境の表に「確認する場所・方法」「記録する値」の列と記録の様式を加えた。hook の待ち時間の判定に、作業指示者の判断待ちの暫定値（裁定待ち事項 J-12）を置いた。managed settings で確かめるキーを列挙した。項目数は変わらない |
| 2026-10-03 | v0.5 | クロスレビュー Round 3（実用 S8）の反映。hook の行の判定基準で、「2 秒を超える」の対象を測定点 A の上乗せ（hook なしの中央値との差）と明記 |
| 2026-10-10 | v0.6 | cc 2.1.296（docs 2.1.295）の反映（1-8 §7）。§2 冒頭で、測定版の下限を 2.1.293 以降とする提案（J-18）、モデルを完全な ID で指定することと基準モデルの案（J-14）、測定の注意（permission mode の固定、`-p` の終了待ち、`MSYS_NO_PATHCONV`、Remote Control を切って計測し有無を記録）を追加。hook の行に 2.1.296 の値と測り方の注記（`/model` の切替直後、測定点 B は全 hook の合算、Remote Control の有無）、auto mode の行に Haiku 5.5 と `permissionDecisionMs`、分類器の行に 2.1.288 の変更、Mod の行に既定の版・不具合の期間・`prompt.context`、職場の auto mode の行に Bedrock の解決先、Mods の行に `allowManagedModsOnly` の意味と debug log での判定方法を追加。本環境の表に 4 項目（自動開始ターンの `prompt_id`、`cost_usd` の段階単価、OTel に出ない API 呼び出しの件数、版上げ直後の最初のセッション）を追加（本環境 13→17 項目、職場 8 項目は変わらない） |
