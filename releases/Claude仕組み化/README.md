# Claude 仕組み化に関する配布物

Claude Code のプロジェクト構成において「同じ手順を繰り返し使っている」「Rule にすべきか Skill にすべきか迷う」「既存の Rule + 独自テンプレフォルダを再評価したい」といった場面で、CLAUDE.md / Rule / Skill のいずれで実装すべきかを判断し、雛型まで提供する `mechanism-builder` Skill の配布物。新規仕組み化に加えて、既存 Skill / Rule を判断軸に沿って再評価する **リファクタリングモード**（`/mechanism-builder <対象名>`）も同梱。

## 同梱物一覧

| ファイル | 配置先 | 役割 |
|---|---|---|
| `mechanism-builder-snippet.md` | （CLAUDE.md にコピペ） | 仕組み化判断の全体像（検知ルール・実装 Skill の役割分担）案内 + 一時ファイル出力先ルールの CLAUDE.md 追記用文言 |
| `.claude/rules/mechanism-builder-detection.md` | `<your-project>/.claude/rules/mechanism-builder-detection.md` | A-1（Claude 自律検知・提案）と A-3（保留タスク再開）プロトコル。`paths:` なし（常時ロード） |
| `.claude/skills/mechanism-builder/SKILL.md` | `<your-project>/.claude/skills/mechanism-builder/SKILL.md` | Skill 入口。`/mechanism-builder` でユーザー実行可、description 経由で Claude の自動 invoke も可 |
| `.claude/skills/mechanism-builder/references/decision-flow.md` | 同左 | 判断フロー詳細（公式比較表 + 補完 2 軸判定 + Rule + 独自テンプレ移行判断） |
| `.claude/skills/mechanism-builder/references/bundle-design.md` | 同左 | Skill bundle 設計指針（SKILL.md / references / templates / examples / scripts の使い分け） |
| `.claude/skills/mechanism-builder/references/refactor-existing.md` | 同左 | リファクタリングモード（既存 Skill / Rule 再評価）詳細フロー |
| `.claude/skills/mechanism-builder/templates/new-skill-template/` | 同左 | 新規 Skill 用 bundle 構造一式の雛型（SKILL.md + references + templates + examples + scripts） |
| `.claude/skills/mechanism-builder/templates/new-rule.md.template.md` | 同左 | 新規 Rule ファイル雛型 |
| `.claude/skills/mechanism-builder/templates/claude-md-snippet.md.template.md` | 同左 | CLAUDE.md 追記用スニペット雛型 |
| `.claude/skills/mechanism-builder/templates/refactor-proposal.md.template.md` | 同左 | リファクタリングモードの提案ファイル雛型（前提知識ブロック埋め込み済み） |
| `.claude/skills/mechanism-builder/scripts/generate-refactor-proposal.sh` | 同左 | リファクタリングモードのバリデーション + テンプレ展開スクリプト |

## 導入手順

1. **ファイル配置**: 上表「配置先」のとおり、`.claude/` 配下に各ファイルをコピー
2. **CLAUDE.md への追記**: `mechanism-builder-snippet.md` 冒頭の HTML コメントを除いた本文を、利用者の CLAUDE.md（プロジェクトルートまたはサブフォルダ）に追記
3. **動作確認**:
   - `/mechanism-builder` を実行して Skill が認識されているか確認（ユーザー実行モード）
   - 既存 Skill / Rule に対して `/mechanism-builder <対象名>` を実行し、提案ファイルが生成されるか確認

## 利用方法

### 新規仕組み化

```text
/mechanism-builder
```

「何かを仕組み化したい」と判断したとき、CLAUDE.md / Rule / Skill のどれにすべきかの判断 → 雛型作成 までを支援。Claude が判断フローに沿って質問し、合意した方針で雛型をコピー・展開する。

### 既存資産のリファクタリング

```text
/mechanism-builder <対象名>
```

既存の Skill / Rule を本 Skill の判断軸（公式比較 + 補完 2 軸判定 + bundle 設計指針）に沿って再評価し、提案ファイルを生成する。スコープは **判断 → 提案ファイル生成 まで**（実際の編集作業は別タスク）。

`<対象名>` 形式:
- `<name>` — 自動解決（Skill / Rule のいずれか 1 件にマッチ）
- `skill:<name>` — Skill に限定
- `rule:<name>` — Rule に限定

提案ファイルは付録（公式比較表 + 補完 2 軸判定 + bundle 設計指針）が埋め込み済みのため、作業指示者は前提知識を別途参照する必要なく単体で判断できる。

## ファイル間の依存関係

- `mechanism-builder-detection.md` は `paths:` なし（常時ロード）で A-1（Claude 自律検知・提案）と A-3（保留タスク再開）プロトコルを提供。SKILL.md へのリンクで B フロー（設計・実装・通知）に接続する
- `SKILL.md` は Skill の入口。`user-invocable: true`（デフォルト）のため `/mechanism-builder` で `/` メニューから実行可能
- `references/` 配下 3 ファイルは Progressive Disclosure に従い、SKILL.md からの相対リンク経由で必要時にロードされる
- `scripts/generate-refactor-proposal.sh` はリファクタリングモード時に Claude が `bash` 経由で実行する
- 提案ファイルの出力先は **受け取り側 CLAUDE.md の「一時ファイル・中間成果物の出力先」ルール** に依存。`mechanism-builder-snippet.md` の B ブロックを CLAUDE.md に取り込めば、スクリプトのデフォルト（`.claude/workspace/mechanism-builder/<対象名>/`）が機能する

## カスタマイズの観点

- **`user-invocable` / `disable-model-invocation` の切替**: デフォルトは「ユーザー実行・Claude 自動実行とも可能」。Claude 自動実行を禁じたい場合は `disable-model-invocation: true` を frontmatter に追加
- **提案ファイル出力先の変更**: `.claude/workspace/mechanism-builder/<対象名>/` 以外を使いたい場合は、スクリプト `PROJECT_ROOT`/`WORKSPACE_DIR` 変数を編集するか、Claude が直接 Write で出力する運用に切り替える
- **「作業指示者」表現**: チーム内のタスクオーナー・依頼者を指す。社内文化に応じて「ユーザー」「依頼者」等に置換可
- **bundle 設計実例の追加**: 利用者プロジェクト内の Skill 実装例を `references/bundle-design.md` §8 に追記すると、判断時の参照価値が高まる

## 動作環境

- **bash**: スクリプトは `bash` を想定。Windows 環境では Git Bash または WSL 経由で動作確認済
- **awk / sed / date**: スクリプト内部で使用。標準的な GNU/BSD いずれでも動作

## 公式リファレンス

- `code.claude.com/docs/en/features-overview`（Compare similar features セクションに CLAUDE.md vs Rules vs Skills 比較表）
- `code.claude.com/docs/en/skills`（Skill 仕様）
- `code.claude.com/docs/en/memory`（CLAUDE.md / Rules 仕様）
- `code.claude.com/docs/en/output-styles`（Output Styles との違い）

## 変更履歴

- 2026-05-15 版（初版）
- 2026-05-17: `mechanism-builder-detection.md` 追加（A-1 自律検知・A-3 保留再開プロトコル）。`mechanism-builder-snippet.md` Block A を対応する内容に更新
