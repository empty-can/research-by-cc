# Skill bundle 設計指針

Skill ディレクトリ配下の bundle ファイル（SKILL.md / references / templates / examples / scripts）の設計指針と実例。

## 1. Skill ディレクトリ構造（公式）

### 1.1 標準構造（`docs/en/skills` より）

公式が代表例として示す構造:

```text
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

補助ファイルを伴う場合の拡張:

```text
my-skill/
├── SKILL.md (required - overview and navigation)
├── reference.md (detailed API docs - loaded when needed)
├── examples.md (usage examples - loaded when needed)
└── scripts/
    └── helper.py (utility script - executed, not loaded)
```

### 1.2 各ディレクトリ・ファイルの役割

| 要素 | 役割 | サイズ目安 |
|---|---|---|
| `SKILL.md` | 入口。ミッション・使い方の最短ルート・主要章立て | 200〜500 行（公式は 500 行未満推奨） |
| `references/` | 詳細リファレンス・判断フロー・参考資料。SKILL.md からリンクし、必要時のみロード | 1 ファイル 200〜400 行程度 |
| `templates/` | コピーして埋めて使う雛型 | 雛型ごとに分割 |
| `examples/` | 期待される入出力フォーマットの実例 | 1〜数ファイル |
| `scripts/` | Claude が実行するヘルパースクリプト | 単体実行可能な単位で分割 |

## 2. SKILL.md の設計

### 2.1 frontmatter

```yaml
---
name: <skill-name>                 # kebab-case、ディレクトリ名と合わせる
description: <一行説明>             # Claude の自動 invoke 判断材料、簡潔に
# 以下は必要なら設定:
# user-invocable: false             # /メニュー非表示（Claude のみ呼べる）
# disable-model-invocation: true   # ユーザーのみ呼べる（Claude 自動呼出禁止）
# paths:                            # path-scoped 自動発火
#   - "**/<path-pattern>/**"
# allowed-tools: Read Grep          # 事前承認するツール
# context: fork                     # subagent で実行
# agent: Explore                    # forkモード時のエージェント
---
```

主要フィールドの選定指針:

| フィールド | 設定指針 |
|---|---|
| `description` | 「何をするか」+「いつ使うか」を 1〜2 文で。Claude はこれを見て自動 invoke するか判断する |
| `user-invocable` | `false` にするのは「Claude にだけ知識として持っていてほしい背景情報」の場合 |
| `disable-model-invocation` | `true` にするのは「ユーザーが明示的に呼ぶ前提のワークフロー」（副作用がある操作等） |
| `paths` | path-scoped 自動ロードしたい場合のみ。glob パターン |

### 2.2 本文の方針

- **最短ルート案内**: 「呼ばれた直後に何をするか」を最初に明示
- **詳細は references/ へ**: 判断フロー・比較表・実例の詳細は分離
- **Progressive Disclosure**: SKILL.md は概要、details は references/、雛型は templates/
- **章立て例**: 提供物 → いつ使うか → 判断要点 → 実装ステップ → 同梱テンプレ一覧 → 関連参照

### 2.3 サイズ目安

公式 `docs/en/skills` の Tip:
> Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.

200 行を超え始めたら references/ への分離を検討。

## 3. references/ の設計

### 3.1 いつ使うか

- SKILL.md だけでは説明しきれない詳細がある
- 複数の判断軸・比較表・実例を集約したい
- 「必要時のみロード」したい大量のリファレンス（公式仕様抜粋等）

### 3.2 SKILL.md からの参照方法

```markdown
詳細は [references/decision-flow.md](references/decision-flow.md) を参照。
```

相対パスで `[ファイル名](references/<file>.md)` の形式。Claude は SKILL.md ロード時にこれらリンクを認識し、必要に応じて読みに行く。

### 3.3 ファイル分割の指針

- **観点別分割**: 「判断フロー」と「設計指針」など意味で分ける
- **過剰分割を避ける**: ファイル数が増えると Progressive Disclosure の利点が薄れる
- **目安**: 1 Skill につき references/ は 2〜5 ファイル程度

## 4. templates/ の設計

### 4.1 雛型ファイルの命名

雛型ファイルは「実体ファイル名 + `.template.md`」の形式を推奨。例:

| 雛型ファイル名 | 生成後のファイル名 |
|---|---|
| `SKILL.md.template.md` | `SKILL.md` |
| `new-rule.md.template.md` | `<rule-name>.md` |
| `claude-md-snippet.md.template.md` | （CLAUDE.md に追記） |

理由:
- 「これは雛型である」ことを命名で明示
- `.md` 末尾を残すことで Markdown 編集ツールのシンタックスハイライトが効く
- 実体 `SKILL.md` と区別される（Claude Code は `<skill-name>/SKILL.md` のみ Skill 認識するため、深い階層の `SKILL.md.template.md` は Skill として誤認されない）

### 4.2 雛型ディレクトリ構造

Skill 全体を雛型化する場合は、生成先の構造を雛型としてそのまま再現:

```text
templates/new-skill-template/
├── SKILL.md.template.md
├── references/
│   └── reference.md.template.md
├── templates/
│   └── template.md.template.md
├── examples/
│   └── sample.md.template.md
└── scripts/
    └── script.sh.template
```

→ `cp -r templates/new-skill-template/ <target>/` でディレクトリごとコピーし、不要な雛型ディレクトリを削除する運用。

## 5. examples/ の設計

- Claude が「期待される出力フォーマット」を把握するための実例
- 1 ファイル 50〜200 行程度に収める
- 複雑な場合は数ファイルに分割

## 6. scripts/ の設計

- Claude が実行するヘルパースクリプト
- `allowed-tools: Bash(<script-path>)` 等で frontmatter から事前承認
- 単体実行可能な単位で分割（汎用ロジックを共通化する場合は scripts/lib/ 等にサブ分割）

## 7. 独自フォルダを避ける理由

### 7.1 公式設計思想

公式 `docs/en/skills` は Skill ディレクトリ配下に templates / examples / scripts / references を bundle することを **代表的な利用パターンとして明示**。`.claude/templates/` のような独自フォルダを別途作る運用は **公式に推奨されていない**。

### 7.2 独自フォルダの問題点

- **Rule との関係が不明確**: `.claude/templates/<name>/` のような独自フォルダは、対応する Rule との参照関係が分かりにくい
- **公式の Progressive Disclosure を享受できない**: Skill bundle なら SKILL.md ロード時に description 経由で全体像が把握できる。独自フォルダはこの仕組みの外
- **path-scoped 自動ロードが分散**: Rule で path-scoped 自動ロード、テンプレが独自フォルダだと、関連リソースの参照経路が複数に分かれる

### 7.3 独自フォルダが妥当なケース（例外）

- Skill 仕組みで吸収しきれない明確な要件がある（Skill の Invocation 制御や bundle 構造でカバーできない、または不適切な構造が必要）
- Skill 化のオーバーヘッドが見合わないほど小規模（雛型 1 ファイルのみ等）

迷ったら Skill bundle を第一選択。

## 8. 実例

### 8.1 多ファイル参照型 Skill（path-scoped 自動ロード）

構造例:
```text
.claude/skills/<name>/
├── SKILL.md
└── references/
    ├── common/
    │   ├── 01_<観点 A>.md
    │   ├── 02_<観点 B>.md
    │   └── 03_<観点 C>.md
    ├── <カテゴリ 1>.md
    ├── <カテゴリ 2>.md
    └── <カテゴリ 3>.md
```

設計判断:
- 補助ファイル多数（共通観点 + カテゴリ別観点）→ Skill 化
- `user-invocable: false` + `paths:`: 編集時の自動ロード専用（コマンド実行用途なし）
- references/ はフェーズ別または観点別に分割
- `templates/` `examples/` `scripts/` は用途次第で省略可（純粋なガイドラインの場合は不要）

### 8.2 Rule + 独自テンプレフォルダ → Skill 統合パターン

旧構造（再評価対象）:
```text
.claude/rules/<name>-runtime.md       # Rule
.claude/templates/<name>/             # 独自テンプレフォルダ
├── README.md                          # テンプレ運用ガイド
└── <観点>_template.md × N             # 報告書雛型
```

新構造（統合後）:
```text
.claude/skills/<name>/
├── SKILL.md                           # 旧 README 由来、概観・基本ルール
├── references/runtime-rules.md        # 旧 Rule 由来、詳細運用
└── templates/<観点>_template.md × N
```

設計判断:
- 補助ファイル多数（テンプレ N 種 + 詳細運用仕様）→ Skill 化
- 旧 Rule + 独自テンプレフォルダの双方向参照を Skill bundle に集約
- 移行時は旧パスをリダイレクト残置（過去成果物のリンク維持）
- `user-invocable: false` + `paths:` で path-scoped 自動ロード（コマンド実行は現状不要だが将来追加可能）

### 8.3 mechanism-builder（本 Skill、自己参照）

構造:
```text
.claude/skills/mechanism-builder/
├── SKILL.md
├── references/
│   ├── decision-flow.md
│   └── bundle-design.md   # 本ファイル
└── templates/
    ├── new-skill-template/
    │   ├── SKILL.md.template.md
    │   ├── references/reference.md.template.md
    │   ├── templates/template.md.template.md
    │   ├── examples/sample.md.template.md
    │   └── scripts/script.sh.template
    ├── new-rule.md.template.md
    └── claude-md-snippet.md.template.md
```

設計判断:
- 補助ファイル（references 2 + templates 多数）→ Skill 化
- `user-invocable: true`（デフォルト）: 作業指示者が `/mechanism-builder` で呼ぶ用途
- `paths:` なし: 編集時の自動発火不要（明示呼び出し or Claude 自動判断）
- 雛型は実体ファイル名 + `.template.md` 形式で命名
