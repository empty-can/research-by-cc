---
name: example-skill
description: 層2 plugin に同梱する skill の雛形。<トリガー条件と用途を1〜2文で>。ユーザーが「<キーワード>」と言ったら適用する。
# user-invocable: false  # /補完に出さず、関連判断/paths該当時のみロードする場合に有効化
# paths:                  # 特定ファイル種別の編集時のみロードする条件付き skill にする場合
#   - "**/*.ts"
---

# example-skill

> これは層2 plugin に skill を同梱する際の**形式雛形**。
> base-dev-kit の実 skill（`commit-and-pr` / `orchestrate` / `request-new-skill` /
> `review-skill-request`）は各々 `skills/<name>/SKILL.md` としてこの階層に並ぶ。

## このディレクトリの構成

```
skills/
└── <skill-name>/
    ├── SKILL.md          # 必須。frontmatter（name/description）＋本文
    ├── references/       # 任意。SKILL.md から参照する補助ドキュメント
    └── examples/         # 任意。用例
```

## 手順（本文）

1. <ステップ1>
2. <ステップ2>

## plugin 配布時の注意

- skill は plugin の配布単位ごとにキャッシュへ独立コピーされる。`CLAUDE.md` / `rules` / `settings.json`
  は plugin では運べないため、skill 内からそれらに依存しない（必要なら層1 commit 側に置く）。
- plugin 提供 skill のコマンドは `/base-dev-kit:<name>` の名前空間で呼ばれる。
