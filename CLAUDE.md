# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリの役割

**Claude Code を使って各種テーマを調査するためのワークスペース**であり、製品コードを置く場所ではない。中身は大きく 2 種類:

1. **チーム共有の Claude Code 設定** (`.claude/`) — 全調査で共通利用する skills / agents / rules / output-styles / templates / settings.json
2. **個別調査フォルダ** (`research-for-xxx/`) — 調査テーマ単位のサブプロジェクト。テーマ固有の `.claude/` / `.mcp.json` / `CLAUDE.md` を任意で持てる

## 主要な慣習（複数ファイルにまたがるため明示）

### `research-for-xxx/CLAUDE.md` は遅延ロード
ルート直下の `CLAUDE.md`（このファイル）は毎セッション自動ロードされるが、`research-for-xxx/` 配下の `CLAUDE.md` は **そのフォルダの調査を指示された時に初めてロードする**。各調査の細かい背景・前提は個別 CLAUDE.md に書き、ルートには書かない。

### 個別調査フォルダの構造
新規テーマで `research-for-<テーマ>/` を切る時、その直下に置けるもの:

- `CLAUDE.md` — その調査の前提・目的・参照リソース（必須に近い）
- `.claude/` — そのテーマだけに必要な skill / 設定（必要なら）
- `.mcp.json` — そのテーマだけに必要な MCP サーバー（必要なら）
- `reports/` — **成果物の格納先**（後述）

共通で使う設定はルート `.claude/` に入れる（重複させない）。

### 成果物は `research-for-xxx/reports/<タスク名>/<フェーズ名>/` に置く
**ルート側に reports は持たない。**調査用フォルダ自体が作業スコープなので、各 `research-for-xxx/` の中に `reports/` を持つ。

**フォルダ階層（基本 2 階層）**:
1. `reports/<タスク名>/` — タスクは複数日にまたがるのが通常。
2. `reports/<タスク名>/<フェーズ名>/` — タスクを構成するフェーズごとに切る。

**フォルダ・ファイル命名規則**:
- **順序を示したい場合は数値プレフィックスを先頭に付ける**（例: `01.基礎調査/`, `01.調査A/`）。フォルダ・ファイルどちらも同じルール。
- **日付はファイル名の末尾に付ける**（先頭には付けない）。タスク・作業名でソートした方が辿りやすいため。
- 日付フォーマットは `YYYY-MM-DD`。
- 日付を付けてよいのは **同じ内容を複数回実施し、結果を別ファイルとして残したい場合のみ**（レビュー報告書の 1 回目 / 2 回目 など）。それ以外のファイルは **ファイル内に変更履歴を記載** することで作成日・更新日を表現する。
- フェーズ配下に複数の作業ファイルが混在する場合は、**ファイル名に作業を識別できる文字列を含める** ことで見通しを保つ。
- 親タスク違いで同名の作業が出る場合（例: フィジビリティ検証と有効性検証の双方に「パターンA 検証」がある）は、**親タスクを示す接頭辞をフォルダ／ファイル名に含めて区別する**（例: `01.検証_フィジビリティ_パターンA/`）。

**フェーズ配下にさらにサブフォルダを切ってよいケース**:
そのフォルダで作成するメインドキュメント以外に **付随ドキュメント（別紙・参考資料等）が存在する場合**。レビュー報告書のような作業単位の付随物は、ファイル名に作業を識別できる文字列を含める運用で十分。複数作業を横断する付随物として作る運用にできるなら、フェーズ階層に直置きを優先する。

例:
```
research-for-local-RAG-for-cc/
└── reports/
    ├── 01.基礎調査/
    │   ├── 01.調査A/
    │   │   ├── 調査報告書.md
    │   │   ├── クロスレビュー報告書_2026-05-02.md   ← 末尾に日付・複数回実施想定
    │   │   └── クロスレビュー報告書_2026-05-08.md
    │   ├── 02.調査B/
    │   │   └── 調査報告書.md
    │   └── 99.最終基礎調査報告/
    │       └── 報告書.md
    └── 03.フィジビリティ検証/
        └── 01.検証_フィジビリティ_パターンA/         ← 親タスク識別子を名前に含める
            └── 検証報告書.md
```

タスクをまたいで再利用するファイルは個別 `CLAUDE.md` で位置を明記する。

### 進捗マーカー
進捗を記載するファイル（各 `CLAUDE.md` のタスク進行状況など）では以下のマーカーを使う:
- `- [ ]` 未着手
- `- [x]` 完了
- 進行中・保留などの中間状態は `(進行中)` / `(保留: <理由>)` のような注記をタスク名の後に付ける

### Skill の追加は二段階フロー
新しい slash command を作りたい時は専用 skill 経由で進める:

1. `/request-new-skill <概要>` — `.claude/workspace/skill-request/<kebab-name>/` に作業フォルダと依頼書テンプレを生成
2. 依頼者が `skill-request-form.md` に要件を記入
3. `/review-skill-request [フォルダ名]` — Claude が依頼書をレビュー、`skill-cc-response.md` に質問・指摘・既存 Skill 調査結果・実装方針ドラフトを書き込む
4. 確認事項がクリアになったら実装へ

複雑な依頼は `/review-skill-request` 内部で `general-purpose` Agent (Opus) への委任を判断する。詳細は `.claude/skills/review-skill-request/SKILL.md`。

### 既存の skill / agent / output-style / template
| 種別 | 名前 | 用途 |
|---|---|---|
| skill | `commit-and-pr` | コミット → push → PR 作成を 1 メッセージで連続実行（`disable-model-invocation: true` で明示呼び出し限定） |
| skill | `orchestrate` | 複数 sub-agent を並列/順次協調させる。**メインセッションで呼ぶ前提**（subagent は subagent を spawn できない仕様への対応） |
| skill | `request-new-skill` / `review-skill-request` | 上記の skill 追加フロー |
| skill | `5-whys` | なぜなぜ分析（根本原因特定）。examples/ と references/ にサポートドキュメントあり |
| agent | `code-reviewer` | git diff ベースのレビュー。Sonnet 固定。大規模変更の後に主体的に呼んでよい |
| output-style | `code-review` | レビュー結果のフォーマット定義。CRITICAL / IMPORTANT / SUGGESTION / POSITIVE 4 段階 |
| template | `cross-review/` | クロスレビュー報告書の雛型 3 種（論理整合性 / 実用性 / 作業指示者レビュー）。`.claude/templates/cross-review/README.md` に運用方針 |

### path-scoped rule
`.claude/rules/coding-standards.md` は frontmatter の `paths:` で **コードファイル編集時のみロード**される。Markdown だけ触る作業ではロードされないので、コード規約をここに集約してコンテキスト消費を抑えている。プロジェクト固有の言語別規約を追加する場合は同ディレクトリに新ファイルを切る。

### 設定の階層
- `.claude/settings.json` — チーム共有・コミット対象
- `.claude/settings.local.json` — 個人ローカル・コミット対象外（`.example` をコピーして使う）

`settings.json` の `permissions.deny` で `.env*` / `secrets/**` / `~/.aws/credentials` / `~/.ssh/**` の読み取りをブロック済み。新たな機微パスが出たら **deny に追加してから扱う**。

### SessionStart hook
セッション開始時に `git status --short` が自動実行され、未コミット変更の有無を一覧表示する。新規 hook を足す時は Windows + macOS/Linux 両対応を意識する。

### 個別調査フォルダの README
`research-for-xxx/CLAUDE.md` は遅延ロードのため、調査の目的・背景・参照資料はここに集約する。`research-for-xxx/README.md` は **GitHub での閲覧者向けの公開ドキュメント**として、CLAUDE.md から公開向け情報を抽出して別途作成する（CLAUDE.md と README.md の二重管理を避けるため、README.md は CLAUDE.md の派生物として位置付け、本質的な情報の真の出所は CLAUDE.md とする）。

## Agent 活用ガイドライン

実作業の **計画時・実施時は本ガイドラインを必ず参照** する。判断基準と活用パターンを定め、メインセッションのコンテキストを「判断・調整・対話」に集中させる方針。

### Agent に委任すべきケース

以下のいずれかに該当するなら、原則 Agent へ委任する:

- **一定量以上のファイル読み込み・要約・整形**（先行インプット読込、長文ドキュメント要約 など）
- **大規模ファイルの生成・統合**（計画書・設計書・報告書の合成）
- **独立した複数の作業を並列で進めたい場合**（クロスレビュー、複数観点調査）
- **専門 Agent が用意されている領域**（`code-reviewer`、`Explore`、`Plan` 等）
- **作業の出力ファイル/結果をそのままレビュー対象にできるもの**

### Agent に委任すべきでないケース（メインセッションが直接実行）

以下のいずれかに該当するなら、メインセッションが直接実行する:

- **メインセッション自身が内容を読み込んで判断する必要がある作業** — 委任すると判断材料がメインに戻らない
- **数行〜小範囲の機械的編集**（タイポ修正、1ファイルのリネーム等） — Agent 起動オーバーヘッドが作業時間を上回る
- **探索的・反復的に次手を決める作業** — 委任すると文脈分断で期待と乖離する
- **メタ情報の更新**（タスク管理、進捗マーカー、変更履歴の小範囲追記）
- **ユーザーとの対話そのもの**（確認、要約、問い返し）
- **Agent 結果の検証コストが委任益を上回ると見込まれる作業**

判断に迷う場合の補助基準: 「**作業の出力ファイル/結果をそのままレビュー対象にできるか？**」が Yes なら委任、No なら直接実行を検討。

### 活用パターン

Agent 委任時の実行パターンは `/orchestrate` skill のパターン A/B/C を参照（本ガイドラインで重複定義しない）。

- **パターン A**: 並列調査 — 独立した複数トピックの同時調査
- **パターン B**: 段階的処理 — 前段の結果が次段の入力になる
- **パターン C**: 役割分担 — 大規模タスクを専門領域に分割

### モデル選定原則

委任する Agent のモデル、または **メインセッション直接実行時の使用モデル** は、作業性質に応じて以下の原則で選定する:

| 作業性質 | 推奨モデル |
|---|---|
| 機械的な情報抽出・要約・整形 | Sonnet |
| ファイル探索・パターン検索（多回反復） | Sonnet（または `Explore` agent） |
| 論理整合性レビュー・大規模統合・設計判断 | Opus |
| クロスレビューでの観点分担 | Opus と Sonnet を並列 |
| 専門 Agent が既定モデルを持つ場合 | 当該 Agent の規定モデル（例: `code-reviewer` は Sonnet 固定） |

**推奨理由の説明粒度**: 作業指示者は Opus / Sonnet / Haiku の一般的な特性を把握済み。各モデルの特性に沿った素直な推奨の場合、推奨理由は **割愛** する。各モデルの特性から一般的には採用されないモデルを推奨する場合（作業特性やコンテキスト状況から例外的な選定をする場合）にのみ、推奨理由を補足する。

### モデル切り替えルール

**Agent に委任すべきでないケース** で、上記モデル選定原則の推奨モデルが現在メインセッションで使用中のモデルと異なる場合:

- 作業指示者が指示時にモデル切り替えに言及していなければ、**Claude 側から作業指示者にモデル切り替えを依頼する**
- 切り替えが完了してから作業を実施する
- 「切り替え不要」と作業指示者が判断した場合は、その判断に従って実行する（明示的な合意があったことを応答に残す）

これは「Agent で別モデルを呼べない作業」を、メインセッションで非推奨モデルのまま実行することを防ぐためのガード。

## Anthropic 公式ドキュメント調査の手順（暫定ルール）

> **暫定運用**: 本ルールは本格的なローカル RAG 構築完了までの繋ぎ。本格 RAG 完成後は調査ルートが変わり、本ルールは更新または Skill 化される（`research-for-local-RAG-for-cc/improvements/C01-001` / `C01-003` 参照）。

Claude Code / Anthropic API / Claude Agent SDK 等の Anthropic 公式情報を調査する際は、以下の手順を踏む:

1. **セッション開始時に llms.txt をコンテキストに保持する**: 毎セッション開始時、`research-for-local-RAG-for-cc/resources/references/claude-code-llms.txt` を Read で読み込み、Anthropic 公式ドキュメントの全ページカタログをコンテキストに保持する
2. **調査時はローカル DL 済みファイルを優先する**: llms.txt から関連ページを特定した後、内容を確認する場合は以下のローカル DL 済みファイルを Grep / Read で参照する。WebFetch は基本的に使わない:
   - 全文: `research-for-local-RAG-for-cc/resources/references/claude-code-llms-full.txt`
   - 構造（見出し階層）: `research-for-local-RAG-for-cc/resources/references/claude_code_docs_map.md`
3. **WebFetch を使う条件**: ローカル DL 済みファイルでカバーされない情報（最新 whats-new で DL 未完のもの等）に限定する

**根拠**: WebFetch はネットワーク I/O + Anthropic 側レンダリング往復のコストが発生するが、ローカル Grep は実質ゼロコスト。同等の情報がローカルにある場合、ローカル参照がほぼ確実にローコスト。

**現スコープ**: `research-for-local-RAG-for-cc/resources/references/` 配下にしか llms.txt 群が存在しないため、**ローカル llms.txt + Grep 戦略は Anthropic 公式ドキュメント限定** で機能する。他公式ドキュメント（AWS / ライブラリ等）の調査経路は次節「外部情報源・経路選択ルール（暫定）」を参照。

## 外部情報源・経路選択ルール（暫定）

> **暫定運用**: C01-003（公式ドキュメント調査 Skill 化）完成までの繋ぎ。Skill 完成後は本ルールは Skill 内部の routing logic に吸収される。

### 情報源別の調査経路優先順位

外部情報を調査する際は、情報源に応じて以下の経路を **第一選択** とする。第一選択が失敗・不適合の場合のみフォールバックを使う。

| 情報源 | 第一選択 | フォールバック |
|---|---|---|
| Claude Code 公式 docs | ローカル llms.txt + Grep（前節「Anthropic 公式ドキュメント調査の手順」参照）| WebFetch |
| AWS 公式 docs | `mcp__awslabs__search_documentation` → `mcp__awslabs__read_documentation` / `read_sections` | WebFetch on `docs.aws.amazon.com` |
| ライブラリ docs（npm / PyPI / 言語標準ライブラリ等） | `mcp__context7__resolve-library-id` → `mcp__context7__query-docs` | WebFetch |
| 一般 web（上記以外） | WebFetch | — |

### ファイル操作・Web fetch の MCP vs built-in

ファイル操作と Web fetch は **built-in tools を第一選択** とする。MCP 版を使うのは「built-in に対して明確な優位性がある場面」に限定。

| 用途 | 第一選択（built-in）| MCP を使う条件 |
|---|---|---|
| ファイル読み書き・編集 | Read / Write / Edit | （MCP 不要、built-in で十分）|
| 複数ファイル一括読み込み | Read を複数回 | `mcp__filesystem__read_multiple_files` — ターン削減効果が顕著な時のみ |
| ディレクトリ階層俯瞰 | Glob `**/*` 等 | `mcp__filesystem__directory_tree` — JSON 構造化出力が必要な時のみ |
| ファイル / 内容検索 | Glob / Grep | （MCP 不要、built-in が高速）|
| ファイル移動・作成 | Bash `mv` / `mkdir` | （MCP 不要）|
| Web 取得 + 要約 | WebFetch | （MCP 不要）|
| 生 HTML / バイナリ / PDF 取得 | — | `mcp__fetch__fetch` — WebFetch は要約処理が入るため不向き |
| WebFetch がリダイレクト等で失敗 | — | `mcp__fetch__fetch` をフォールバックとして使用 |

## 環境特性

- **OS**: Windows 11（プライマリ） — bash シェル経由で操作。パスは `C:\cc-workspace\research-by-cc` 形式
- **Node.js v18+** — MCP サーバー起動用
- **MCP サーバー** — ルート `.mcp.json` は空。`anthropic-docs` / `context7` / `fetch` / `github` はユーザレベル（`~/.claude/`）で定義済み。テーマ固有の MCP は `research-for-xxx/.mcp.json` に追加する
- **GitHub MCP** — `GITHUB_TOKEN` 環境変数（OS レベル）が必要
- **Git** — Git 化済み・GitHub 公開済み。コミット運用は「Git 運用ルール」節を参照

## Git 運用ルール

本リポジトリは Git 化済み・GitHub 公開済み。Git 運用の意義と運用ルールを以下にまとめる。

### Git 運用の意義

- **差分レビューの効率化** — `git diff` で改訂前後の差分だけ読めばレビュー指摘の反映状況が確認でき、改訂版を全文再読する必要がなく、トークン・コンテキスト消費を抑えられる
- **時系列の意思決定ログ** — `git log` がそのままプロジェクトジャーナルになる。各 CLAUDE.md の「変更履歴」も Git 化以降は重複管理を避けて簡潔化してよい
- **過去版へのアクセス** — `git show <commit>:<path>` で過去のドラフトを参照でき、現状ファイルを汚さず振り返れる
- **安全網** — 誤削除・誤上書きから回復可能（`git reflog` まで含めれば実害をかなり抑えられる）
- **公開コラボレーション** — GitHub 公開済みのため、Issue / PR を通じた外部からの指摘・改善提案を受けられる

### `.gitignore` の方針

- **個人ローカル設定**（`.claude/settings.local.json` / `CLAUDE.local.md`）— ユーザ個別の権限・補足指示。共有しない
- **作業中の一時物**（`.claude/work/` / `.claude/workspace/` / `scratch/` / `*.tmp`）— 完了後に削除されるか、別途コミット対象に昇格させる
- **エージェントメモリのローカル分**（`.claude/agent-memory-local/`）— セッション固有
- **環境変数・機密情報**（`.env*`（`.env.example` 除く）/ `secrets/`）— `permissions.deny` との二重防御
- **言語別ビルド成果物**（`node_modules/` / `__pycache__/` 等）— research-for-xxx 配下で RAG 構築コードを実行する想定
- **IDE / OS** ローカル設定 — 個別環境依存

### コミット運用ルール

**コミット候補となるタイミング** — Claude は以下のタイミングで「コミット候補」として作業指示者に提案する:

- 個別調査フォルダ内のフェーズが完了したとき
- クロスレビュー報告書を作成・更新したとき
- 依頼者レビュー指摘を反映した改訂版を作成したとき
- 共通設定（`.claude/` 配下）の更新を完了したとき
- ルート CLAUDE.md / README.md の方針変更を反映したとき

**Claude による自動コミットの可否**:

- **Claude は成果物作成・更新時にコミット候補として依頼者に提案する。依頼者の明示承認を経て初めて commit 操作を実行する**（自動コミットはしない）
- 提案には「コミットメッセージ案」と「対象ファイル群」を含める
- `git add -A` / `git add .` は使用せず、対象ファイルを明示指定する

**コミットメッセージの方針**:

- 1 行目は `<種別>: <要約>` 形式（種別例: `feat`, `fix`, `docs`, `chore`, `refactor`, `review`）
- 本文（任意）には「なぜ」を中心に記載。「何を」は diff から読める
- レビュー反映コミットは `review: 〜への対応反映` のように明記

**SessionStart hook の活用**:

- セッション開始時の `git status --short` 出力で未コミット変更を確認
- 出力に未コミット項目がある場合、Claude は最初の応答で「未コミット変更の有無」と「直近のコミット候補にすべきか」を作業指示者に確認する

## よくある作業

| やりたいこと | 起点 |
|---|---|
| 既存調査の続き | `research-for-<テーマ>/CLAUDE.md` を読んでから着手 |
| 新規調査の開始 | `research-for-<新テーマ>/` を切り、`CLAUDE.md` と `reports/` を用意 |
| タスクの成果物作成 | `research-for-<テーマ>/reports/<タスク名>/` を切ってその中で完結させる |
| 共通 skill の追加 | `/request-new-skill` → `/review-skill-request` |
| 大規模変更後のレビュー | `code-reviewer` agent を呼ぶ（output-style: `code-review`） |
| 並列調査・段階処理 | `/orchestrate` を読んでパターン A/B/C を選ぶ |
