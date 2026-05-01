---
name: request-new-skill
description: 新しいSkillの作成依頼を開始する。作業用フォルダを作成し、依頼書テンプレートをコピーする。
allowed-tools: Bash(mkdir:*), Bash(cp:*), Bash(ls:*), Bash(powershell.exe *)
---

## 引数

`/request-new-skill <概要>` の形式で呼び出す。`<概要>` はSkillの内容を短く表す日本語または英語の説明。

## 実行手順

### 1. フォルダ名を生成する

- `<概要>` をケバブケース（英数字・ハイフンのみ）に変換する
- 日本語の場合はローマ字または意味が伝わる英語に意訳する
- 例: "コミット自動化" → `auto-commit`、"daily report" → `daily-report`
- 日付プレフィックスは付与しない（フォルダ名 = 事実上のSkill名として扱う）

### 2. 重複チェック

`.claude/workspace/skill-request/` 配下に同名フォルダが既に存在する場合:

- 「同名のSkill作成依頼が既に存在します（`<パス>`）。過去に同様のSkillを作成しようとした可能性があります。続行しますか？」と確認を求める
- ユーザーが続行を選択した場合のみ次へ進む

### 3. 作業用フォルダを作成する

```
.claude/workspace/skill-request/<フォルダ名>/
```

### 4. テンプレートをコピーする

- `.claude/templates/skill-request/skill-request-form.md` → 作業用フォルダへコピー
- `.claude/templates/skill-request/skill-cc-response.md` → 作業用フォルダへコピー

### 5. 完了を報告し、エディタで開く

- 作成したフォルダのパスと `skill-request-form.md` のパスを伝える
- 「`skill-request-form.md` に要件を記入後、`/review-skill-request` を実行してください」と案内する
- 以下のコマンドでシステムデフォルトのエディタを開く:
  ```
  powershell.exe -Command "Start-Process '<skill-request-form.md の絶対パス>'"
  ```
