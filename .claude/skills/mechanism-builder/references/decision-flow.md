# 判断フロー詳細

CLAUDE.md / Rule / Skill の選定判断について、公式比較表と補完観点を集約した詳細リファレンス。

## 1. 公式の比較表

### 1.1 CLAUDE.md vs Rules vs Skills（`docs/en/features-overview` より）

| Aspect | CLAUDE.md | `.claude/rules/` | Skill |
|---|---|---|---|
| **Loads** | Every session | Every session, or when matching files are opened | On demand, when invoked or relevant |
| **Scope** | Whole project | Can be scoped to file paths | Task-specific |
| **Best for** | Core conventions and build commands | Language-specific or directory-specific guidelines | Reference material, repeatable workflows |

公式ガイダンス:
- **CLAUDE.md**: 毎セッション必要な指示（ビルドコマンド・テスト規約・プロジェクト構造）
- **Rules**: CLAUDE.md を肥大化させずに整理する手段。`paths:` 付き Rule は対象ファイル編集時のみロード
- **Skills**: 「時々必要」な参照資料・`/<name>` で起動するワークフロー

### 1.2 CLAUDE.md vs Skill（同セクションより、コマンド実行可能性が明示）

| Aspect | CLAUDE.md | Skill |
|---|---|---|
| **Loads** | Every session, automatically | On demand |
| **Can include files** | Yes, with `@path` imports | Yes, with `@path` imports |
| **Can trigger workflows** | **No** | **Yes, with `/<name>`** |
| **Best for** | "Always do X" rules | Reference material, invocable workflows |

→ **「コマンド実行可能性」は Skill 固有の利点として公式に明示** されている。

### 1.3 Output Styles vs Skills（`docs/en/output-styles` より）

> Output styles modify how Claude responds (formatting, tone, structure) and are always active once selected. Skills are task-specific prompts that you invoke with `/skill-name` or that Claude loads automatically when relevant.

- **Output Styles**: Claude の応答の仕方（フォーマット・トーン・構造）を**常時**変更。`/config` で選択
- **Skills**: タスク固有のプロンプト。必要時のみロード

→ レビュー報告書のような「ファイル成果物の雛型」は **Output Styles ではなく Skill の templates/** に置くのが公式設計。

### 1.4 Skill vs Subagent

| Aspect | Skill | Subagent |
|---|---|---|
| **What it is** | Reusable instructions, knowledge, or workflows | Isolated worker with its own context |
| **Best for** | Reference material, invocable workflows | Tasks that read many files, parallel work |
| **Context** | Adds to main window | Separate window |

→ Skill は「メイン会話で使う再利用可能な指示」。Subagent は「独立コンテキストで作業を委任する worker」。

## 2. 公式の「Build your setup over time」フロー

`docs/en/features-overview` より、トリガーから機構を選ぶフロー:

| トリガー | 追加すべき機構 |
|---|---|
| Claude が convention や command を 2 回間違える | CLAUDE.md に追記 |
| 同じプロンプトを繰り返し打っている | user-invocable な Skill 化 |
| 同じプレイブック・多段手順を 3 回目以上ペーストしている | Skill 化 |
| 副タスクが会話を圧迫している | Subagent にルーティング |
| 毎回必ず実行させたいことがある | Hook を書く |

CLAUDE.md が 200 行を超えそうなら、Rule か Skill に分離する（同ページ「Rule of thumb」）。

### 2.1 Hook を選ぶケース（第 4 の機構）

Hook は CLAUDE.md / Rule / Skill とは独立した機構。以下の特性を踏まえて Skill/Rule との住み分けを判断する。

| 観点 | Hook の特性 |
|---|---|
| 実行タイミング | lifecycle イベント連動（SessionStart / UserPromptSubmit / UserPromptExpansion / PreToolUse / PostToolUse / PreCompact / Stop 等） |
| 実行コンテキスト | **Claude のコンテキスト外**で動作（シェルコマンド / HTTP / 別 LLM 呼び出し） |
| Claude との連携 | `UserPromptSubmit` / `UserPromptExpansion` / `SessionStart` 限定で `additionalContext` を注入可。その他イベントでは Claude が直接参照しない |

**Skill/Rule との住み分け**:
- 「毎回必ず実行させたい外部処理（ログ・アーカイブ・CI 連携等）」→ Hook
- 「Claude の reasoning を含む繰り返しワークフロー」→ Skill
- 「Claude に知識・規約を与える」→ Rule / CLAUDE.md

**設計上の注意点（参照元で確認済み）**:
- `UserPromptExpansion` は skill/custom コマンドのみに発火。`/compact` / `/clear` 等の **built-in コマンドには発火しない**
- built-in slash コマンドは同名 Skill を作成しても上書き不可（built-in と user skills は別系統で管理）
- `PreCompact` hook は compaction 前に動作するが **現在の会話コンテキスト内での Claude reasoning は不可**（外部プロセスのみ）

**参照先（ローカル）**: `research-for-local-RAG-for-cc/resources/references/claude-code-llms-full.txt`

| トピック | 目安行 / キーワード |
|---|---|
| Hook ライフサイクル全体・イベント種別表 | 約 21639 行〜 `"Hooks fire at specific points"` |
| UserPromptSubmit・UserPromptExpansion 仕様 | 約 22574 行〜 |
| PreCompact 仕様・trigger フィールド | `"PreCompact"` で Grep |
| Hook 種別（command / http / prompt / mcp_tool / agent） | 約 766 行〜 `"When to use which hook type"` |
| Built-in slash コマンド一覧 | `"built-in slash commands"` で Grep |

## 3. 補完判断軸（公式比較表に欠落している観点）

### 3.1 補助ファイル要否

**公式の状況**: CLAUDE.md vs Rules vs Skills の比較表には「補助ファイル要否」という判断軸は存在しない。ただし Skill ディレクトリ構造例（`docs/en/skills`）として `template.md` / `examples/` / `scripts/` / `references/` が示されており、Skill が補助ファイルを bundle できる仕組みは明示されている。

**判断観点**:
- 単一ファイルで完結する指示 → Rule で十分
- 雛型・サンプル・スクリプト・詳細リファレンスを伴う → Skill ディレクトリに bundle

**Rule 側の制約**: Rule は単一 Markdown ファイル前提。サブディレクトリでのグルーピング（`.claude/rules/frontend/`, `.claude/rules/backend/`）は公式に許容されているが、**Rule 1 件が補助ファイルを持つ仕組みは存在しない**。

### 3.2 コマンド実行可能性

**公式の状況**: §1.2 の CLAUDE.md vs Skill 比較で `Can trigger workflows: Yes, with /<name>` として明示。

**判断観点**:
- 作業指示者が `/<name>` で明示的に呼ぶ用途がある → Skill
- 作業者が呼び出すことはなく、特定パス編集時の自動ロードだけで足りる → Rule（または `user-invocable: false` の Skill）

**Skill の Invocation 制御（frontmatter）**:

| Frontmatter | ユーザー実行 | Claude 自動実行 |
|---|---|---|
| （デフォルト） | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

→ Skill は「ユーザーだけ呼べる」「Claude だけ呼べる」「両方呼べる」を frontmatter で切り替えられる。Rule にこの軸はない。

### 3.3 「常時ロードしたい単一ガイドライン」の処理

`paths:` 付き Rule と「`user-invocable: false` + `paths:`」の Skill は機能的に類似:

| 観点 | path-scoped Rule | path-scoped Skill |
|---|---|---|
| 自動ロードのトリガー | `paths:` 一致時 | `paths:` 一致時 |
| `/` メニュー表示 | しない（Rule に概念なし） | しない（`user-invocable: false` 設定時） |
| 補助ファイル bundle | 不可 | 可能 |
| 単一ファイルの読みやすさ | シンプル | SKILL.md + references/ で冗長になり得る |

**選択指針**: 補助ファイルが不要なら Rule、必要なら Skill。

## 4. 2 軸判定マトリクス

| 補助ファイル | コマンド実行 | 結論 |
|---|---|---|
| No | No | **Rule** で十分（必要なら `paths:` 付き） |
| Yes | No | **Skill**（`user-invocable: false` + `paths:`、補助ファイル bundle） |
| No | Yes | **Skill**（コマンド実行用途） |
| Yes | Yes | **Skill**（コマンド + bundle、最も Skill の旨味が大きい） |

## 5. 「Rule + 独自テンプレフォルダ」の再評価判断（公式に欠落）

公式は「CLAUDE.md → Skill 移行」は複数箇所で言及するが、「**Rule + 独自テンプレフォルダ → Skill 統合**」の移行判断は **公式に存在しない**。本 Skill 独自の判断指針:

### 5.1 統合検討トリガー

- Rule が単一ファイルで完結せず、別フォルダにテンプレ・例示・スクリプトが分散している
- Rule とテンプレの双方向参照（A → B → A）が発生している
- テンプレ運用ガイド（README）が独立して存在し、Rule の補足説明になっている

これらの状況は「実質的に補助ファイルを持つ Skill 構造を独自実装している」状態。Skill 化で公式設計に整合させる余地が大きい。

### 5.2 移行時の注意点

1. **旧 Rule のリダイレクト化**: frontmatter の `paths:` を **必ず削除**。残すとリダイレクト案内が自動ロードされ context を汚す
2. **旧パス参照の維持**: 過去成果物（過去のレビュー報告書等）から旧パスへの参照は、リダイレクト残置で機械的置換せず維持
3. **現役参照箇所のみ更新**: CLAUDE.md / 他 Skill / 他 Rule 内の参照は新パスへ更新
4. **Skill 自己編集時の自動ロード**: 新 Skill の `paths:` に `.claude/skills/<name>/**/*.md` を含めると、Skill 開発・編集中も自動ロードされる

## 6. 公式に明示的に欠落している観点（本 Skill の独自価値）

本 Skill が公式の補完として提供する価値:

1. **補助ファイル要否を判断軸としてフレーム化**: 公式比較表にはない明示的な 2 軸判定
2. **Rule + 独自テンプレフォルダの移行判断**: 公式に存在しない構造再評価の指針
3. **`user-invocable: false` + `paths:` の組み合わせ運用パターン**: 各要素は公式仕様だが、組み合わせとしての運用パターンは公式に明示なし

これらは公式の補完情報であり、公式の方針と矛盾するものではない。
