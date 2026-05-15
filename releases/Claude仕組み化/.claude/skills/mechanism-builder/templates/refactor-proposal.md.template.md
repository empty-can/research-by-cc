<!--
このファイルは mechanism-builder のリファクタリングモードで使う提案ファイル雛型。
scripts/generate-refactor-proposal.sh が {{...}} プレースホルダーを置換して使用する。

プレースホルダー一覧:
- {{TARGET_NAME}}        — 対象名（例: my-skill）
- {{TARGET_TYPE}}        — skill / rule
- {{TARGET_PATH}}        — Skill ディレクトリ または Rule ファイルの絶対パス
- {{GENERATED_AT}}       — 生成日時（ISO-8601）
- {{CURRENT_ANALYSIS}}   — 分析結果 Markdown の current_analysis セクション
- {{JUDGMENT_RESULT}}    — judgment_result セクション
- {{IMPROVEMENT_PROPOSAL}} — improvement_proposal セクション
- {{ALTERNATIVES}}       — alternatives セクション
-->

# {{TARGET_NAME}} リファクタリング提案

| 項目 | 値 |
|---|---|
| 対象名 | `{{TARGET_NAME}}` |
| 種別 | `{{TARGET_TYPE}}` |
| 対象パス | `{{TARGET_PATH}}` |
| 生成日時 | `{{GENERATED_AT}}` |
| 生成元 | `mechanism-builder` Skill（リファクタリングモード） |

---

## 0. この提案の読み方

本ファイルは Claude（mechanism-builder Skill）が、対象 `{{TARGET_NAME}}` を本 Skill の判断軸（公式比較 + 補完 2 軸判定 + bundle 設計指針）に沿って再評価した結果です。

**作業指示者は以下のいずれかを Claude に伝えてください**:

- **推奨案を採用**: §3 の改善提案に従って編集を実施してほしい
- **代替案 X を採用**: §4 の代替案 X に従って編集を実施してほしい
- **修正案あり**: 具体的な修正点を伝える
- **判断保留**: 追加調査・分析の再生成を依頼する

判断材料が不足している場合、付録 A〜C の前提知識を参照してください（本ファイル単体で判断に必要な情報を含めています）。

---

## 1. 現状分析

{{CURRENT_ANALYSIS}}

---

## 2. 判定結果

{{JUDGMENT_RESULT}}

---

## 3. 改善提案（推奨アクション）

{{IMPROVEMENT_PROPOSAL}}

---

## 4. 代替案

{{ALTERNATIVES}}

---

## 5. 判断ポイント

作業指示者が判断する際の確認事項:

- **§3 改善提案** の前提・粒度は妥当か（過剰 / 不足はないか）
- **§4 代替案** に挙がっていない選択肢はないか
- **影響範囲**: 改訂による既存資産（過去レビュー報告書のリンク、他 Skill / Rule からの参照等）への影響を許容できるか
- **タイミング**: 即時実施 / 別タスク化 / 保留 のいずれが適切か

判断に必要な前提知識は付録 A〜C を参照。

---

## 付録 A: 公式比較表（CLAUDE.md vs Rule vs Skill）

`code.claude.com/docs/en/features-overview` の「Compare similar features」セクションより。

| 機構 | ロード | スコープ | 適用ケース |
|---|---|---|---|
| **CLAUDE.md** | 毎セッション | プロジェクト全体 | 「常に守る」中核規約・ビルドコマンド・プロジェクト概要 |
| **`.claude/rules/`** | 毎セッション（`paths:` なし）または `paths:` 一致時 | プロジェクト全体 または path-scoped | 言語別・ディレクトリ別の規約（単一ファイル完結） |
| **Skill** | 必要時のみ（自動 invoke / 手動 `/<name>` / `paths:` 一致） | タスク固有 | 参照資料・繰り返しワークフロー・補助ファイルを伴うガイドライン |

**機構間の使い分け原則**（`docs/en/memory` より）:

> Rules load into context every session or when matching files are opened. For task-specific instructions that don't need to be in context all the time, use skills instead.

## 付録 B: 補完 2 軸判定

公式比較表に欠落している補完観点。`mechanism-builder` Skill が定める独自軸。

| 観点 | Yes なら Skill 寄り | No なら Rule で十分 |
|---|---|---|
| **補助ファイル要否**（template / examples / scripts / references を伴うか） | Skill ディレクトリ配下に bundle 必要 | Rule（単一ファイル）で完結可 |
| **コマンド実行用途**（作業指示者が `/<name>` で実行する用途があるか） | Skill 化で実現（公式 frontmatter で実行制御） | Rule で十分（Rule にこの軸はない） |

**両方 No** なら Rule で十分。**いずれか Yes** なら Skill を検討。

**Skill frontmatter の Invocation 制御**（`docs/en/skills`）:

- デフォルト: ユーザー実行・Claude 自動実行とも可能
- `disable-model-invocation: true`: ユーザー実行のみ
- `user-invocable: false`: Claude 自動実行のみ（`/` メニュー非表示）

「常時または path-scoped 常時ロードしたい補助ファイル付きガイドライン」は `user-invocable: false` + `paths:` の Skill で実現できる（Rule に補助ファイルを伴わせる仕組みは公式に存在しない）。

## 付録 C: bundle 設計指針

公式の Skill ディレクトリ構造例（`docs/en/skills`）:

```text
my-skill/
├── SKILL.md           # 入口（必須）
├── references/        # 詳細リファレンス（必要時ロード、Progressive Disclosure）
├── templates/         # Claude が埋める雛型
├── examples/          # 期待される入出力フォーマット例
└── scripts/           # Claude が実行するヘルパースクリプト
```

**ファイル種別の使い分け**:

| ディレクトリ | 用途 |
|---|---|
| `SKILL.md` | 入口。Skill のミッション・適用範囲・最短ルート案内 |
| `references/` | 詳細仕様・判断フロー・参考資料（SKILL.md からリンクし、必要時ロード） |
| `templates/` | コピーして埋めて使う雛型 |
| `examples/` | 期待される入出力フォーマットの実例 |
| `scripts/` | Claude が実行するヘルパースクリプト |

**独自フォルダ作成の回避**: ガイドライン・テンプレート・スクリプト等の補助ファイルは、関連 Skill のディレクトリ配下に bundle することが公式推奨。`.claude/templates/` 等を Skill とは独立に作るのは原則避ける（既存資産で該当するものは Skill 統合の対象）。

---

<!-- 提案ファイル末尾 -->
