# F02-001 background Agent の Write 権限設定漏れによる処理中断・再実行

## 1. はじめに

### 1.1 要改善点概要

フェーズ 02（基礎調査）の並列 Agent 実行（パターン A：Sonnet 8 並列）において、background Agent がファイルへの書き込み時に権限プロンプト（permission prompt）を受け取れず Write が拒否され、処理が中断した。事前に `settings.json` の `permissions.allow` へ `Write` 権限を追加しておく手順が抜けていたことが直接原因。事象解消のため処理中断後に権限を追加し再実行する対応（手戻り）が発生した。

なお、本要改善点の **真の射程は「Write 権限のみ」ではなく**、`permissions.allow` に事前登録されていない **あらゆる種別のアクション**（Edit / Bash の特定コマンド / MCP ツール / WebFetch ドメイン / Agent / Read deny 該当パス等）が、background Agent や並列 sub-agent から発行された場合に同じ手戻り構造を引き起こす点にある（§4 で再構成）。

### 1.2 サマリ

| 項目 | 内容 |
| --: | :-- |
| **カテゴリ** | ツール／権限 |
| **優先度** | 高 |
| **スコープ** | 横断 |
| **ステータス** | 対処中（本格対処の中核実装済み・残部=案 6 雛型同梱はクロージング時判断） |
| **影響範囲** | background Agent や並列 sub-agent が `permissions.allow` に未登録のアクションを発行する全フェーズ・全サブタスク。特に複数 Agent を並列起動するパターン A／C が高リスク。Write のみならず Edit / Bash / MCP / WebFetch / Agent 等あらゆるアクション種別に同一構造で波及 |
| **関連 ID** | なし（同根の類件: 2026-05-06 commit `afea8b8` で対応した「並列 Agent 実行時の Bash 系 permission prompt 多発」事象）／プロセス改善観点での派生: F02-013（なぜなぜ分析プロセスの改善検討） |
| **採用案** | **本調査活動中（暫定）**: 検知ベースの対処療法（拒否事象を検出して `settings.json` に追加）を継続。`auto` モードは利用プラン Pro では利用不可のため対象外。**本格対処の中核実装済み（2026-05-07）**: §5.2 多層防御のうち案 1（事前列挙チェックリスト）+ 案 2（検出ベース拡張ワークフロー）+ 案 5（落とし穴記録）を統合配置した path-scoped rule `.claude/rules/agent-permission-runtime.md`（149 行、横断スコープ）を新規作成。**残部（クロージング時判断）**: 案 6 雛型同梱（次期プロジェクト開始時タスク）。**クロージング時の評価対象**: 本先行適用案の効果分析と、その時点の内容をそのまま正式対応として採用するかの最終判断 |

## 2. 発生事象の整理

### 2.1 発生事象

2026-05-03（日）のフェーズ 02 基礎調査において、作業計画書 v1.0 に定義された「パターン A：並列（Sonnet 8 並列）」で 8 本の background Agent を同時起動し、各サブタスクの調査報告書を書き込む作業を行った。このとき、background Agent は Claude Code のメインセッションから切り離されて動作するため、実行中に権限プロンプトを受け取ることができない（公式ドキュメント `https://code.claude.com/docs/en/sub-agents` のとおり、subagent は parent のパーミッション context を継承するが、`default` モードではプロンプト挙動に依存し、parent の allow ルールに事前登録されていないアクションは実質的に拒否される）。一方、実行時点の `settings.json`（コミット `a463ec6` 以降の初期状態）の `permissions.allow` リストには `Write` 権限が含まれていなかった。その結果、各 Agent が調査報告書ファイルを書き込む段階で Write が拒否され、処理が中断した。

事象解消のため、以下の対応が発生した:
1. `settings.json` の `permissions.allow` に `Write(research-for-local-RAG-for-cc/**)` を追加（コミット `a756e7e`）
2. background Agent を再実行（コミット `51211f5`）

### 2.2 発生経緯

1. **計画フェーズ**: 作業計画書 v1.0（コミット `6711737`、2026-05-02）でフェーズ 02 の実施方針として「パターン A：並列（独立サブタスクを並列実行）、機械的情報抽出・要約（Sonnet）」が決定された。計画書には並列 Agent の起動方式や役割が明記されていたが、background Agent が Write 操作を行うための事前権限設定という手順は言及されていなかった。

2. **実行フェーズ**: 2026-05-03 にフェーズ 02 の実作業に着手し、Sonnet 8 並列で background Agent を起動した。各 Agent が `research-for-local-RAG-for-cc/reports/02.基礎調査/` 配下に調査報告書ファイルを書き込もうとした段階で Write が拒否され、処理が中断した。

3. **事後対応**: 処理中断を受けて `settings.json` に Write 権限を追加し（コミット `a756e7e`、コミットメッセージ: "02.基礎調査の並列 Agent 実行時に、background agent が permission prompt を受けられず Write が拒否される問題を解消するための事前許可"）、再実行した（コミット `51211f5`）。

4. **フェーズ 02 振り返り**: 2026-05-04 の振り返りで本事象が要改善点として識別され F02-001 として起票された。`improvements/` フォルダ新設時のコミット（`6f0080c`）では `Write(research-for-*/**)` および `Edit(research-for-*/**)` へのグロブ化拡張が「F02-001 対応」として実施された。

5. **同根事象の継続発生（追加発見）**: 2026-05-06 コミット `afea8b8` にて「並列 Agent 実行時に `cd` / `git show` / `git blame` / `wc` 等で permission prompt が多発する事象」が認識され、これらを `permissions.allow` に追加する対応が行われた。F02-001 と完全に同型（事前 allow 漏れによる中断）であり、対象が Write から Bash 系コマンドに広がっただけの同根事象である。

## 3. 原因分析

### 3.1 直接原因

以下の複数原因が同時に作用した（単一原因ではない）:

1. **事前の Write 権限の設定漏れ（観察事実）**: background Agent を起動する前に `settings.json` の `permissions.allow` に `Write` 権限を追加する手順が実行されなかった。結果として、background Agent がファイルを書き込もうとした際に Claude Code の権限チェックで拒否され、処理が中断した。

2. **background Agent / 並列 sub-agent の permission 制約（仕様事実）**: 並列起動された sub-agent や background 実行コンテキストでは、実行中の permission prompt をユーザに即座に応答してもらうフィードバックループが事実上機能せず、「事前 allow に無いアクション ＝ 拒否される」という挙動になる。これは Claude Code 仕様であり変更不能（Anthropic 公式ドキュメント `https://code.claude.com/docs/en/permissions` の「deny → ask → allow」評価順位および sub-agent の permission inheritance 規定）。

3. **作業着手前の権限事前確認プロセスの不在（プロセス事実）**: 計画フェーズ・着手フェーズのいずれにも、「これから sub-agent / background で発行されうるアクションを洗い出して `settings.json` の `permissions.allow` と照合する」というチェックポイントが組み込まれていなかった。CLAUDE.md・`ハマりどころ.md`・作業計画書のいずれにも記述がない。

### 3.2 根本原因

## なぜなぜ分析: background Agent の Write 権限設定漏れによる処理中断

### 問題記述

**What（何が）:** フェーズ 02 の background Agent（Sonnet 8 並列）がファイル書き込み時に Write 権限拒否を受け、処理が中断した
**When（いつ）:** 2026-05-03、フェーズ 02 基礎調査の並列 Agent 実行時
**Where（どこで）:** `settings.json` の `permissions.allow` と、background Agent の Write 操作（`research-for-local-RAG-for-cc/reports/02.基礎調査/` 配下）
**Impact（影響）:** 8 本の Agent 処理が中断し、Write 権限追加 → 再実行という手戻りが発生。作業時間ロスおよびコスト（トークン）の再消費が生じた

### Why Chain（分岐ツリー）

直接原因が「事前漏れ（プロセス側）」と「prompt を受けられない仕様（システム側）」の二系統に跨るため、5-whys スキル「落とし穴 3」に従い分岐構造で記述する。

#### 分岐 A: なぜ事前 allow が漏れたか（プロセス側）

| Why | 問い | 答え | 根拠・証拠 |
|---|---|---|---|
| Why A-1 | なぜ background Agent が Write を拒否されたか？ | 実行時点の `settings.json` の `permissions.allow` に `Write` エントリが存在しなかったため | コミット `a463ec6`（初期化）〜`a756e7e`（修正）の間の `settings.json` には `Write` エントリが無い。`a756e7e` のコミットメッセージが "permission prompt を受けられず Write が拒否される問題を解消" と明記している |
| Why A-2 | なぜ `permissions.allow` に `Write` が追加されていなかったか？ | sub-agent / background 実行で発行されうるアクション群を作業着手前に列挙し `permissions.allow` と照合する **準備チェックポイント** が、計画書にも CLAUDE.md にも `ハマりどころ.md` にも組み込まれていなかったため | 作業計画書 v1.0（コミット `6711737`）にはパターン A 並列の実施方針は記載されているが、事前権限確認手順への言及はない。`ハマりどころ.md` にも background Agent / 並列実行に伴う権限確認に関するエントリは存在しない（2026-05-06 時点での全文検索で確認） |
| Why A-3 | なぜ準備チェックポイントが存在しなかったか？ | 「sub-agent / background は事前 allow されたアクションしか実行できない」という挙動特性が、計画レビュー時に **意識すべき判断基準として明文化されていなかった** ため。直前の対面セッション（メインセッション）では `default` permission mode で都度 prompt 確認できていたため、その挙動が sub-agent でも同じだという暗黙の前提が成立していた | Anthropic 公式ドキュメント `code.claude.com/docs/en/sub-agents` の「Subagents inherit the permission context from the main conversation」「`default`: Standard permission checking with prompts」と、メインセッションで対話的に prompt 応答できた経験を区別する記述が、本プロジェクト着手時点のいずれの設定ファイル・運用ドキュメントにも存在しなかった |
| Why A-4 | なぜ挙動特性が明文化されていなかったか？ | 本プロジェクトで「並列 sub-agent / background Agent を本格利用する」初回実施が 2026-05-03 のフェーズ 02 であり、実体験で挙動の差を踏むまで明文化のトリガが発生しなかった。計画段階で公式ドキュメントから permission モデルを逆算して準備するというプロセス自体が、研究プロジェクト一巡目の段階では未確立だった | コミット `a463ec6`（初期化）は 2026-05-01、background Agent を使った本格的な並列実行はコミット `51211f5`（2026-05-03）が初回。フェーズ 02 振り返りで F02-001〜F02-007 の 7 件が同時起票された事実（`improvements/【本紙】要改善点一覧.md` 変更履歴 2026-05-04）は、一巡目で品質ガードを経験的に積み上げる段階だったことを示す |

#### 分岐 B: なぜ実行時に拒否されると気付くまで対処できないか（システム側）

| Why | 問い | 答え | 根拠・証拠 |
|---|---|---|---|
| Why B-1 | なぜ実行中に prompt 応答で復帰できないか？ | sub-agent / background 実行コンテキストでは、permission prompt を発行してもユーザの即時応答に対して並列 Agent が同期的に待機する仕組みが事実上機能しないため。`permissionMode: default` でも、未許可アクションは実質的に拒否される運用になる | コミット `a756e7e` メッセージ「background agent が permission prompt を受けられず」／公式ドキュメント `code.claude.com/docs/en/permissions` の sub-agent permission 継承規定および `dontAsk` モードの説明（"Auto-deny permission prompts (explicitly allowed tools still work)"）から、未明示 allow が auto-deny に近い運用になることが裏付けられる |
| Why B-2 | なぜこの仕様が存在するか？ | これは Claude Code 側の仕様（並列実行の設計上、対話的 prompt は単一のメインセッションを前提とするため、sub-agent には parent の事前ルールを継承させる設計）であり、本プロジェクト側で変更できない外部制約である | 公式ドキュメント `code.claude.com/docs/en/sub-agents` の「Each subagent runs in its own context window with ... independent permissions」「Subagents inherit the permission context from the main conversation」 |
| Why B-3 | この外部制約に対し本プロジェクトは何ができるか？ | (a) 事前 allow を網羅する、(b) sub-agent 側の `permissionMode` を `bypassPermissions` / `auto` に切り替える、(c) PreToolUse hook で動的判定する、(d) 拒否時のフォールバック・自動拡張ワークフローを設計する、のいずれか／組み合わせ | 公式ドキュメント `code.claude.com/docs/en/permissions` の「Permission modes」「Extend permissions with hooks」セクション、および subagent frontmatter `permissionMode` 設定 |

#### 共通根（分岐 A・B が合流する点）

| Why | 答え | 根拠・証拠 |
|---|---|---|
| Why C-1（共通） | sub-agent / background の permission 仕様（B 側の外部制約）を前提とした **事前準備プロセス**（A 側で必要な観点）が、計画フェーズ・着手フェーズに組み込まれていなかった。具体的には「これから sub-agent / background が発行しうるアクションを列挙する → 既存 `permissions.allow` と照合する → 不足分を追加するか、`permissionMode` 切替・hook 等の代替手段を選ぶ」という意思決定フローが未定義 | §3.1 直接原因 1〜3 の合流点。本件 (Write) も commit `afea8b8` の Bash 系も、いずれも同じ「事前準備プロセスの不在」で説明可能 |

### 根本原因

**特定した原因:** 「sub-agent / background Agent は実行中に permission prompt 経由でユーザ応答を取り戻す手段を持たないため、事前 allow（または `permissionMode` 切替・hook 等）による準備が必須である」という外部制約に対し、作業計画・着手フェーズに **事前準備プロセス**（発行されうるアクションの列挙・既存 allow との照合・不足分の対処方針決定）が組み込まれていない状態。

**種別:** プロセス（着手前の準備チェックリスト／意思決定フローの欠如）／知識（sub-agent 仕様と対話セッション挙動の差の暗黙化）

**確信度:** 高

### バリデーション（逆方向確認）

- 「sub-agent / background 実行前のアクション列挙 × `permissions.allow` 照合 × 不足対処方針決定」のフローが整備 → Why A-3「準備チェックポイントが存在しない」が解消 ✓
- Why A-3 が解消 → Why A-2「`permissions.allow` に Write が追加されていなかった」が防止される ✓
- Why A-2 が解消 → Why A-1「Write が拒否された」が防止される ✓
- Why A-1 が解消 → 問題「処理中断・再実行」が発生しない ✓
- B 側の外部制約は変更不能だが、A 側の準備プロセスが整っていれば B-1 の影響を受けない ✓

チェーンは成立する。

### 対策（5-whys スキル出力）

| 種別 | 対応内容 | 担当 | 期限 |
|---|---|---|---|
| 即時対応 | `settings.json` の `permissions.allow` に `Write(research-for-*/**)` と `Edit(research-for-*/**)` を事前追加（コミット `a756e7e` および `6f0080c` で実施済み）。並列 Agent 実行で頻出する読み取り系 Bash コマンド（cd / git show / git blame / wc / pwd）も追加（コミット `afea8b8`） | — | 対応済み（2026-05-03〜06） |
| 予防措置 | sub-agent / background Agent を起動する作業の **着手前チェックリスト** を整備し、CLAUDE.md または `.claude/rules/` に配置。「これから sub-agent / background から発行されうるアクションを列挙する」「既存 `permissions.allow` と照合する」「不足分について allow 追加 / `permissionMode` 切替 / hook / フォールバック設計のいずれを採るか決定する」の 3 ステップを規定 | Claude / 作業指示者 | 次期 sub-agent 並列実行前 |
| 予防措置 | Anthropic 公式の permission system 仕様（permission modes / Bash 組み込み read-only / process wrapper strip / Read & Edit gitignore 仕様 / sub-agent 継承挙動）の要点を `ハマりどころ.md` に集約し、新規メンバ・新規プロジェクト着手時の参照資産化 | Claude / 作業指示者 | 同上 |
| 検出 | 新規プロジェクト（`research-for-xxx/`）開始時に `settings.json` テンプレートへ `Write(research-for-*/**)` `Edit(research-for-*/**)` および読み取り系 Bash 群を既定エントリとして含める | Claude / 作業指示者 | 次期プロジェクト開始時 |
| 検出（フォールバック） | sub-agent 実行中に permission 拒否が発生した場合の自動再開・追加 allow ワークフロー（PreToolUse hook ベース）を検討。事前列挙では網羅できない長尾事象に対する受け皿として位置付け | Claude / 作業指示者 | §5 で詳細案出 |

### レビューア所見（Opus 4.7、2026-05-06）

§3.1 / §3.2 を Opus 視点で品質チェックし、軽微な構造改善を直接適用。所見は以下のとおり:

| 観点 | チェック結果 | 対応 |
|---|---|---|
| 直接原因の網羅性 | 旧版は「事前の Write 権限の設定漏れ」1 件のみで、システム側制約（仕様事実）と作業プロセス側欠落（プロセス事実）を分離していなかった。後段の §4・§5 が「Write 限定」に閉じる遠因となっていた | §3.1 を 3 項目（観察事実／仕様事実／プロセス事実）に再構成し直接適用 |
| Why Chain の論理整合性 | 旧版 Why 1〜4 は単線で進行していたが、実体は「プロセス側の漏れ」と「システム側の仕様」の合流原因。単線で書くと一方が他方を説明しているような誤読を招く | 分岐 A／B ＋ 共通根 C-1 構造に再構成（5-whys スキル「落とし穴 3」適用、F02-003 と同一形式） |
| 各 Why の証拠裏付けの十分性 | 旧版 Why 1〜4 は git コミットと作業計画書の参照は十分だが、「実行中に permission prompt を受け取れない」という制約の出所が公式ドキュメント未参照だった | 公式ドキュメント `code.claude.com/docs/en/permissions` および `code.claude.com/docs/en/sub-agents` への参照を追加（Why A-3、Why B-1、Why B-2、Why B-3） |
| 根本原因の特性（実行可能 / 再発防止可能 / 根本的 / 検証可能） | 旧版は「実行可能 ○／検証可能 ○」だが、「再発防止可能」が **Write 権限のみ** に閉じており、Edit / Bash / MCP / WebFetch / Agent 等の同根事象に届かなかった。実際 commit `afea8b8` で Bash 系の同根事象が確認されている | 根本原因記述を「あらゆるアクション種別」に抽象化し、対策セクションも「アクション列挙 → 照合 → 不足対処方針決定」という汎用フローに昇格 |
| 落とし穴 1（早すぎる停止） | 旧版 Why 4「初回実施だった」で停止しており、「初回」自体は改善不可。本来「初回実施だったから明文化されていなかった」だけでなく「明文化のための公式ドキュメント逆引きプロセスが未確立だった」まで掘る方が、対策が実行可能になる | Why A-4 を「公式ドキュメントから permission モデルを逆算して準備するプロセスが研究一巡目では未確立」に書き換え |
| 落とし穴 2（責任追及） | 該当なし。旧版・新版ともプロセス・システムに焦点 | — |
| 落とし穴 3（単一スレッド分析） | 旧版が該当。プロセス側／システム側の分岐を単線で記述していた | 分岐 A／B 構造に書き換え |
| 落とし穴 4（検証されていない仮定） | 旧版 Why 1 で「permission prompt を受け取れないため」を仮定として扱っていた箇所を、公式ドキュメント引用で事実化 | Why B-1 / B-2 で公式ドキュメント引用を追加 |

**総合判定:** 旧版は致命的な品質欠陥を含まないが、後段（§4 / §5）の射程を「Write のみ」に閉じる遠因となる構造的弱さがあった。本改訂で（a）直接原因の複数列挙化、（b）Why Chain の分岐構造化、（c）公式ドキュメント引用追加、（d）根本原因の抽象化、を直接適用し、§4 / §5 の再実施に備えた。

## 4. 同件調査

### 4.1 同件調査の観点と範囲設計

§3 で特定した根本原因は「sub-agent / background Agent は実行中に permission prompt 経由でユーザ応答を取り戻す手段を持たないため、事前 allow（または `permissionMode` 切替・hook 等）による準備が必須である」という外部制約に対する **事前準備プロセスの欠落** である。この構造から逆算すると、同件・類件の対象範囲は **「Write 権限」に閉じない**。

**同件調査の抽象観点（後続 Sonnet 担当者でも具体化可能なレベルで定義）:**

> permission system が事前 allow（または `permissionMode` 切替・hook・フォールバック等の代替手段）を要求する **あらゆる種別のアクション** が、sub-agent / background Agent / 並列実行コンテキストから発行され、未許可で拒否されたか、あるいは拒否されるリスクが顕在化した事象。

具体的に範囲に含まれるアクション種別（公式ドキュメント `code.claude.com/docs/en/permissions` の「Permission rule syntax」「Tool-specific permission rules」セクションから逆算）:

1. **Write / Edit**: ファイル書き込み・編集（gitignore 仕様の glob 指定）
2. **Bash**: 任意のシェルコマンド（組み込み read-only コマンド `ls`/`cat`/`head`/`tail`/`grep`/`find`/`wc`/`diff`/`stat`/`du`/`cd` 等は prompt 不要だが、`git show`/`git blame` 等は明示 allow が必要。process wrapper（timeout/time/nice/nohup/stdbuf/裸 xargs）は自動 strip されるが、`watch`/`setsid`/`ionice`/`flock`/`find -exec` 等は常に prompt）
3. **PowerShell**: 同様のパターン（Bash と同じシンタックス）
4. **MCP ツール**: `mcp__<server>__<tool>` 形式。サーバ単位 / ツール単位ワイルドカード可
5. **WebFetch**: `WebFetch(domain:<host>)` 形式
6. **Agent**: `Agent(<AgentName>)` 形式（subagent 起動許可制御）
7. **Read deny に該当するパス**: `Read(./.env)` 等の deny ルールに該当するパスへの読み取り

**調査の問い:**
- 各アクション種別について、本プロジェクトでの sub-agent / background 実行で permission 拒否事象が発生した／し得たか
- 既存の `permissions.allow` が当該アクションを事前カバーしているか、それとも対症療法的に追加されてきた経緯があるか

### 4.2 本プロジェクト内の同件・類件調査

**結果:**

| アクション種別 | 同件・類件の有無 | 根拠 |
|---|---|---|
| **Write** | **本件**（同件）| コミット `a756e7e`（2026-05-03）で `Write(research-for-local-RAG-for-cc/**)` を追加、コミット `6f0080c`（2026-05-04）で `Write(research-for-*/**)` にグロブ拡張 |
| **Edit** | **類件（潜在）** | コミット `6f0080c` で `Edit(research-for-*/**)` を Write と同時追加。Edit 単独での処理中断事象は git log 上は確認できないが、Write と同根のため事前的に同時追加されたと解釈できる（コミットメッセージ「settings.json の Write/Edit 権限をグロブ化し」） |
| **Bash（読み取り系）** | **類件（顕在）** | コミット `afea8b8`（2026-05-06）で `cd:*` / `git show:*` / `git blame:*` / `wc:*` / `pwd` を追加。コミットメッセージ「並列 Agent 実行時に cd / git show / git blame / wc 等で permission prompt が多発する事象への対応」と明記。**F02-001 と完全同型の事象** が事前 allow 不足で再発した実例 |
| **Bash（書き込み系）** | 顕在せず（ガード意図あり）| コミット `afea8b8` メッセージ「書き込み系（push/reset/commit 等）は引き続き確認必須とする」のとおり、敢えて allow に含めない方針が採られた。これらは sub-agent / background から実行する想定がないため発生していない |
| **MCP（github）** | 類件（事前的対応）| コミット `6f0080c` で `mcp__github__search_repositories` 等 6 件を追加。フェーズ 02 の GitHub MCP 利用前に事前的に追加された。事前列挙ベースで対応できた成功例だが、利用ツールが増えた場合は同根事象が再発しうる |
| **WebFetch** | 類件（事前的対応）| `settings.json` 初期から `code.claude.com` / `docs.claude.com` / `github.com/anthropics` の 3 ドメインのみ allow。本タスクで permission 公式ドキュメントを参照するために `code.claude.com` がカバーしていたから問題なかったが、新規ドメイン参照時は事前 allow が必要 |
| **Agent** | 顕在せず | `Agent(...)` rules を deny / allow 配置していない（既定で全許可状態）。将来「特定 subagent のみ許可」運用に切り替える場合に同根事象が顕在化しうる |
| **Read deny 該当パス** | 顕在せず | `.env` / `secrets/**` / `.aws/credentials` / `.ssh/**` を deny 済み。sub-agent から該当パス読み取りが発生していない |

**ハマりどころ.md への記録:** background Agent / sub-agent の権限制約に関するエントリは `ハマりどころ.md` に記載されていない（2026-05-06 時点での全文検索で確認）。**Write 単独でも、Bash 系（commit `afea8b8`）でも、ハマりどころへの記録が後追いされておらず、同根事象が一度起きたあとも知識化されないまま再発している構造** が確認できる。

### 4.3 他プロジェクト（research-for-xxx）の調査

本ワークスペース内の現時点での調査プロジェクトは `research-for-local-RAG-for-cc/` のみであり、他の `research-for-xxx/` フォルダは存在しない（2026-05-06 時点）。ただし、ルート `settings.json` のグロブ `Write(research-for-*/**)` / `Edit(research-for-*/**)` は将来追加されるプロジェクトにも適用されるため、Write/Edit 限定では次期プロジェクトで同件は発生しない見込み。一方、Bash 系・MCP 系・WebFetch 系・Agent 系は（本プロジェクトで蓄積された allow が）次期プロジェクトでも機能するが、新たなツール（プロジェクト固有 MCP サーバ等）が追加された際には同根事象が再発しうる。

### 4.4 同件調査の総合所見

- **同件・類件は単発でなく、構造的に発生し続けている**: Write（2026-05-03）→ Edit（2026-05-04 事前追加）→ Bash 読み取り系（2026-05-06）と、いずれも「事前列挙の漏れ」または「対症療法的な追加」というパターンで処理されてきた。`permissions.allow` の所要量は調査の進行とともに増えるため、「列挙して固定」ではなく「列挙→検出→拡張」のループ運用が必要であることが §4 全体から導出される
- **対策方針への含意**: §5 で再構成する案では、（a）事前列挙を続ける案だけでなく、（b）拒否検出ベースの自動拡張ワークフロー、（c）`permissionMode` 切替によるそもそも prompt 不要化、（d）PreToolUse hook による動的判定、を選択肢に含めるべき
- **網羅性の限界の証拠**: Write/Edit を事前追加した 2026-05-04 時点でも、Bash 系の漏れが 2026-05-06 に発覚した事実は「事前列挙の網羅性は経験的に積み上がるしかなく、初期段階で完全列挙は困難」という性質を直接示している

## 5. 再発防止策

§3.2 の対策セクションおよび §4.4 の所見を踏まえ、再発防止策を「根本（本質的対応）」「暫定（対処療法的対応）」の 2 区分で整理する。**§4.4 で確認された網羅性の限界を踏まえ、「事前列挙ベース」案だけでなく「検出ベース」「フォールバック」「`permissionMode` 切替」を含めて並列に評価する**。

**Cons 列の必須評価軸（§4.4 所見を反映）:**
- **実現可能性 = 網羅性確保**: その案単独で、本プロジェクトの sub-agent / background が発行しうるアクションを必要十分にカバーできるか（カバー漏れ時の手戻り発生可否）
- **配置先・運用面の懸念**: ファイル配置先・参照タイミング・記載コスト等

### 5.1 再発防止策一覧

| # | 対応区分 | 推奨 | 内容 | Pros. | Cons.（必須評価軸: 実現可能性 = 網羅性確保 ＋ 運用面懸念） |
| -- | -- | -- | :-- | :-- | :-- |
| 1 | 根本 | 推奨 | **着手前チェックリスト方式（事前列挙）**: sub-agent / background Agent を起動する作業の着手前に、「発行されうるアクションを Write/Edit/Bash/MCP/WebFetch/Agent 別に列挙 → 既存 `permissions.allow` と照合 → 不足分への対処方針（allow 追加 / `permissionMode` 切替 / hook / 案 2〜4 への切り替え）を決定」する 3 ステップを CLAUDE.md または `.claude/rules/` に明文化。`ハマりどころ.md` にも本プロジェクト固有の落とし穴として記録 | 「列挙する」習慣自体が漏れ削減に効く／既存資産（`ハマりどころ.md` 参照ルール、CLAUDE.md 「Agent 活用ガイドライン」節）に追記する形で実装可能／新規プロジェクトに自然に伝搬（CLAUDE.md は全プロジェクト共通ロード） | **網羅性確保: 中** — 列挙の網羅性は実施者の知識に依存し、未経験のアクション種別（プロジェクト固有 MCP サーバ・カスタム subagent 等）は漏れる構造が残る。`afea8b8` のように一度認識されないと表面化しない長尾事象は事前列挙では抑止しきれない／本案単独では §4.4 の「列挙→検出→拡張」ループの「列挙」部しか担保できない |
| 2 | 根本 | 推奨 | **検出ベースの拡張ワークフロー（拒否時のリカバリ手順を運用化）**: sub-agent / background 実行中に permission 拒否で中断した場合の **標準復旧手順** を明文化。「拒否されたアクションを `settings.json` に追加 → 該当箇所だけリトライ（全 Agent 再起動を避ける）→ `ハマりどころ.md` に追記」のフローを定義。可能なら拒否ログから自動的に追加候補を提示するスクリプト（PreToolUse hook ベース）を整備 | 事前列挙の漏れを **拒否事象を検出して即座に拡張** することで吸収できる／長尾事象に対する受け皿になる／拒否経験が `ハマりどころ.md` に蓄積される自然なループが形成される | **網羅性確保: 高（事後的に）** — 事前網羅は不要、検出後に拡張するため理論上は全アクション種別をカバー可能／**運用面: 中** — 拒否発生時に再起動コストが完全にゼロにはならない（拒否時点までの作業は無駄になる場合がある）／hook 自動化までは初期コストが高い |
| 3 | 根本 | - | **`permissionMode` 切替によるそもそも prompt 不要化**: sub-agent frontmatter で `permissionMode: bypassPermissions`（または `acceptEdits` / `auto`）を設定し、prompt そのものを発生させない。`bypassPermissions` は危険のため、特定 subagent（独立 sandbox 内で動かすもの）に限定的に適用。デフォルトは `auto`（背景 classifier 評価）を検討 | 事前列挙不要／実行中の拒否そのものが発生しない／公式に提供されている仕組みを使うため独自実装が不要 | **網羅性確保: 高** — モード次第で全アクションをスキップ可能／**運用面: 高リスク** — `bypassPermissions` は「`.git` / `.claude` / `.vscode` 等の保護対象 ディレクトリへの書き込みも許可」され、誤操作・プロンプトインジェクション耐性が著しく低下（公式ドキュメントの Warning）。`auto` モードは現状 research preview。本プロジェクトの security 方針（deny に `.env` 等を明示）と相性が悪く、deny ルールのうち `bypassPermissions` 配下では一部しか機能しない場合がある／`acceptEdits` は Edit 系のみ自動承認で Bash 系等はカバーしない |
| 4 | 根本 | - | **PreToolUse hook によるカスタム判定**: hook 内で「sub-agent からの呼び出しなら所定 allowlist と照合し、不足分は記録した上で許可 / 拒否」というロジックを実装。許可した内容を後で `settings.json` に反映する自動拡張ワークフローへ統合 | 事前列挙と検出ベースのハイブリッドが実装可能／プロジェクト固有のセキュリティポリシーを柔軟に表現可能／拒否ログを構造化データとして蓄積できる | **網羅性確保: 高（実装次第）** — hook ロジック次第で柔軟に対応可能／**運用面: 高コスト** — hook 実装・テスト・メンテのコストが本プロジェクト規模に対して過剰。研究フェーズより本格運用フェーズ向き／hook の挙動確認自体に時間を要する／本プロジェクト現状では未使用（`SessionStart` の `git status --short` のみ） |
| 5 | 暫定 | 推奨 | **`settings.json` の現状（グロブ済み）維持＋ `.claude/rules/agent-permission-runtime.md`（新規）への落とし穴記録**: コミット `6f0080c` / `afea8b8` で蓄積された allow ルールを維持し、background Agent / sub-agent の権限制約を `.claude/rules/agent-permission-runtime.md` に新規エントリとして追記。本要改善点はワークスペース横断スコープのため `ハマりどころ.md`（本プロジェクト固有）ではなく `.claude/rules/`（path-scoped rule）配下が適切。`.claude/rules/agent-permission-runtime.md` は Agent 関連作業時にロードされる範囲を `paths:` で限定 | 即効性が高い／公式の path-scoped rule 仕組みに乗る（v3.0α-r1 で確立した方針と整合）／全プロジェクト横断で機能（新規 `research-for-xxx/` でも自動適用）／追加コストは記録 1 件のみ／案 1〜4 の本格実装までの繋ぎとして機能 | **網羅性確保: 中** — 既知の落とし穴は記録されるが、未経験事象は捕まえられない（本プロジェクトでも Write→Bash の二段で発覚した経緯）／単独では案 1〜4 の代替にはならない |
| 6 | 暫定 | - | **新規プロジェクト雛型への既定 allow 同梱**: 新規 `research-for-xxx/` 開始時に `settings.json` 雛型へ Write/Edit/読み取り Bash 群/汎用 MCP を既定エントリとして含める | プロジェクト初期化時の漏れを構造的に防げる／本プロジェクトで蓄積した allow が他プロジェクトに自動伝搬 | **網羅性確保: 限定的** — 既知のアクション種別の伝搬には有効だが、プロジェクト固有のツール（プロジェクト固有 MCP・カスタム subagent 等）は雛型では予見できない／案 1〜2 と組み合わせないと長尾事象を捕まえられない |
| 7 | 暫定 | - | **拒否時のフォールバック設計（並列度を抑える）**: 並列 sub-agent 実行で拒否が起きた場合、`/orchestrate` パターン A の並列度を 1 に落として直列リトライする運用。並列度 1 ならメインセッションで対話的 prompt 応答が機能する | 公式仕様（メインセッション = 対話的 prompt 可）を活用するため追加実装不要／案 2 の検出機構が無くても運用可能 | **網羅性確保: 高（最終手段として）** — 並列度 1 ならアクション種別を問わず prompt 経由で復旧可能／**運用面: 並列性能の喪失** — フェーズ 02 のパターン A（Sonnet 8 並列）の並列性能（コスト・時間効率）が失われるため恒常運用には不適。緊急時フォールバック専用 |

### 5.2 採用案

§4.4 で確認された「列挙→検出→拡張ループの必要性」を踏まえ、**単一案で網羅性を確保することは構造的に困難**。作業指示者判断（2026-05-06）により、以下の **二段階採用** で進める:

#### 5.2.1 本調査活動中の暫定対処（即時運用）

- **検知ベースの対処療法を継続**（実質的に案 2 のミニマル実装）: sub-agent / background 実行で permission 拒否が発生した場合、その都度 `settings.json` に追加して再実行する運用を継続。コミット `a756e7e` / `6f0080c` / `afea8b8` で実施してきた手法をそのまま踏襲
- 銀の弾丸的な対応策の有無を作業指示者の判断前に確認した結果、**`auto` モードがプラン要件**（Max / Team / Enterprise / API）**を満たす場合に唯一の銀の弾丸候補となるが、利用プランが Pro のため対象外**。それ以外の公式機能（`acceptEdits` / `bypassPermissions` / PreToolUse hook 等）はいずれも本プロジェクトの security 方針との相性または部分カバーの問題で銀の弾丸とならない
- 本調査活動中はこの対処療法で大きな支障が出ないと判断（§4.4 で確認したとおり、事前列挙の網羅性は経験的に積み上がる構造のため、検知ベースの追加対応で実用上は十分）

#### 5.2.2 本格対処（クロージング時判断）

§4.4 の所見を踏まえ、以下の **多層防御** をクロージング時に最終判断する:

1. **案 1（事前列挙チェックリスト）** + **案 5（落とし穴記録）** を `.claude/rules/agent-permission-runtime.md`（新規・横断スコープ）に統合配置。「着手前に列挙 → 既存 allow と照合 → 不足分への対処方針決定」の 3 ステップ明文化と、既知の落とし穴・公式仕様（permission modes / Bash 組み込み read-only / process wrapper strip / Read & Edit gitignore 仕様 / sub-agent 継承挙動）の集約を同一ファイルで実施
2. **案 2（検出ベースの拡張ワークフロー）** を運用ルール化し、拒否発生時のリトライ手順と `.claude/rules/agent-permission-runtime.md` への追記フローを標準化（hook 自動化は後フェーズ）
3. **案 6（雛型同梱）** は次期プロジェクト開始時に同時実施
4. **案 3（`permissionMode` 切替）** は本プロジェクトの security 方針（deny ルール明示）と相性が悪いため非推奨
5. **案 4（PreToolUse hook）** は研究フェーズではコスト過剰
6. **案 7（並列度低下フォールバック）** は緊急時のみ

これにより、（a）事前列挙で大半のアクションをカバー、（b）漏れた長尾事象は検出ベースで吸収、（c）`.claude/rules/agent-permission-runtime.md` に経験を蓄積（path-scoped rule なので Agent 関連作業時のみロードされ context 効率も良い）、（d）次期プロジェクトに伝搬、という多層防御が成立する。

#### 5.2.3 記載先選定の根拠

`ハマりどころ.md` ではなく `.claude/rules/agent-permission-runtime.md` を選択した理由:

- `ハマりどころ.md` は **本調査活動（local-RAG-for-cc）固有のハマりどころ集約** という位置付け
- 本要改善点は **Claude を利用した活動全般（横断スコープ）** の課題（要改善点一覧本紙でも「横断」と分類済み）
- 公式仕様の `.claude/rules/` 配下に path-scoped rule として配置すれば、`paths:` で Agent 関連作業時のみロードされ、context 効率も担保される（v3.0α-r1 で確立した方針と整合）

## 6. 特記事項/補足事項

- コミット `6f0080c` の対応（`Write(research-for-*/**)` のグロブ化と `Edit(research-for-*/**)` の追加）および `afea8b8` の対応（読み取り系 Bash 群追加）は、いずれも「F02-001 対応（広義）」と位置付けられる暫定修正であり、根本的な防止策（明文化・チェックリスト化・検出ベース運用）は未着手のまま。
- background Agent / sub-agent が `permissions.allow` なしに permission prompt 経由で実行中復旧できない制約は Claude Code の仕様（公式ドキュメント `code.claude.com/docs/en/permissions` および `code.claude.com/docs/en/sub-agents`）であり、変更不能。再発防止はプロセス側（事前確認の仕組み化＋検出ベースの拡張運用）でのみ実現可能。
- `Edit` 権限についても同様の懸念があり、Write と同一の根本原因を持つため同一チケット（本件）で管理する。Bash 系 / MCP 系 / WebFetch 系 / Agent 系も同根のため、§4 で範囲拡張済み。
- §4 の調査より、`ハマりどころ.md` にこの落とし穴が未記載であることが判明した。§5 案 5（推奨）の実施時に合わせて追記することを推奨する。
- 本要改善点はスコープ「横断」として扱い、解決策確定後はルート CLAUDE.md または `.claude/rules/` への昇格を検討する。
- **公式 read-only 既定認識の発見と `afea8b8` 重複疑義（保留事項、クロージング時に再検証）**: 公式ドキュメント `code.claude.com/docs/en/permissions` の "Read-only commands" セクションに「Claude Code recognizes a built-in set of Bash commands as read-only and runs them without a permission prompt **in every mode**. These include `ls`, `cat`, `head`, `tail`, `grep`, `find`, `wc`, `diff`, `stat`, `du`, `cd`, and read-only forms of `git`」と明記されている。これによれば、コミット `afea8b8` で `settings.json` に追加した `Bash(cd:*)` / `Bash(pwd)` / `Bash(wc:*)` / `Bash(git show:*)` / `Bash(git blame:*)` は **本来 prompt 不要** の組み込み read-only 集合に含まれる可能性が高い。しかし実運用では当時 permission prompt が発生した（推定原因: ワンライナーで複数コマンドを連結した形式 / Bash ツールを経由しない形式 / 引数パターンが組み込み判定から外れた、等）。**本格対処時に当時の prompt 発生条件を特定し、追加した allow エントリの一部が冗長であれば整理する**。
- **利用プラン Pro による `auto` モード非適用の記録**: 公式の `auto` モードは「未許可アクションを classifier が判定して自動承認」する仕組みで、本要改善点に対する銀の弾丸候補となりうるが、**Max / Team / Enterprise / API プラン限定**（Anthropic API プロバイダのみ）であり、利用プラン Pro では使えない。プラン変更があれば再評価する。
- **本要改善点のなぜなぜ分析プロセス自体に対する改善観点**は F02-013 として分離起票（5-whys スキル本体・別紙雛型・委任プロンプトの構造的改善検討）。クロージング時に F02-013 と合わせて判断する。
- **本格対処の中核実装ログ（2026-05-07、Opus Agent 委任）**: §5.2 多層防御の案 1 + 案 2 + 案 5 を統合配置した path-scoped rule `.claude/rules/agent-permission-runtime.md`（149 行）を新規作成済み。frontmatter `paths:` は Agent 起動を計画/実行する作業に関わるファイル群（`**/.claude/agents/*.md` / `**/作業計画書*.md` / `**/v3_作業計画書*.md` / `**/.claude/skills/*/SKILL.md`）を初期ターゲットとし、運用フィードバックで調整余地ある旨を本文に明記。本ファイル本体は F02-001 §3.2 / §5 を仕様参照元、cross-review-runtime.md（v3.0α-r1）を構造参考、公式ドキュメント（permissions / permission-modes / sub-agents）を要点出典として整備
- **権限観察モード採用結果（2026-05-07）**: 本ファイル作成時に意図的に事前権限付与を行わず（観察モード）、発生する権限拒否を実証データとして収集する方針を採った。**結果として権限拒否は発生せず**。Opus Agent の委任実行（メインセッションを介した sub-agent 起動）では `Write(.claude/rules/...)` が既存 allow `Write(research-for-*/**)` の対象外であったが、メインセッションが対話的 prompt を受けられる挙動下では問題なく通過した。これは F02-001 §3.2 Why B-1（sub-agent / background は実行中 prompt 経由の復帰不可）と公式 sub-agents ドキュメントの「parent から interactive permission prompt 経由で承認を得られる場合」の挙動と整合する観察結果。**ただし本観察は「メインセッション経由 Agent 委任」のケースであり、background Agent 並列起動（フェーズ 02 §5.4 パターン A 相当）の場合は依然として事前 allow が必要である点に留意**。両ケースの差異は §4.4 同件調査の補足データとしてクロージング時に再評価対象。**追加観察（2026-05-07 作業指示者補足）**: 作業指示者は本タスク実行中、Claude Code の **Remote Control 設定を有効にしてスマホ Claude アプリから作業指示** していた。Agent 起動中に発生した permission prompt をスマホアプリ経由で承認していた事実が事後に共有された。つまり Agent 側からは「拒否されずに通過」した形だが、実態は **メインセッション → Remote Control → スマホアプリ → ユーザー承認** という prompt 中継経路が機能した結果である可能性が高い。これは F02-001 §3.2 Why B-1（sub-agent / background は実行中 prompt 経由の復帰不可）に対する **重要な補足観察**: Remote Control 有効化下では、メインセッション経由の Agent 起動（Task ツール経由）における permission prompt がアプリ経由で承認可能。**ただし、フェーズ 02 §5.4 の background Agent 並列起動（パターン A 相当、メインセッションから切り離された background 実行）で同様に機能するかは別途検証が必要**。Remote Control の Agent permission 承認挙動は、F02-001 採用案の本格対処方針（特に案 1 事前列挙チェックリスト）に対する第三の選択肢（Remote Control 有効化を運用前提とすれば事前列挙のカバレッジ要件が緩和される可能性）として、クロージング時に再評価対象とする。**発生 prompt 件数の実証（2026-05-07 追加共有）**: Remote Control 経由で承認された permission prompt は **計 3 件** 発生していた事実が、作業指示者のスマホアプリタイムラインで確認された。各 prompt の具体内容（コマンド・ツール・パス・引数等）はスマホ Claude アプリの仕様上テキストコピーが不可のため、本時点でのセッション連携は不可。詳細データは後日スクリーンショット等での連携が可能となれば §4.4 同件調査の追加実証データとして反映予定。なお、件数 3 件という事実だけでも、案 1 事前列挙チェックリストの完全網羅が構造的に困難である（§4.4 で確認済み）ことの追加実証として意義がある: 本タスク（rule ファイル作成 1 件 + セルフレビュー）という比較的シンプルな作業でも 3 件の prompt が発生したため、より複雑な作業（フェーズ 02 §5.4 並列 8 本起動相当）では事前列挙の漏れが量的に拡大することが見込まれる。**副次観察**: スマホ Claude アプリの permission prompt 履歴はテキストコピー不可という仕様も、後続の同種挙動観察時の参考情報として記録

---

## 変更履歴

- 2026-05-06: 初版作成（Claude Sonnet 4.6、5-whys スキル適用）
- 2026-05-06: §3 Opus による品質チェック実施 + §4・§5 を Opus 再実施（観点抽象化・実現可能性観点追加）。§3.1 を 3 項目に再構成、§3.2 Why Chain を分岐ツリー化（プロセス側 A／システム側 B ＋ 共通根 C-1）、公式ドキュメント引用追加、§3.2 末尾にレビューア所見を追記。§4 を「permission system が事前 allow を要求するあらゆる種別のアクション」に観点抽象化し、Write 限定から Bash/MCP/WebFetch/Agent 等まで範囲拡張。§5 を全面書き直しし、Cons 列に「実現可能性 = 網羅性確保」を必須評価軸として明記、検出ベース・フォールバック・`permissionMode` 切替・hook 等を選択肢に追加、§5.2 で推奨組み合わせを提示。§1.2 ステータスを「未対処」→「分析中」に更新（Claude Opus 4.7）
- 2026-05-06: 作業指示者判断により採用案を確定。§1.2 ステータスを「分析中」→「対処中（暫定対処継続・本格対処はクロージング時判断）」、採用案列を二段階採用（暫定: 検知ベース対処療法継続 / 本格対処: §5.2 多層防御を `.claude/rules/agent-permission-runtime.md` に集約、クロージング時判断）に更新。§5.1 案 5 の記載先を `ハマりどころ.md`（プロジェクト固有）から `.claude/rules/agent-permission-runtime.md`（横断スコープ）に変更。§5.2 を「採用案」節に書き換え、§5.2.3 で記載先選定の根拠を明示。§6 特記事項に「公式 read-only 既定認識の発見と `afea8b8` 重複疑義の保留」「利用プラン Pro による `auto` モード非適用」「F02-013 への派生分離」を追記
- 2026-05-07: 本格対処の中核を先行実装。§5.2 多層防御の案 1 + 案 2 + 案 5 を統合配置した path-scoped rule `.claude/rules/agent-permission-runtime.md`（149 行）を Opus Agent 委任で新規作成（セルフレビュー前半 2 巡 + 後半 2 巡で IMPORTANT 4 件検出・反映済み）。§1.2 ステータスを「対処中（暫定対処継続・本格対処はクロージング時判断）」→「対処中（本格対処の中核実装済み・残部=案 6 雛型同梱はクロージング時判断）」、採用案列を実装済み旨に更新。§6 特記事項に実装ログと権限観察モード採用結果（権限拒否は発生せず、メインセッション経由 Agent 委任では問題なく通過したが background 並列の場合は依然事前 allow 必要との留意点）を追記。クロージング時の効果分析と正式採用判断対象として記録
- 2026-05-07: §6 特記事項「権限観察モード採用結果」段落の末尾に、作業指示者からの追加共有（Remote Control 有効化下のスマホ Claude アプリで Agent permission prompt を承認していた事実）を反映。これが F02-001 §3.2 Why B-1 への重要な補足観察となり、本格対処方針に Remote Control 有効化を前提とした第三の選択肢が追加で浮上したため、クロージング時の再評価対象として記録
