---
name: mechanism-builder
description: Claude Code の機構（CLAUDE.md / Rule / Skill）への仕組み化判断と実装支援。新規ガイドライン・手順の仕組化、既存構造（Rule + 独自テンプレ等）の再評価、Skill bundle 設計が必要な時に使用。
---

# mechanism-builder（仕組み化ビルダー）

Claude Code のプロジェクト構成において「何かを仕組み化したい」と判断したとき、どの機構（CLAUDE.md / Rule / Skill）で実装すべきかを判断し、必要な雛型を提供する Skill。判断だけでなく **実装ファイルの作成までをスコープ** とする。

## 1. このSkillが提供するもの

- **判断**: 仕組み化対象を CLAUDE.md / Rule / Skill のどれにすべきかの判断フロー
- **設計**: Skill とする場合の bundle ファイル設計指針（templates / examples / scripts / references の使い分け）
- **実装**: 各種ファイルの雛型（SKILL.md / Rule / CLAUDE.md スニペット）
- **リファクタリング**: 既存 Skill / Rule を本 Skill の判断軸に沿って再評価し、改善提案ファイルを生成（`/mechanism-builder <対象名>`）

## 2. いつ使うか

- 同じ手順・プロンプト・チェックリストを繰り返し使っており、再利用可能な形に仕組み化したい
- 「これは CLAUDE.md に書くべき? Rule にすべき? Skill 化すべき?」と迷っている
- 既存の `Rule + 独自テンプレフォルダ` 等の組み合わせを Skill 統合できないか再評価したい
- 新規 Skill を作るとき、bundle 構造（templates / examples / scripts / references）の設計指針が欲しい
- 既存 Skill / Rule を本 Skill の判断軸（公式比較 + 2 軸判定 + bundle 設計）に沿ってリファクタリングしたい（`/mechanism-builder <対象名>` で起動）

## 実行フロー

### A-2: ユーザーコマンド実行時の入口

| 起動形式 | 処理 |
|---|---|
| `/mechanism-builder`（引数なし） | 新規仕組み化として B-1 へ進む。保留中の仕組み化タスクがある場合は先に確認する（`.claude/rules/mechanism-builder-detection.md` §A-3 参照） |
| `/mechanism-builder <対象名>` | 対象 Skill / Rule のリファクタリングとして B-1（リファクタリング視点）へ進む |

### B-1: 設計案立案・ユーザー合意

実装前に、仕組み化の設計案を立案してユーザーと合意する。

**新規仕組み化の場合**:

1. §3.1 の公式比較軸 + §3.2 の補完 2 軸判定で機構（CLAUDE.md / Rule / Skill）を選定する
2. Skill とする場合は §4 の bundle 設計指針に従い、名前・frontmatter・bundle 構造を設計する
3. 以下の形式で設計案を提示する:

   ```
   【仕組み化設計案】
   - 機構: Skill / Rule / CLAUDE.md
   - 名前: <name>
   - 目的（description）: <説明>
   - frontmatter 設定: user-invocable / paths / disable-model-invocation
   - bundle 構造（Skill の場合）: SKILL.md / references / templates / examples / scripts の構成
   - 想定利用シーン:
   ```

4. ユーザーのフィードバックを受け、合意に至るまで修正する
5. 合意後 → B-2 へ

**リファクタリングの場合**（`/mechanism-builder <対象名>`）:

1. `references/refactor-existing.md` の Step 1〜4 に従い分析する
2. 分析結果を設計変更案として提示し、採用する変更点についてユーザーと合意する
3. 合意後 → B-2 へ（§5.4 の実装手順を適用）

### B-2: 実装

合意した設計に従って実装する。詳細手順は §5（実装ステップ）を参照。

### B-3: 完了通知

実装完了後、以下をユーザーへ提示する:

- 作成・変更した種別とパス（例: `Skill: .claude/skills/<name>/SKILL.md`）
- `user-invocable: true` の Skill なら: コマンド（`/<name>`）と機能概要
- `user-invocable: false` + `paths:` の Skill / Rule なら: 発火条件（どのファイル編集時にロードされるか）
- 運用上の注意（あれば）

## 3. 判断フロー（要点）

### 3.1 公式比較軸（`docs/en/features-overview` の「CLAUDE.md vs Rules vs Skills」より）

| 機構 | ロード | スコープ | 適用ケース |
|---|---|---|---|
| **CLAUDE.md** | 毎セッション | プロジェクト全体 | 「常に守る」中核規約・ビルドコマンド |
| **`.claude/rules/`** | 毎セッション or `paths:` 一致時 | プロジェクト全体 or path-scoped | 言語別・ディレクトリ別の規約 |
| **Skill** | 必要時のみ | タスク固有 | 参照資料・繰り返しワークフロー |

### 3.2 補完 2 軸判定（公式比較に欠落している判断軸）

| 観点 | Yes なら Skill 寄り | No なら Rule で十分 |
|---|---|---|
| **補助ファイル**（template / examples / scripts / references）を伴うか | Skill ディレクトリ配下に bundle 必要 | Rule（単一ファイル）で完結可 |
| **作業指示者が `/<name>` でコマンド実行**する用途があるか | Skill 化で実現（`/`メニュー登場） | Rule で十分（Rule にこの軸はない） |

**両方 No** なら Rule で十分。**いずれか Yes** なら Skill を検討。

### 3.3 「常時ロードしたい単一ガイドライン」の扱い

- `paths:` を持つ Rule = 「特定パス編集時に常時ロード」
- `user-invocable: false` + `paths:` の Skill = 同等機能を実現可能
- 違いは「補助ファイルを bundle できるか（Skill）/できないか（Rule）」のみ

詳細フロー・公式比較表・補完観点の根拠は [references/decision-flow.md](references/decision-flow.md) を参照。

## 4. Skill bundle 設計（要点）

### 4.1 公式の Skill ディレクトリ構造例

```text
my-skill/
├── SKILL.md           # 入口（必須）
├── references/        # 詳細リファレンス（必要時ロード）
├── templates/         # Claude が埋める雛型
├── examples/          # 期待される出力フォーマット例
└── scripts/           # Claude が実行するスクリプト
```

### 4.2 ファイル種別の使い分け

| ディレクトリ | 用途 |
|---|---|
| `SKILL.md` | 入口。Skill のミッション・適用範囲・最短ルート案内 |
| `references/` | 詳細仕様・判断フロー・参考資料（SKILL.md からリンクし、必要時ロード） |
| `templates/` | コピーして埋めて使う雛型（Claude が `$ARGUMENTS` 等で埋める） |
| `examples/` | 期待される入出力フォーマットの実例 |
| `scripts/` | Claude が実行するヘルパースクリプト |

### 4.3 独自フォルダ（`.claude/templates/` 等）を避ける

ガイドライン・テンプレート・スクリプト等の補助ファイルは、**関連 Skill のディレクトリ配下に bundle** することが公式推奨。独自フォルダ（`.claude/templates/` を Skill とは独立に作る等）は原則避ける。

詳細指針・実例は [references/bundle-design.md](references/bundle-design.md) を参照。

## 5. 実装ステップ

### 5.1 新規 Skill を作成する

1. `templates/new-skill-template/` をディレクトリごと対象パスへコピー
   - 例: `cp -r .claude/skills/mechanism-builder/templates/new-skill-template/ .claude/skills/<new-skill-name>/`
2. コピー先で `SKILL.md.template.md` を `SKILL.md` にリネーム
3. 必要な bundle ファイルだけを残し、不要な雛型ディレクトリ（references / templates / examples / scripts）は削除
4. frontmatter を埋める:
   - `name`: Skill 名（kebab-case）
   - `description`: いつ使うかが分かる説明（Claude の自動 invoke 判断材料）
   - 必要なら `user-invocable: false`（`/`メニュー非表示）、`paths:`（自動発火条件）、`disable-model-invocation: true`（手動呼び出し限定）
5. 本文を埋める

### 5.2 新規 Rule を作成する

1. `templates/new-rule.md.template.md` を `.claude/rules/<rule-name>.md` にコピー
2. `paths:` frontmatter で対象ファイルパターンを指定（path-scoped 自動ロードする場合）
3. 本文を埋める

### 5.3 CLAUDE.md に追記する

1. `templates/claude-md-snippet.md.template.md` を参考に、CLAUDE.md の該当節へ追記
2. 200 行を超えそうな場合は `.claude/rules/<name>.md` に分割して path-scoped 化する

### 5.4 既存資産のリファクタリング（リファクタリングモード）

既存の Skill / Rule を本 Skill の判断軸（公式比較 + 補完 2 軸判定 + bundle 設計指針）に沿って再評価し、提案ファイルを生成する。**判断 → 提案 まで** がスコープ（実際の編集作業は別タスクで実施）。

#### 起動方法

```text
/mechanism-builder <対象名>
```

`<対象名>` は `<name>` / `skill:<name>` / `rule:<name>` の 3 形式に対応。

#### フロー概要（5 ステップ）

1. **対象解決とバリデーション**: `scripts/generate-refactor-proposal.sh validate` で存在チェック・種別判定
2. **現状読み込み**: 確定した path 配下を Read
3. **2 軸判定の再適用**: §3.2 の補完 2 軸を現状構成に適用
4. **bundle 設計レビュー**: §4 の設計指針に照らしてレビュー
5. **提案ファイル生成**: 分析結果 Markdown をスクリプトに渡し、テンプレ展開で提案ファイル出力

#### 出力先

提案ファイルの出力先は **ルート CLAUDE.md「Claude が生成する一時ファイル・中間成果物の出力先」ルール** に従う。本リポジトリのデフォルトは `.claude/workspace/mechanism-builder/<対象名>/proposal-YYYY-MM-DD.md`。

該当階層の CLAUDE.md にルールがない場合は、推測せず作業指示者に確認する。

#### 詳細フロー

各ステップの詳細・スクリプトの仕様・分析結果 Markdown の構造は [references/refactor-existing.md](references/refactor-existing.md) を参照。

### 5.5 既存構造の手動再評価（簡易）

スクリプトを使わず、手動で既存構造を再評価する場合の手順:

1. 対象資産（Rule + 独自テンプレフォルダ 等）の構成要素を列挙
2. §3.2 の 2 軸判定を適用
3. Skill 統合の選択肢を検討（移行時は旧パスのリダイレクト残置で過去成果物のリンクを維持）

実例は [references/bundle-design.md](references/bundle-design.md) の「実例」セクションを参照。

## 6. 同梱テンプレート・スクリプト一覧

| ファイル | 用途 |
|---|---|
| `templates/new-skill-template/` | 新規 Skill 用 bundle 構造一式（SKILL.md + references/ + templates/ + examples/ + scripts/ のスケルトン） |
| `templates/new-rule.md.template.md` | 新規 Rule ファイル雛型 |
| `templates/claude-md-snippet.md.template.md` | CLAUDE.md 追記用スニペット雛型 |
| `templates/refactor-proposal.md.template.md` | リファクタリングモードの提案ファイル雛型（前提知識ブロック埋め込み済み） |
| `scripts/generate-refactor-proposal.sh` | リファクタリングモードのバリデーション + テンプレ展開スクリプト |

## 7. 関連参照

本 Skill 内:
- [references/decision-flow.md](references/decision-flow.md) — 判断フロー詳細
- [references/bundle-design.md](references/bundle-design.md) — bundle 設計指針 + 実例
- [references/refactor-existing.md](references/refactor-existing.md) — リファクタリングモード詳細

プロジェクト全体:
- `.claude/rules/mechanism-builder-detection.md` — 自律発案（A-1）・保留タスク再開（A-3）プロトコル（常時ロード）
- ルート CLAUDE.md「Claude が生成する一時ファイル・中間成果物の出力先」節 — 一時ファイル出力先ルール

公式ドキュメント:
- `code.claude.com/docs/en/features-overview`（Compare similar features セクションに CLAUDE.md vs Rules vs Skills 比較表）
- `code.claude.com/docs/en/skills`（Skill 仕様）
- `code.claude.com/docs/en/memory`（CLAUDE.md / Rules 仕様）
- `code.claude.com/docs/en/output-styles`（Output Styles との違い）

## 変更履歴

- 2026-05-15 版（初版）
- 2026-05-15: リファクタリングモード追加（既存 Skill / Rule の判断軸再適用 + 提案ファイル生成）
- 2026-05-17: 実行フロー（A-2 エントリー / B-1 設計合意 / B-3 完了通知）追加。自律発案・再開プロトコルを `.claude/rules/mechanism-builder-detection.md` に分離
