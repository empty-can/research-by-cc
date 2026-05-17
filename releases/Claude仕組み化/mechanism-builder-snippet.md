<!--
このファイルは、利用者の CLAUDE.md（プロジェクトルートまたはサブフォルダ）に追記するための節です。
本ファイル先頭の HTML コメントを除き、2 ブロック（A: 仕組み化判断, B: 一時ファイル出力先ルール）の本文を CLAUDE.md の適切な位置に貼り付けてください。
「作業指示者」はチーム内のタスクオーナー・依頼者を指します（社内文化に応じて読み替え可）。

ブロックの目的:
- A ブロック: 仕組み化判断の全体像（自律検知ルール `.claude/rules/mechanism-builder-detection.md` と実装 Skill の役割分担）を CLAUDE.md に記録する。Claude の自律検知・提案フローは detection rule（常時ロード）が担い、本ブロックはその案内役
- B ブロック: mechanism-builder のリファクタリングモードが提案ファイルを出力する際の出力先ルールを定義する（B を導入しないとリファクタリングモード実行時に Claude が出力先を作業指示者に確認する挙動になる）
-->

## 仕組み化判断

繰り返し手順・定型作業の仕組み化が必要と判断した場合のフロー（自律提案・タイミング確認・保留タスク再開）は `.claude/rules/mechanism-builder-detection.md`（常時ロード）に規定する。実装フロー（設計合意・実装・完了通知）は `mechanism-builder` Skill（`.claude/skills/mechanism-builder/SKILL.md`）が担う。

### 利用シーン

- 同じ手順・プロンプト・チェックリストを繰り返し使っており、再利用可能な形に仕組み化したい
- 新しいガイドライン・ルールを追加する際、CLAUDE.md / Rule / Skill のどれにすべきか判断したい
- 既存の Rule + 独自テンプレフォルダ等の組み合わせを Skill 統合できないか再評価したい
- 新規 Skill を作るとき、bundle 構造（templates / examples / scripts / references）の設計指針が欲しい

### 起動方法

- `/mechanism-builder` — 新規仕組み化（判断フロー + 雛型作成）
- `/mechanism-builder <対象名>` — 既存 Skill / Rule のリファクタリング提案（判断 → 提案ファイル生成）

詳細は `.claude/skills/mechanism-builder/SKILL.md` を参照。

## 一時ファイル・中間成果物の出力先

Claude が処理過程で生成する **一時ファイル・中間成果物**（最終成果物ではないが、スクリプト連携や作業途中のデータ受け渡し用、または作業指示者が一度確認するためのファイル）の出力先は、以下のルールに従う。

### 解決フロー

1. **適切な階層の CLAUDE.md（ルート / サブフォルダ / Skill SKILL.md 等）に出力先ルールが明記されている場合**: そのルールに従う
2. **見つからない場合**: 作業指示者に出力先をその場で確認する。推測で出力先を決めない

### デフォルト出力先

本プロジェクトのデフォルトは:

```text
.claude/workspace/<目的>/
```

- `<目的>` フォルダ名は Skill 名・タスク名と一致させる（例: `.claude/workspace/mechanism-builder/<対象名>/`）。これにより `.claude/skills/<name>/` ↔ `.claude/workspace/<name>/` の対応関係が一目で分かる
- `.claude/workspace/` は `.gitignore` 推奨（コミット対象外）

### 適用範囲

- 本ルールは本リポジトリ内の全 Skill / Rule / CLAUDE.md で順次適用する
- 新規 Skill 設計時は本ルールに従い、SKILL.md 内に「出力先 = 本ルールに従って解決、ルールがなければ作業指示者に確認」のフローを内蔵する
- サブフォルダで別の出力先を採用したい場合は、その `CLAUDE.md` に出力先ルールを明記する
