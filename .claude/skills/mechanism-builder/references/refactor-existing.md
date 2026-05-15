# リファクタリングモード（既存 Skill / Rule 再評価）

mechanism-builder の **リファクタリングモード**。既存の Skill または Rule を、本 Skill が定める判断軸（公式比較 + 2 軸判定 + bundle 設計指針）に沿って再評価し、改善提案ファイルを生成する。

**スコープ**: 判断 → 提案ファイル生成 まで。実際の編集作業は本 Skill のスコープ外（作業指示者の判断後、別タスクで実施）。

## 1. 起動方法

```text
/mechanism-builder <対象名>
```

例:
- `/mechanism-builder cross-review` — Skill / Rule のいずれかが対象（自動解決）
- `/mechanism-builder skill:cross-review` — Skill に限定
- `/mechanism-builder rule:agent-permission-runtime` — Rule に限定

## 2. フロー（5 ステップ）

### ステップ 1: 対象解決とバリデーション

スクリプトを呼び、対象の存在チェックと種別判定を行う:

```bash
bash .claude/skills/mechanism-builder/scripts/generate-refactor-proposal.sh validate <対象名>
```

スクリプトは JSON を stdout に出力する。`status` 値で分岐:

| status | 意味 | Claude の対応 |
|---|---|---|
| `ok` | 1 件に解決 | ステップ 2 へ進む。`type` と `path` を取得 |
| `error` (`not_found`) | 対象が存在しない | 作業指示者にタイポ確認を依頼 |
| `error` (`ambiguous`) | 同名 Skill と Rule が両方存在 | 種別プレフィックス（`skill:` / `rule:`）の付与を依頼 |
| `error` (`skill_not_found` / `rule_not_found`) | 指定種別で見つからない | 作業指示者にパス確認を依頼 |

### ステップ 2: 現状読み込み

確定した path 配下を読み込み:

- **Skill**: `SKILL.md` + `references/` + `templates/` + `examples/` + `scripts/` の構成把握 + 各ファイル要約
- **Rule**: 単一 Markdown ファイル

ファイル数が多い場合は、Skill ディレクトリ配下を Glob で一覧してから主要ファイルのみ Read する。

### ステップ 3: 2 軸判定の再適用

`SKILL.md` §3.2 の補完 2 軸判定を現状構成に対して再適用:

1. **補助ファイル要否**: 現状の補助ファイル群は妥当か / 不足はないか / 過剰ではないか
2. **コマンド実行用途**: 作業指示者が `/<name>` で実行する用途はあるか / 想定されるか

判定結果を以下のいずれかに分類:

| 分類 | 概要 |
|---|---|
| `appropriate` | 現状の機構選択は適切 |
| `skill_recommended` | Rule → Skill 化を推奨 |
| `rule_recommended` | Skill → Rule 化を推奨（オーバーエンジニアリング） |
| `partial_improvement` | 機構選択は維持、内部構造のみ改善 |

### ステップ 4: bundle 設計レビュー

`SKILL.md` §4 の bundle 設計指針に照らし、以下の観点でレビュー:

- 独自フォルダで bundle すべきものが SKILL.md 配下に集約されているか
- `references/` / `templates/` / `examples/` / `scripts/` の使い分けが公式指針と整合しているか
- `SKILL.md` が Progressive Disclosure の入口として機能しているか（概観 → references リンクで詳細）
- frontmatter 設計（`paths:` / `user-invocable` / `disable-model-invocation`）が用途と整合しているか

### ステップ 5: 提案ファイル生成

ステップ 2〜4 の分析結果を Markdown にまとめ、スクリプトに渡してテンプレを展開:

```bash
bash .claude/skills/mechanism-builder/scripts/generate-refactor-proposal.sh generate <対象名> <analysis-md-path>
```

スクリプトは `templates/refactor-proposal.md.template.md` を読み、プレースホルダーを置換して提案ファイルを出力。出力先 path を JSON で stdout に返す。

## 3. 分析結果 Markdown の構造

Claude がステップ 5 で渡す `analysis-md` は以下のセクション構成:

```markdown
# Analysis for <target-name>

## current_analysis
（現状分析: 構成・規模・特性・主な内容の要約）

## judgment_result
（判定結果: 分類 + 根拠）

## improvement_proposal
（改善提案: 推奨アクション + 具体的な変更点）

## alternatives
（代替案: 採用しないが言及すべき選択肢 + 不採用理由）
```

- 各セクションの `## <key>` ヘッダは固定（スクリプトが key で抽出）
- セクション本文は自由記述（Markdown サブヘッダ・リスト・表 OK）
- 出力先（一時ファイル）: 本リポジトリでは `.claude/workspace/mechanism-builder/<対象名>/.analysis.md`

## 4. 出力先ルール

提案ファイルの出力先は **ルート CLAUDE.md「Claude が生成する一時ファイル・中間成果物の出力先」ルール** に従う。

### 解決フロー

1. 該当階層の CLAUDE.md（ルート / 個別調査フォルダ）に出力先ルールがあればそれに従う
2. なければ作業指示者に確認

### 本リポジトリのデフォルト

```text
.claude/workspace/mechanism-builder/<対象名>/proposal-YYYY-MM-DD.md
```

スクリプトは本デフォルトに従って出力する。別の出力先を使う場合はスクリプトを呼ばず Claude が直接 Write する（または将来的にスクリプトに出力先引数を追加）。

## 5. 提案ファイルの内容

提案ファイル（`proposal-YYYY-MM-DD.md`）は以下の構成:

| セクション | 内容 |
|---|---|
| メタ情報 | 対象名 / 種別 / path / 生成日時 |
| 1. 現状分析 | Claude が用意した分析結果 |
| 2. 判定結果 | 2 軸判定 + bundle 設計レビューの結論 |
| 3. 改善提案 | 推奨アクション |
| 4. 代替案 | 採用しない選択肢と理由 |
| 5. 判断ポイント | 作業指示者が判断する際の確認事項 |
| 付録 A: 公式比較表 | CLAUDE.md vs Rule vs Skill |
| 付録 B: 補完 2 軸判定 | 2 軸の説明 |
| 付録 C: bundle 設計指針 | Skill ディレクトリ構造の要点 |

**付録 A〜C は固定文字列**（テンプレ側に埋め込み済み）。作業指示者は前提知識を別途参照する必要なく、提案ファイル単体で判断できる。

## 6. 作業指示者の判断後の流れ

mechanism-builder のリファクタリングモードは **判断 → 提案 まで** をスコープとする:

1. **作業指示者**: 提案ファイルを確認し、採用判断（推奨案 / 代替案 / 修正案）を Claude に伝達
2. **Claude**: 採用判断に従って編集作業を実施（本 Skill は不要、通常の Edit / Write で対応）

判断材料に不足があれば、追加調査または提案ファイルの再生成を依頼する。

## 7. 関連参照

- 判断フロー詳細: [decision-flow.md](decision-flow.md)
- bundle 設計指針: [bundle-design.md](bundle-design.md)
- スクリプト: `scripts/generate-refactor-proposal.sh`
- テンプレ: `templates/refactor-proposal.md.template.md`
- 出力先ルール: ルート CLAUDE.md「Claude が生成する一時ファイル・中間成果物の出力先」節
