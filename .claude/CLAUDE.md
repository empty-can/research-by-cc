# CLAUDE.md（`.claude/` 運用詳細）

ルート `CLAUDE.md` と同じ「Project instructions」スコープで毎セッション自動ロードされる。本ファイルは**このリポジトリの Claude Code 設定（`.claude/`）の操作詳細**を担当し、ルート側は俯瞰と索引に徹する。

## 成果物の配置・命名規則

成果物は `research-for-xxx/reports/<タスク名>/<フェーズ名>/` に置く（**ルート側に reports は持たない**）。調査用フォルダ自体が作業スコープ。

- **階層は基本 2 階層**: `reports/<タスク名>/`（複数日にまたがる単位）→ `<フェーズ名>/`（構成フェーズ単位）
- **順序を示すなら数値プレフィックスを先頭に**（例: `01.基礎調査/`, `01.調査A/`）。フォルダ・ファイル共通
- **日付はファイル名の末尾に**付ける（先頭には付けない）。フォーマットは `YYYY-MM-DD`。付けてよいのは**同一内容を複数回実施し別ファイルで残す場合のみ**（レビュー報告書の 1 回目/2 回目 等）。それ以外はファイル内の変更履歴で作成・更新日を表現する
- 同一フェーズに複数の作業ファイルが混在するなら、**ファイル名に作業を識別できる文字列**を含める
- 親タスク違いで同名作業が出る場合は、**親タスクを示す接頭辞**で区別する（例: `01.検証_フィジビリティ_パターンA/`）
- フェーズ配下にサブフォルダを切ってよいのは、メインドキュメント以外に**付随ドキュメント（別紙・参考資料）がある場合**。横断的な付随物にできるならフェーズ階層に直置きを優先
- タスクをまたいで再利用するファイルは、個別 `CLAUDE.md` で位置を明記する

## Skill の追加は二段階フロー

新しい slash command を作りたい時は専用 skill 経由で進める:

1. `/request-new-skill <概要>` — `.claude/workspace/skill-request/<kebab-name>/` に作業フォルダと依頼書テンプレを生成
2. 依頼者が `skill-request-form.md` に要件を記入
3. `/review-skill-request [フォルダ名]` — Claude が依頼書をレビューし、`skill-cc-response.md` に質問・指摘・既存 Skill 調査結果・実装方針ドラフトを記入
4. 確認事項がクリアになったら実装へ

複雑な依頼は `/review-skill-request` 内部で `general-purpose` Agent (Opus) への委任を判断する。詳細は `.claude/skills/review-skill-request/SKILL.md`。

## 既存の skill / agent / output-style / template

| 種別 | 名前 | 用途 |
|---|---|---|
| skill | `commit-and-pr` | コミット → push → PR 作成を 1 メッセージで連続実行（`disable-model-invocation: true` で明示呼び出し限定） |
| skill | `orchestrate` | 複数 sub-agent を並列/順次協調させる。**メインセッションで呼ぶ前提**（subagent は subagent を spawn できない仕様への対応） |
| skill | `request-new-skill` / `review-skill-request` | 上記の skill 追加フロー |
| skill | `5-whys` | なぜなぜ分析（根本原因特定）。examples/ と references/ にサポートドキュメントあり |
| agent | `code-reviewer` | git diff ベースのレビュー。Sonnet 固定。大規模変更の後に主体的に呼んでよい |
| output-style | `code-review` | レビュー結果のフォーマット定義。CRITICAL / IMPORTANT / SUGGESTION / POSITIVE の 4 段階 |
| template | `cross-review/` | クロスレビュー報告書の雛型 3 種（論理整合性 / 実用性 / 作業指示者レビュー）。運用方針は `.claude/templates/cross-review/README.md` |

## 設定の階層

- `.claude/settings.json` — チーム共有・コミット対象
- `.claude/settings.local.json` — 個人ローカル・コミット対象外（`.example` をコピーして使う）

`settings.json` の `permissions.deny` で `.env*` / `secrets/**` / `~/.aws/credentials` / `~/.ssh/**` の読み取りをブロック済み。**新たな機微パスが出たら deny に追加してから扱う**。

## `.claude/rules/` の使い方（path-scoped rule）

`.claude/rules/*.md` は公式機能。frontmatter の `paths:`（glob の YAML リスト）で**該当ファイルを読んだ時のみロード**され、`paths:` を書かなければ**毎セッション無条件ロード**される。CLAUDE.md 本体を軽く保ち、必要な時だけ規約をロードして context を節約する仕組み。

現在の rules:

| ファイル | ロード条件 | 内容 |
|---|---|---|
| `research-source-routing.md` | 無条件 | 外部情報の調査経路（ローカル優先・llms.txt 戦略・MCP vs built-in） |
| `agent-delegation.md` | 無条件 | Agent 委任判断・活用パターン・モデル選定 |
| `git-workflow.md` | 無条件 | コミット運用・`.gitignore` 方針 |
| `coding-standards.md` | コードファイル編集時 | 言語別コーディング規約 |
| `cross-review-runtime.md` | レビュー報告書 / テンプレ編集時 | クロスレビュー実施の詳細運用 |
| `agent-permission-runtime.md` | agent 定義 / 計画書 / SKILL.md 編集時 | sub-agent 起動時の permission 事前準備 |

新たな横断ルールや言語別規約を足す時は同ディレクトリに新ファイルを切る。`paths:` を付ければそのファイルを読んだ時だけ、付けなければ毎セッションロードされる（**無条件ロードは context 量が CLAUDE.md と同等**な点に注意し、特定パス専用の規約はできるだけ `paths:` を付ける）。

## SessionStart hook

セッション開始時に `git status --short` が自動実行され、未コミット変更の有無を一覧表示する。出力に未コミット項目がある場合、Claude は最初の応答で「未コミット変更の有無」と「直近のコミット候補にすべきか」を作業指示者に確認する。新規 hook を足す時は Windows + macOS/Linux 両対応を意識する。
