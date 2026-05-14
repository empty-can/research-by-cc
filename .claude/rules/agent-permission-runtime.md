---
paths:
  - "**/.claude/agents/*.md"
  - "**/作業計画書*.md"
  - "**/v3_作業計画書*.md"
  - "**/.claude/skills/*/SKILL.md"
---

# Agent 実行時の permission 事前準備運用ルール（F02-001 派生・横断スコープ）

sub-agent / background Agent を起動する作業に関わるファイル（agent 定義・作業計画書・SKILL.md 等）を読み書きする際に自動ロードされる path-scoped rule。F02-001（background Agent の Write 権限設定漏れ）§5.2.2 採用案の **本格対処の中核実装** であり、`.claude/skills/cross-review/`（v3.0α-r3、Skill 構造）と並ぶ横断スコープの仕組みとして位置付ける。

> **採用案ステータス**: F02-001 §5.2 にて **暫定対処（検知ベース対処療法継続）と本格対処（本ファイル＋多層防御）を二段階採用** と確定済。本格対処の最終運用は **クロージング時判断** 対象。本ファイルは中核実装として先行整備し、運用フィードバックを `paths:` 範囲・チェックリスト粒度に反映していく。
>
> **本ファイルの位置付け**: F02-001 §5.2.2 採用案の (1) 案 1 ＋ 案 5（事前列挙 ＋ 落とし穴記録）と (2) 案 2（検出ベース拡張ワークフロー）を統合配置する。雛型同梱（案 6）は新規プロジェクト開始時に別途実施。`permissionMode` 切替（案 3）/ PreToolUse hook（案 4）/ 並列度低下フォールバック（案 7）は本ファイルでは方針記述のみで実装スコープ外。

## 1. 着手前チェックリスト（事前列挙ステップ）

sub-agent / background Agent を起動する作業の着手前に、以下 3 ステップを実施する。Agent 委任を含む作業計画を立案するメインセッションが責任を持つ（subagent 自身がセルフチェックで吸収できる構造ではないため）。

### 1.1 列挙対象のアクション種別

公式の permission rule syntax（`code.claude.com/docs/en/permissions`「Tool-specific permission rules」）に対応する以下 8 種別を列挙対象とする。「発行されない」と判断できるならスキップしてよいが、判断根拠を計画上に明記する。

| # | 種別 | 確認観点 |
|---|---|---|
| 1 | **Write** | 新規ファイル作成・上書きが発生するパス（例: `Write(research-for-*/**)`） |
| 2 | **Edit** | 既存ファイル編集が発生するパス（Edit 系内蔵ツール全般に適用） |
| 3 | **Bash** | 実行するシェルコマンド（組み込み read-only に該当しない / 引数パターン依存のもの。§3.2 参照） |
| 4 | **PowerShell** | 同上の PowerShell 版（cmdlet エイリアス含む） |
| 5 | **MCP** | `mcp__<server>__<tool>` 単位。サーバ単位ワイルドカード `mcp__<server>__*` も可 |
| 6 | **WebFetch** | アクセスドメイン（`WebFetch(domain:<host>)` 形式） |
| 7 | **Agent** | subagent 起動（`Agent(<AgentName>)` 形式。deny で制限する運用なら確認必要） |
| 8 | **Read deny 該当パス** | 既存 deny ルール（`.env*` / `secrets/**` / `~/.aws/credentials` / `~/.ssh/**`）配下を読みに行かないか |

### 1.2 3 ステップ手順

1. **列挙**: 上記 8 種別について、当該作業で発行されうるアクションを具体例ベースで挙げる。複数 Agent を並列起動する場合（パターン A / C）は **各 Agent ごとに列挙**
2. **照合**: 既存 `permissions.allow`（チーム共有 `.claude/settings.json` ＋ 個人 `.claude/settings.local.json`）と突き合わせ、未カバーアクションを抽出
3. **不足対処方針決定**: §1.3 の選択肢から方針を決定。決定結果は計画書または着手チェック結果として残す（後続の振り返りで参照する）

### 1.3 不足対処方針の選択肢

| 選択肢 | 適用判断 |
|---|---|
| **(a) `permissions.allow` 追加** | 読み取り系（公式組み込み read-only 集合外の `git show` 等）、Write/Edit（`research-for-*/**` 等の作業ディレクトリ配下）、参照頻度の高い MCP / WebFetch ドメインが第一選択。チーム共有なら `.claude/settings.json`、個人ローカルなら `.claude/settings.local.json`。**破壊系（`git push` / `git reset` / `git commit` / `rm` 等）は追加しない** 方針（F02-001 §4.2 / `afea8b8` 同型）。詳細は §2.2 |
| **(b) `permissionMode` 切替** | subagent frontmatter で `acceptEdits` 指定（**ファイル編集 ＋ 一般 FS コマンド `mkdir`/`touch`/`rm`/`rmdir`/`mv`/`cp`/`sed` を作業ディレクトリ内で自動承認**）。`bypassPermissions` は `.git` / `.claude` 配下への書き込みまで通すため本プロジェクト方針と相性悪く非推奨。`auto` は利用プラン Pro では非適用（§3.1 参照） |
| **(c) PreToolUse hook** | 動的判定が必要かつ hook 実装コストを許容できる場合。**deny/ask 規則は hook の戻り値に関わらず優先評価される** ため、deny を覆す目的では使えない（公式 permissions ページ "Extend permissions with hooks" 節）。本プロジェクト現状では未使用（研究フェーズではコスト過剰） |
| **(d) フォールバック設計（並列度低下）** | 緊急時のみ。`/orchestrate` パターン A の並列度を 1 に落としメインセッションで対話的 prompt 応答に切り替える運用。並列性能を失うため恒常運用には不適 |

## 2. 検出ベースの拡張ワークフロー（拒否発生時の標準復旧）

事前列挙は経験的に積み上がる性質を持ち（F02-001 §4.4「事前列挙の網羅性は構造的に限界がある」所見）、長尾事象は実行時拒否で初めて顕在化する。発生時の標準復旧手順を以下に定める。

### 2.1 標準復旧手順

1. **拒否検出**: sub-agent / background 実行中に permission 拒否で中断した場合、**全 Agent 再起動を避け** 該当 Agent / 該当箇所のみリトライ準備に入る
2. **`settings.json` への追加判断**: §2.2 の基準に従い、追加先（共有 `.claude/settings.json` か 個人 `.claude/settings.local.json` か）と allow エントリを決定
3. **追加実施**: 決定したエントリを追加。書き込み系・破壊系を含める場合は作業指示者に確認する
4. **該当箇所リトライ**: 拒否で中断した箇所から再開（拒否時点までの作業をなるべく無駄にしない）
5. **本ファイル §3.6 への追記**: 既知の落とし穴として再発防止用に追記。条件（並列度・コマンド形態・引数パターン等）を可能な限り具体化

### 2.2 settings.json への追加判断基準

| 種類 | 追加可否 | 配置先 |
|---|---|---|
| 読み取り系 Bash（`git show:*` / `wc:*` / `cd:*` / `pwd` 等）| 積極的に追加 | チーム共有（再発防止のため） |
| Write/Edit（`research-for-*/**` 配下等）| 追加可 | チーム共有 |
| MCP 読み取り系・検索系 | 追加可 | チーム共有 |
| WebFetch（参照頻度高いドメイン）| 追加可 | チーム共有 |
| 書き込み系 Bash（`git push` / `git reset` / `git commit` / `rm` 等）| **追加しない**（明示確認方針）| — |
| 個人検証用の限定的 allow | 追加可 | 個人ローカル（`.gitignore` 対象） |

## 3. 落とし穴記録（公式仕様の要点と既知の挙動）

公式仕様要約。原典は引用 URL を参照。

### 3.1 permission modes（公式 `code.claude.com/docs/en/permission-modes`）

| モード | 概要 |
|---|---|
| `default` | 各ツール初回使用時に prompt。Reads は無条件許可 |
| `acceptEdits` | ファイル編集と一般 FS コマンド（`mkdir`/`touch`/`mv`/`cp`/`rm`/`rmdir`/`sed`）を作業ディレクトリ内で自動承認 |
| `plan` | Reads と read-only シェルのみ。ソース編集は不可 |
| `auto` | classifier がバックグラウンドで安全性チェック。**プラン要件: Max / Team / Enterprise / API（Pro 不可）+ Anthropic API プロバイダ限定 + 対応モデル限定**。research preview |
| `dontAsk` | 事前 allow 以外を auto-deny。CI 等で利用 |
| `bypassPermissions` | 全 prompt スキップ（`.git`/`.claude`/`.vscode`/`.idea`/`.husky` への書き込みも通過）。隔離環境専用 |

### 3.2 Bash の組み込み read-only 認識

公式 `code.claude.com/docs/en/permissions` の「Read-only commands」節:

> Claude Code recognizes a built-in set of Bash commands as read-only and runs them without a permission prompt **in every mode**.

組み込み集合: `ls` / `cat` / `head` / `tail` / `grep` / `find` / `wc` / `diff` / `stat` / `du` / `cd` / read-only forms of `git`。設定変更不可（prompt 強制したい場合は `ask` / `deny` ルールで上書き）。

> **保留事項（`afea8b8` 重複疑義、本格対処確定時に再検証）**: 上記組み込みに含まれる `cd` / `wc` / `git show` / `git blame` / `pwd` を 2026-05-06 commit `afea8b8` で `settings.json` に追加した。組み込み認識のはずだが実運用で prompt が発生した実績あり。**推定原因**: (a) ワンライナーで複数コマンド連結（`git show xxx | wc -l` 等）、(b) Bash ツール非経由の発行経路、(c) write-capable/exec-capable フラグを持つコマンド（`find`/`sort`/`sed`/`git`）と unquoted glob の組み合わせで read-only 判定から外れる挙動、(d) 引数パターン依存。クロージング時に当時の prompt 発生条件を特定し、追加した allow エントリの一部冗長性を整理する（重複削除可否の判断）。

### 3.3 process wrappers の自動 strip

公式 permissions ページ「Process wrappers」節より、Bash ルールマッチ前に **自動 strip される** ラッパー: `timeout` / `time` / `nice` / `nohup` / `stdbuf`。**裸の `xargs`** も strip（`xargs -n1` 等フラグ付きは strip されない）。

**自動 strip されない**（常に prompt するため `Bash(<wrapper> *)` 形式の prefix ルールでは承認できない）: `watch` / `setsid` / `ionice` / `flock`。`find -exec` / `find -delete` も `Bash(find *)` でカバーされない。承認したい場合は完全一致ルールを書く。`devbox run` / `npx` / `docker exec` 等は strip されないため `Bash(devbox run npm test)` のように内側コマンドを含めて記述する。

### 3.4 Read & Edit の gitignore 仕様（パス指定パターン）

公式 permissions ページ「Read and Edit」節より、4 形式:

| パターン | 意味 |
|---|---|
| `//path` | **絶対** パス（FS ルートから） |
| `~/path` | ホームディレクトリ起点 |
| `/path` | プロジェクトルート起点（**絶対パスではない点に注意**） |
| `path` / `./path` | カレントディレクトリ起点 |

`*` は単一ディレクトリ内マッチ、`**` は再帰マッチ。Windows パスは POSIX 化（`C:\Users\alice` → `/c/Users/alice`）。**Read/Edit deny は Bash サブプロセスには適用されない**（`Read(./.env)` deny は Bash の `cat .env` を防げない、OS レベルで防ぎたければ sandbox 利用）。

### 3.5 sub-agent の permission 継承挙動

公式 `code.claude.com/docs/en/sub-agents` の `permissionMode` 節 + `background` 節より:

- subagent は **メインセッションの permission context を継承** し、frontmatter `permissionMode` で独自モードに上書き可能
- 親優先となるケース: 親が `bypassPermissions` または `acceptEdits` の場合、これらは subagent frontmatter の `permissionMode` 指定より優先する
- 親 auto モード時の特殊挙動: subagent は auto モードを継承し、frontmatter `permissionMode` は **無視される**。classifier が parent と同じ block/allow 規則で各 tool call を再評価
- **background subagent の重要挙動**: 起動前に必要な tool 権限について **事前に prompt が出る**。起動後は事前承認分のみ動作し、未承認は **auto-deny**。clarifying questions の tool call は失敗するが subagent 自体は継続
- background が permission 不足で失敗した場合、**同タスクの foreground subagent を新規起動して対話 prompt 経由でリトライ可能**（緊急回避手段）
- plugin subagent では `permissionMode` / `hooks` / `mcpServers` 指定は無効

### 3.6 既知の落とし穴

- **`afea8b8` 重複疑義**（§3.2 と連動、保留事項）: 組み込み read-only 既定認識のはずの `cd` / `wc` / `git show` 等が実運用で prompt を出した。本格対処時に発生条件を特定し、冗長 allow を整理する
- **利用プラン Pro での `auto` モード非適用**: 本要改善点に対する潜在的銀の弾丸が利用プラン上の制約で適用不可。プラン変更時に再評価
- **`/orchestrate` パターン A 並列実行時の長尾事象**: F02-001 §4.4 のとおり、Write（2026-05-03）→ Edit（2026-05-04 事前追加）→ Bash 読み取り系（`afea8b8`）と段階的に表面化した。事前列挙だけでは捕まらない長尾を §2 検出ベースで吸収する設計
- **`bypassPermissions` の盲点**: `.git` / `.claude` / `.vscode` / `.idea` / `.husky` への書き込みも通過する。本プロジェクトの security 方針（deny 明示）と相性悪く非推奨
- **fork mode 時の特殊挙動**: fork 時は `background` フィールドに関係なく全 spawn が background 化し、permission は事前承認フローに乗る。`CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` で同期化可能

## 4. 関連バックログ・参照

- F02-001（本要改善点、§5.2.2 採用案の中核実装）: `research-for-local-RAG-for-cc/improvements/F02-001_background_Agent_Write権限設定漏れ.md`
- F02-013（なぜなぜ分析プロセス改善検討、F02-001 派生）
- 同種の path-scoped 自動ロード先例: `.claude/skills/cross-review/`（v3.0α-r3、Skill 構造）
- 公式ドキュメント: `code.claude.com/docs/en/permissions` / `code.claude.com/docs/en/permission-modes` / `code.claude.com/docs/en/sub-agents`
- 既存 settings: `.claude/settings.json`（チーム共有）/ `.claude/settings.local.json`（個人ローカル、`.gitignore` 対象）

> **`paths:` 調整方針**: 初期版は「Agent を起動する計画段階のファイル」「Agent 関連スキル」「Agent 並列実行が記述される計画書」をカバー。実運用フィードバックで以下を判断する: (a) 報告書執筆段階で本ルールが必要となる作業が発生したら `**/reports/**/*.md` 系の追加検討、(b) 過剰ロード（不要シーンでの context 消費）が観測されたら `paths:` を絞る、(c) cross-review-runtime.md と paths 重複領域がある場合の整理。

## 変更履歴

- 2026-05-07: 初版作成（Claude Opus 4.7、F02-001 §5.2.2 採用案の中核実装。案 1 + 案 2 + 案 5 を統合配置）
